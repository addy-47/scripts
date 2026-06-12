import os
import re
import sys
import time
import json
import uuid
import shutil
import subprocess
from google import genai
from google.genai import types
from qdrant_client import QdrantClient
from qdrant_client.http import models as qdrant_models

# Constants
API_KEY = ""
MODEL_NAME = "gemini-3.1-flash-lite"
EMBEDDING_MODEL = "gemini-embedding-001"
QDRANT_HOST = "localhost"
QDRANT_PORT = 6333
COLLECTION_NAME = ""

# Updated: Input is now a directory to search recursively
INPUT_DOCS_DIR = ""
OUTPUT_JSONL_PATH = ""
SPLIT_PAGES_DIR = ""

# Snero-level prompt for maximum detail extraction
SYSTEM_INSTRUCTION = """
You are an expert visual document analyzer and RAG ingestion engineer.
Your task is to analyze the provided single page of a PDF document (representing the GMR Bhogapuram International Airport progress update) and describe it with the absolute maximum detail possible.

In your description, cover the following exhaustively:
1. MAIN OBJECTIVE & THEME: What is this page about? (e.g., Progress Update, Key Features, Location Map, Runway details, Terminal Building, Financial progress, etc.)
2. TEXTUAL CONTENT: Extract and transcribe all headings, subheadings, paragraphs, bullet points, table data, labels, and footnotes exactly as they appear.
3. VISUAL ELEMENTS & IMAGES: For any photographs, renderings, schematics, maps, or charts, describe them in vivid detail:
    - What is shown in the image (e.g., aerial view of runway, concrete construction, terminal glass facade)?
    - What progress is visible (e.g., grading, excavation, structural steel, foundation work)?
    - Describe any annotations, labels, legends, or pointers on diagrams/maps.
4. DATA & METRICS: Highlight all numbers, percentages, dates, cost figures, passenger capacities, dimensions, or progress percentages mentioned.
5. DESIGN & LAYOUT: Briefly describe how the page is laid out (e.g., two-column layout, image on left and text on right, infographic, table of contents).

Be extremely thorough, comprehensive, and precise. Do not summarize or omit any information. Treat every detail, label, caption, and number as highly important for search/RAG indexing.
"""

def find_pdf_files(directory):
    """Recursively find all PDF files in the given directory."""
    pdf_files = []
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.lower().endswith('.pdf'):
                full_path = os.path.join(root, file)
                pdf_files.append(full_path)
    return pdf_files

def split_pdf_with_qpdf(input_path, output_dir):
    """Splits the input PDF into single page PDFs using qpdf."""
    print(f"=== Phase 1: PDF Preparation & Splitting for {os.path.basename(input_path)} ===")
    if not os.path.exists(input_path):
        print(f"Error: Input PDF not found at '{input_path}'")
        return False

    # Ensure output directory exists and is empty
    if os.path.exists(output_dir):
        print(f"Cleaning existing directory: {output_dir}")
        shutil.rmtree(output_dir)
    os.makedirs(output_dir, exist_ok=True)

    output_pattern = os.path.join(output_dir, "page-%d.pdf")
    print(f"Splitting PDF: '{input_path}' -> '{output_pattern}'")
    
    try:
        # Run qpdf command: qpdf --split-pages=1 input.pdf output-%d.pdf
        subprocess.run(["qpdf", "--split-pages=1", input_path, output_pattern], check=True)
        print("PDF successfully split into individual pages!")
        return True
    except subprocess.CalledProcessError as e:
        print(f"Error executing qpdf: {e}")
        return False

def get_completed_pages(jsonl_path):
    """Reads the JSONL output file and returns a set of completed page identifiers."""
    completed = set()
    if os.path.exists(jsonl_path):
        try:
            with open(jsonl_path, "r", encoding="utf-8") as f:
                for line in f:
                    if line.strip():
                        obj = json.loads(line)
                        # Create a unique identifier for each processed page: filename_pagenumber
                        identifier = f"{obj.get('filename', '')}_{obj.get('page_number', 0)}"
                        completed.add(identifier)
            print(f"Resume detection: Found {len(completed)} already completed pages in JSONL.")
        except Exception as e:
            print(f"Warning: Failed to read completed pages from JSONL: {e}")
    return completed

def process_single_pdf(pdf_path, completed_pages, jsonl_file, client, qdrant_client):
    """Process a single PDF file: split, describe, embed, and upsert."""
    filename = os.path.basename(pdf_path)
    print(f"\n{'='*60}")
    print(f"Processing PDF: {filename}")
    print(f"{'='*60}")
    
    # 1. Split PDF
    success = split_pdf_with_qpdf(pdf_path, SPLIT_PAGES_DIR)
    if not success:
        return False

    # 2. Get sorted list of page PDFs
    page_files = []
    for f in os.listdir(SPLIT_PAGES_DIR):
        match = re.match(r"page-(\d+)\.pdf", f)
        if match:
            page_files.append((int(match.group(1)), os.path.join(SPLIT_PAGES_DIR, f)))
    
    # Sort numerically by page number
    page_files.sort(key=lambda x: x[0])
    total_pages = len(page_files)
    print(f"Found {total_pages} page files to process in {filename}.")
    
    if total_pages == 0:
        print("Error: No page files found after split!")
        # Cleanup split pages dir for this file
        if os.path.exists(SPLIT_PAGES_DIR):
            shutil.rmtree(SPLIT_PAGES_DIR)
        return False

    # 3. Process each page
    pages_processed = 0
    for page_num, page_path in page_files:
        # Create unique identifier for this page
        identifier = f"{filename}_{page_num}"
        if identifier in completed_pages:
            print(f"Skipping page {page_num}/{total_pages} (Already processed)")
            continue

        print(f"\n--- Processing Page {page_num}/{total_pages} from {filename} ---")
        
        # Read single page PDF bytes
        try:
            with open(page_path, "rb") as pf:
                pdf_bytes = pf.read()
        except Exception as e:
            print(f"Error reading {page_path}: {e}")
            continue

        # Step A: Multimodal Page Description
        print(f"Sending Page {page_num} to Gemini 3.1 Flash-Lite...")
        try:
            response = client.models.generate_content(
                model=MODEL_NAME,
                contents=[
                    types.Part.from_bytes(data=pdf_bytes, mime_type="application/pdf"),
                    "Describe this page of the document with maximum detail."
                ],
                config=types.GenerateContentConfig(
                    system_instruction=SYSTEM_INSTRUCTION,
                    temperature=0.2
                )
            )
            description = response.text
            if not description:
                print(f"Warning: Empty description returned for Page {page_num}")
                description = f"Page {page_num} of {filename} (No text generated)."
            print(f"Generated description size: {len(description)} chars.")
        except Exception as e:
            print(f"Error calling Gemini describing Page {page_num}: {e}")
            print("Sleeping for 10 seconds before resuming...")
            time.sleep(10)
            continue

        # Step B: Generate Embedding (768 Dimensions)
        print(f"Generating embedding for Page {page_num}...")
        try:
            emb_resp = client.models.embed_content(
                model=EMBEDDING_MODEL,
                contents=description,
                config=types.EmbedContentConfig(
                    task_type="RETRIEVAL_DOCUMENT",
                    output_dimensionality=768
                )
            )
            embedding = emb_resp.embeddings[0].values
            print(f"Successfully generated embedding (dimension: {len(embedding)})")
        except Exception as e:
            print(f"Error generating embedding for Page {page_num}: {e}")
            continue

        # Step C: Upsert to Qdrant
        point_uuid = str(uuid.uuid5(uuid.NAMESPACE_DNS, f"{filename}-page-{page_num}"))
        print(f"Upserting to Qdrant (Point ID: {point_uuid})...")
        try:
            qdrant_client.upsert(
                collection_name=COLLECTION_NAME,
                points=[
                    qdrant_models.PointStruct(
                        id=point_uuid,
                        vector=embedding,
                        payload={
                            "text": description,
                            "source": f"{filename} (Page {page_num})",
                            "chunk_index": page_num,
                            "filename": filename
                        }
                    )
                ]
            )
            print("Successfully upserted to Qdrant!")
        except Exception as e:
            print(f"Error upserting Page {page_num} to Qdrant: {e}")
            continue

        # Step D: Save to JSONL
        output_obj = {
            "page_number": page_num,
            "filename": filename,
            "description": description,
            "embedding": embedding
        }
        jsonl_file.write(json.dumps(output_obj, ensure_ascii=False) + "\n")
        jsonl_file.flush()
        print(f"Successfully saved Page {page_num} to JSONL!")

        # Polite sleep between requests to avoid rate limits
        time.sleep(2.5)
        pages_processed += 1

    # Cleanup split pages dir after processing this file
    if os.path.exists(SPLIT_PAGES_DIR):
        print(f"Cleaning up split pages directory: {SPLIT_PAGES_DIR}")
        shutil.rmtree(SPLIT_PAGES_DIR)
    
    print(f"Finished processing {filename}: {pages_processed}/{total_pages} pages processed")
    return True

def main():
    print("=== Bihar MSME PDF Indexing Script (Recursive) ===")
    print(f"Searching for PDF files in: {INPUT_DOCS_DIR}")
    
    # Find all PDF files recursively
    pdf_files = find_pdf_files(INPUT_DOCS_DIR)
    if not pdf_files:
        print("No PDF files found!")
        return
    
    print(f"Found {len(pdf_files)} PDF file(s) to process:")
    for pdf in pdf_files:
        print(f"  - {pdf}")
    
    # 1. Initialize Clients
    print("\nInitializing Google GenAI and Qdrant clients...")
    client = genai.Client(api_key=API_KEY)
    
    try:
        qdrant_client = QdrantClient(host=QDRANT_HOST, port=QDRANT_PORT)
        # Ensure collection exists
        collections = qdrant_client.get_collections().collections
        exists = any(c.name == COLLECTION_NAME for c in collections)
        if not exists:
            print(f"Creating Qdrant collection: {COLLECTION_NAME}...")
            qdrant_client.create_collection(
                collection_name=COLLECTION_NAME,
                vectors_config=qdrant_models.VectorParams(
                    size=768,
                    distance=qdrant_models.Distance.COSINE
                )
            )
            print(f"Collection {COLLECTION_NAME} created successfully.")
        else:
            print(f"Qdrant collection {COLLECTION_NAME} already exists.")
    except Exception as e:
        print(f"Error connecting to or configuring Qdrant: {e}")
        print("Please make sure Qdrant is running on port 6333.")
        sys.exit(1)

    # 2. Load resume state
    completed_pages = get_completed_pages(OUTPUT_JSONL_PATH)
    
    # 3. Process each PDF file
    print("\n=== Phase 2: Processing PDF Files ===")
    successful_files = 0
    
    # Open JSONL in append mode
    with open(OUTPUT_JSONL_PATH, "a", encoding="utf-8") as jsonl_file:
        for pdf_path in pdf_files:
            success = process_single_pdf(pdf_path, completed_pages, jsonl_file, client, qdrant_client)
            if success:
                successful_files += 1
                # Update completed pages after each file for better resume capability
                completed_pages = get_completed_pages(OUTPUT_JSONL_PATH)
            else:
                print(f"Failed to process {pdf_path}")

    # 4. Final verification
    print("\n=== Phase 3: Verification ===")
    completed_now = get_completed_pages(OUTPUT_JSONL_PATH)
    print(f"Successfully processed {successful_files}/{len(pdf_files)} PDF files")
    print(f"Total completed page entries: {len(completed_now)}")
    
    if successful_files == len(pdf_files):
        print("All PDF files processed successfully!")
    else:
        print("Some files failed to process. Please check logs above.")

if __name__ == "__main__":
    main()
