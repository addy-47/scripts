package cmd

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:     "u",
	Short:   "Universal Linux Undo Command",
	Long:    `A single command — u — that instantly undos the last terminal operation safely, across all shells.`,
	Version: "1.0",
	RunE: func(cmd *cobra.Command, args []string) error {
		if len(args) == 0 {
			// Undo last command
			fmt.Println("Undo last command: Command not yet implemented")
			return nil
		}
		if len(args) == 1 {
			if args[0] == "2" {
				// Undo second last command
				fmt.Println("Undo second last command: Command not yet implemented")
				return nil
			}
		}
		return fmt.Errorf("invalid arguments. Use 'u help' for usage")
	},
	Args: cobra.MaximumNArgs(1),
}

var initCmd = &cobra.Command{
	Use:   "init",
	Short: "Start tracking commands",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("u init: Command not yet implemented")
	},
}

var logCmd = &cobra.Command{
	Use:   "log",
	Short: "Show recent tracked commands",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("u log: Command not yet implemented")
	},
}

var cleanupCmd = &cobra.Command{
	Use:   "cleanup",
	Short: "Remove old backups (>1 day)",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("u cleanup: Command not yet implemented")
	},
}

var disableCmd = &cobra.Command{
	Use:   "disable",
	Short: "Temporarily stop tracking",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("u disable: Command not yet implemented")
	},
}

var listCmd = &cobra.Command{
	Use:   "list",
	Short: "Show all undo mappings",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("u list: Command not yet implemented")
	},
}

var helpCmd = &cobra.Command{
	Use:   "help",
	Short: "show all cmds and what u can do",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("🧰 u – Universal Linux Undo Command")
		fmt.Println("Version: 1.0 (MVP)")
		fmt.Println("")
		fmt.Println("Goal: A single command — u — that instantly undos the last terminal operation safely, across all shells.")
		fmt.Println("")
		fmt.Println("Available commands:")
		fmt.Println("  u init     Start tracking commands")
		fmt.Println("  u help     show all cmds and what u can do")
		fmt.Println("  u          Undo last tracked command")
		fmt.Println("  u 2        Undo second last command")
		fmt.Println("  u log      Show recent tracked commands")
		fmt.Println("  u cleanup  Remove old backups (>1 day)")
		fmt.Println("  u disable  Temporarily stop tracking")
		fmt.Println("  u list     Show all undo mappings")
		fmt.Println("")
		fmt.Println("Bring Ctrl+Z to the Linux terminal — a universal undo command for common shell operations.")
	},
}

func init() {
	rootCmd.AddCommand(initCmd)
	rootCmd.AddCommand(helpCmd)
	rootCmd.AddCommand(logCmd)
	rootCmd.AddCommand(cleanupCmd)
	rootCmd.AddCommand(disableCmd)
	rootCmd.AddCommand(listCmd)
}

func Execute() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}