package main

import (
	"bytes"
	"fmt"
	"go/ast"
	"go/format"
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"strings"
)

// Config
const (
	SourceDir = "./old/backend" // Your source directory
	OutputDir = "./refactor" // Where to save the split files
)

func main() {
	// 1. Walk through the source directory
	entries, err := os.ReadDir(SourceDir)
	if err != nil {
		panic(err)
	}

	fmt.Println("🚀 Starting Code Explosion...")

	for _, entry := range entries {
		if entry.IsDir() || !strings.HasSuffix(entry.Name(), ".go") {
			continue
		}

		processFile(entry.Name())
	}

	fmt.Println("\n✅ Done! Check the 'refactor' directory.")
}

func processFile(fileName string) {
	fullPath := filepath.Join(SourceDir, fileName)
	fset := token.NewFileSet()

	// 2. Parse the Go file safely
	node, err := parser.ParseFile(fset, fullPath, nil, parser.ParseComments)
	if err != nil {
		fmt.Printf("❌ Error parsing %s: %v\n", fileName, err)
		return
	}

	// Create a folder for this file (categorization strategy)
	// e.g., backend/database.go -> refactor/database/
	folderName := strings.TrimSuffix(fileName, ".go")
	targetDir := filepath.Join(OutputDir, folderName)
	os.MkdirAll(targetDir, 0755)

	// 3. Extract Imports (to keep the new files somewhat readable)
	var imports []string
	for _, decl := range node.Decls {
		if genDecl, ok := decl.(*ast.GenDecl); ok && genDecl.Tok == token.IMPORT {
			var buf bytes.Buffer
			format.Node(&buf, fset, genDecl)
			imports = append(imports, buf.String())
		}
	}
	importBlock := strings.Join(imports, "\n")

	// 4. Iterate over all functions and methods
	funcCount := 0
	for _, decl := range node.Decls {
		funcDecl, ok := decl.(*ast.FuncDecl)
		if !ok {
			continue
		}

		// Get Function Name
		funcName := funcDecl.Name.Name
		
		// If it's a method (e.g., func (c *Candidate) Save()), prepend the receiver type
		// Result: Candidate_Save.go
		if funcDecl.Recv != nil {
			for _, field := range funcDecl.Recv.List {
				typeExpr := field.Type
				// Handle pointer receivers (*Candidate) vs value receivers (Candidate)
				if starExpr, ok := typeExpr.(*ast.StarExpr); ok {
					if ident, ok := starExpr.X.(*ast.Ident); ok {
						funcName = ident.Name + "_" + funcName
					}
				} else if ident, ok := typeExpr.(*ast.Ident); ok {
					funcName = ident.Name + "_" + funcName
				}
			}
		}

		// 5. Write the function to a new file
		var buf bytes.Buffer
		
		// Add Package declaration
		buf.WriteString(fmt.Sprintf("package %s\n\n", node.Name.Name))
		
		// Add Imports (Optional: Comment out if you want clean context, but usually helpful)
		buf.WriteString("// Imports from original file\n")
		buf.WriteString(importBlock + "\n\n")

		// Write the Function Code
		format.Node(&buf, fset, funcDecl)

		// Save File
		outputFile := filepath.Join(targetDir, funcName+".go")
		err := os.WriteFile(outputFile, buf.Bytes(), 0644)
		if err != nil {
			fmt.Printf("Error writing %s: %v\n", outputFile, err)
		}
		funcCount++
	}

	fmt.Printf("📂 %-20s -> Extracted %d functions\n", fileName, funcCount)
}