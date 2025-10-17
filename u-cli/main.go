package main

import (
	"fmt"
	"os"

	"u/cmd"

	"github.com/common-nighthawk/go-figure"
)

func main() {
	// Check if this is the first run (no arguments)
	if len(os.Args) == 1 {
		showWelcome()
	}

	cmd.Execute()
}

func showWelcome() {
	// Combine "how are" and "u" side by side

	howAre := figure.NewFigure("how are", "slant", true)
	uFigure := figure.NewFigure("u", "slant", true)

	// Convert figures into lines
	howAreLines := howAre.Slicify()
	uLines := uFigure.Slicify()

	// Define LUTI-style gradient colors
	colors := []string{"\033[36m", "\033[96m", "\033[34m", "\033[94m"}
	reset := "\033[0m"

	// Print them side by side, line by line
	maxLines := len(howAreLines)
	if len(uLines) > maxLines {
		maxLines = len(uLines)
	}

	for i := 0; i < maxLines; i++ {
		left := ""
		if i < len(howAreLines) {
			left = howAreLines[i]
		}
		right := ""
		if i < len(uLines) {
			right = colors[i%len(colors)] + uLines[i] + reset
		}

		fmt.Printf("%-50s %s\n", left, right)
	}

	fmt.Println()
	fmt.Println("🧰 Universal Linux Undo Command")
	fmt.Println("Version: 1.0 (MVP)")
	fmt.Println()
	fmt.Println("Bring Ctrl+Z to the Linux terminal!")
	fmt.Println()
	fmt.Println("Next steps:")
	fmt.Println("  1. Run 'u init' to start tracking commands")
	fmt.Println("  2. Run 'u help' to see what u can do")
	fmt.Println()
	fmt.Println("For more information, visit: https://github.com/adhbutg/u")
	fmt.Println()
}
