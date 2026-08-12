import json
import urllib.request
import sys

SOURCE_URL = "http://localhost:6200"
TARGET_URL = "http://localhost:32771"

COLLECTIONS = ["wcd-missions", "wcd-missions-hybrid"]

def make_req(url, method="GET", data=None):
    headers = {"Content-Type": "application/json"}
    body = json.dumps(data).encode("utf-8") if data is not None else None
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode("utf-8"))

def migrate():
    print("--- Starting Qdrant Point Migration ---")
    print(f"Source: {SOURCE_URL} (qdrant-wcd v1.13.2)")
    print(f"Target: {TARGET_URL} (muxly-db-qdrant latest)")

    for col in COLLECTIONS:
        print(f"\nProcessing collection: {col}...")
        
        # 1. Fetch collection config from source
        src_info = make_req(f"{SOURCE_URL}/collections/{col}")
        col_params = src_info["result"]["config"]["params"]

        # 2. Check if collection exists on target, create if missing
        try:
            target_info = make_req(f"{TARGET_URL}/collections/{col}")
            print(f"  Target collection '{col}' exists.")
        except urllib.error.HTTPError as e:
            if e.code == 404:
                print(f"  Creating collection '{col}' on target...")
                make_req(f"{TARGET_URL}/collections/{col}", method="PUT", data=col_params)
            else:
                raise e

        # 3. Scroll all points from source and upsert to target
        offset = None
        total_migrated = 0

        while True:
            scroll_payload = {
                "limit": 250,
                "with_payload": True,
                "with_vector": True
            }
            if offset is not None:
                scroll_payload["offset"] = offset

            res = make_req(f"{SOURCE_URL}/collections/{col}/points/scroll", method="POST", data=scroll_payload)
            points = res["result"]["points"]
            next_offset = res["result"].get("next_page_offset")

            if not points:
                break

            # Format points for upsert API
            # For points scroll response, vector might be under 'vector' or 'vectors'
            upsert_points = []
            for p in points:
                pt_data = {
                    "id": p["id"],
                    "payload": p.get("payload", {})
                }
                if "vector" in p and p["vector"] is not None:
                    pt_data["vector"] = p["vector"]
                elif "vectors" in p and p["vectors"] is not None:
                    pt_data["vector"] = p["vectors"]
                upsert_points.append(pt_data)

            # Upsert batch to target
            upsert_res = make_req(f"{TARGET_URL}/collections/{col}/points?wait=true", method="PUT", data={"points": upsert_points})
            total_migrated += len(points)
            print(f"  Migrated {total_migrated} points...", end="\r")

            if next_offset is None:
                break
            offset = next_offset

        print(f"  Completed {col}: {total_migrated} total points migrated.")

        # Verify on target
        target_count = make_req(f"{TARGET_URL}/collections/{col}/points/count", method="POST", data={"exact": True})
        print(f"  Target verified count: {target_count['result']['count']} points.")

if __name__ == "__main__":
    migrate()
