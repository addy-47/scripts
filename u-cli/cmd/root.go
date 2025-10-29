package cmd

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"u/internal/backup"
	"u/internal/mapping"
	"u/internal/store"
	"u/internal/tracker"

	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:     "u",
	Short:   "Universal Linux Undo Command",
	Long:    `A single command — u — that instantly undos the last terminal operation safely, across all shells.`,
	Version: "1.1.0",
	RunE: func(cmd *cobra.Command, args []string) error {
		// Check if tracking is initialized
		if !isTrackingInitialized() {
			fmt.Println("u is not initialized. Run 'u init' to start tracking commands.")
			return nil
		}

		if len(args) == 0 {
			// Undo last command
			return undoLastCommand(0)
		}
		if len(args) == 1 {
			if args[0] == "2" {
				// Undo second last command
				return undoLastCommand(1)
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
		home := os.Getenv("HOME")
		configDir := filepath.Join(home, ".u")
		stateDir := filepath.Join(configDir, "state")
		backupsDir := filepath.Join(configDir, "backups")

		// Create directories
		dirs := []string{configDir, stateDir, backupsDir}
		for _, dir := range dirs {
			if err := os.MkdirAll(dir, 0755); err != nil {
				fmt.Printf("Error creating directory %s: %v\n", dir, err)
				return
			}
		}

		// Create default config file
		configPath := filepath.Join(configDir, "config.yaml")
		if _, err := os.Stat(configPath); os.IsNotExist(err) {
			defaultConfig := `ignored_dirs:
  - .cache
  - .git
  - node_modules
  - venv
  - /tmp
  - /proc
  - /sys
ttl: 24h
`
			if err := os.WriteFile(configPath, []byte(defaultConfig), 0644); err != nil {
				fmt.Printf("Error creating config file: %v\n", err)
				return
			}
		}

		// Initialize the store (creates tracking.db)
		store := store.NewStore()
		if err := store.Open(); err != nil {
			fmt.Printf("Error initializing store: %v\n", err)
			return
		}
		store.Close()

		fmt.Println("✅ u has been initialized!")
		fmt.Println("")
		fmt.Println("Next steps:")
		fmt.Println("  1. Add shell hooks to start tracking commands")
		fmt.Println("  2. Run 'u help' to see available commands")
		fmt.Println("")
		fmt.Println("To add shell hooks, add this to your shell config:")
		fmt.Println("")
		fmt.Println("For bash (~/.bashrc):")
		fmt.Println("  export PROMPT_COMMAND='u_track \"$BASH_COMMAND\"'")
		fmt.Println("")
		fmt.Println("For zsh (~/.zshrc):")
		fmt.Println("  preexec_functions+=(u_track)")
		fmt.Println("")
		fmt.Println("For fish (~/.config/fish/functions/fish_prompt.fish):")
		fmt.Println("  function fish_preexec --on-event fish_preexec")
		fmt.Println("      u_track $argv")
		fmt.Println("  end")
	},
}

var logCmd = &cobra.Command{
	Use:   "log",
	Short: "Show recent tracked commands",
	Run: func(cmd *cobra.Command, args []string) {
		if !isTrackingInitialized() {
			fmt.Println("u is not initialized. Run 'u init' to start tracking commands.")
			return
		}

		store := store.NewStore()
		if err := store.Open(); err != nil {
			fmt.Printf("Error opening store: %v\n", err)
			return
		}
		defer store.Close()

		logs, err := store.GetRecentCommands(10) // Show last 10 commands
		if err != nil {
			fmt.Printf("Error retrieving command logs: %v\n", err)
			return
		}

		if len(logs) == 0 {
			fmt.Println("No commands tracked yet.")
			fmt.Println("Start using u by running 'u init' and adding shell hooks.")
			return
		}

		fmt.Println("📋 Recent Tracked Commands:")
		fmt.Println("")

		for i, log := range logs {
			fmt.Printf("%d. %s\n", i+1, log.Cmd)
			fmt.Printf("   📅 %s\n", log.Timestamp)
			fmt.Printf("   📂 %s\n", log.Cwd)
			if len(log.ChangedFiles) > 0 {
				fmt.Printf("   📄 Changed files: %d\n", len(log.ChangedFiles))
			}
			fmt.Println("")
		}
	},
}

var cleanupCmd = &cobra.Command{
	Use:   "cleanup",
	Short: "Remove old backups (>1 day)",
	Run: func(cmd *cobra.Command, args []string) {
		if !isTrackingInitialized() {
			fmt.Println("u is not initialized. Run 'u init' to start tracking commands.")
			return
		}

		backupMgr := backup.NewBackupManager()

		// Default TTL is 24 hours, but could be configurable
		ttl := 24 * time.Hour

		if err := backupMgr.CleanupOldBackups(ttl); err != nil {
			fmt.Printf("Error cleaning up old backups: %v\n", err)
			return
		}

		fmt.Println("✅ Old backups cleaned up successfully.")
		fmt.Printf("Removed backups older than %v.\n", ttl)
	},
}

var disableCmd = &cobra.Command{
	Use:   "disable",
	Short: "Temporarily stop tracking",
	Run: func(cmd *cobra.Command, args []string) {
		if !isTrackingInitialized() {
			fmt.Println("u is not initialized. Run 'u init' to start tracking commands.")
			return
		}

		home := os.Getenv("HOME")
		configDir := filepath.Join(home, ".u")
		disabledFile := filepath.Join(configDir, ".disabled")

		// Create a marker file to indicate tracking is disabled
		if err := os.WriteFile(disabledFile, []byte("tracking disabled\n"), 0644); err != nil {
			fmt.Printf("Error disabling tracking: %v\n", err)
			return
		}

		fmt.Println("✅ Tracking has been disabled.")
		fmt.Println("To re-enable tracking, remove the ~/.u/.disabled file or run 'u enable' (if implemented).")
		fmt.Println("")
		fmt.Println("Note: Existing backups and command history are preserved.")
	},
}

var listCmd = &cobra.Command{
	Use:   "list",
	Short: "Show all undo mappings",
	Run: func(cmd *cobra.Command, args []string) {
		undoMap, err := mapping.LoadUndoMap()
		if err != nil {
			fmt.Printf("Error loading undo mappings: %v\n", err)
			return
		}

		fmt.Println("🧰 Universal Undo Mappings")
		fmt.Printf("Version: %s\n\n", undoMap.Version)

		categories := []struct {
			name string
			maps mapping.CategoryMappings
		}{
			{"File System", undoMap.FileSystem},
			{"Package Managers", undoMap.PackageManagers},
			{"Git", undoMap.Git},
			{"Docker", undoMap.Docker},
			{"System", undoMap.System},
			{"Cloud", undoMap.Cloud},
			{"Database", undoMap.Database},
			{"Miscellaneous", undoMap.Misc},
		}

		for _, category := range categories {
			if len(category.maps) > 0 {
				fmt.Printf("📁 %s:\n", category.name)
				for cmdName, mapping := range category.maps {
					safeStr := "✅"
					if !mapping.Safe {
						safeStr = "⚠️"
					}
					fmt.Printf("  %s %s: %s\n", safeStr, cmdName, mapping.Description)
				}
				fmt.Println()
			}
		}
	},
}

var helpCmd = &cobra.Command{
	Use:   "help",
	Short: "show all cmds and what u can do",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("🧰 u – Universal Linux Undo Command")
		fmt.Println("Version: 1.1.0 (Critical Fixes)")
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

var trackCmd = &cobra.Command{
	Use:   "track",
	Short: "Track a command execution (called by shell hooks)",
	Run: func(cmd *cobra.Command, args []string) {
		if len(args) != 2 {
			fmt.Println("Usage: u track <command> <exit_code>")
			return
		}

		command := args[0]
		exitCode := 0
		if args[1] == "1" {
			exitCode = 1
		}

		tracker := tracker.NewTracker()
		defer tracker.Close()

		if err := tracker.Init(); err != nil {
			fmt.Fprintf(os.Stderr, "Failed to initialize tracker: %v\n", err)
			return
		}

		if err := tracker.TrackCommand(command, exitCode); err != nil {
			fmt.Fprintf(os.Stderr, "Failed to track command: %v\n", err)
		}
	},
}

func init() {
	rootCmd.AddCommand(initCmd)
	rootCmd.AddCommand(helpCmd)
	rootCmd.AddCommand(logCmd)
	rootCmd.AddCommand(cleanupCmd)
	rootCmd.AddCommand(disableCmd)
	rootCmd.AddCommand(listCmd)
	rootCmd.AddCommand(trackCmd)
}

// isTrackingInitialized checks if u has been initialized
func isTrackingInitialized() bool {
	home := os.Getenv("HOME")
	configDir := filepath.Join(home, ".u")
	stateDir := filepath.Join(configDir, "state")
	trackingDb := filepath.Join(stateDir, "tracking.db")

	// Check if tracking database exists
	if _, err := os.Stat(trackingDb); os.IsNotExist(err) {
		return false
	}
	return true
}

// undoLastCommand undoes the nth last command (0 = most recent)
func undoLastCommand(n int) error {
	store := store.NewStore()
	if err := store.Open(); err != nil {
		return fmt.Errorf("failed to open store: %w", err)
	}
	defer store.Close()

	// Get the nth last command
	log, err := store.GetCommandLog(n)
	if err != nil {
		if n == 0 {
			fmt.Println("No commands to undo. Start using u by running 'u init' first.")
		} else {
			fmt.Printf("No command at position %d to undo.\n", n+1)
		}
		return nil
	}

	fmt.Printf("Undoing: %s\n", log.Cmd)

	// Parse the command to find undo mapping
	command, args, err := tracker.ParseCommand(log.Cmd)
	if err != nil {
		return fmt.Errorf("failed to parse command: %w", err)
	}

	// Load undo mappings
	undoMap, err := mapping.LoadUndoMap()
	if err != nil {
		return fmt.Errorf("failed to load undo mappings: %w", err)
	}

	// Find the appropriate undo action
	var undoCmd string
	var found bool

	// Check each category for the command
	categories := []mapping.CategoryMappings{
		undoMap.FileSystem,
		undoMap.PackageManagers,
		undoMap.Git,
		undoMap.Docker,
		undoMap.System,
		undoMap.Cloud,
		undoMap.Database,
		undoMap.Misc,
	}

	for _, category := range categories {
		if mapping, exists := category[command]; exists {
			undoCmd = mapping.Undo
			found = true
			break
		}
	}

	if !found {
		fmt.Printf("No undo mapping found for command: %s\n", command)
		fmt.Printf("Your last command was: %s\n", log.Cmd)
		fmt.Println("This command can be reverted by running the appropriate reverse command manually.")
		return nil
	}

	// Replace placeholders in undo command
	for i, arg := range args {
		placeholder := fmt.Sprintf("{args[%d]}", i)
		undoCmd = strings.ReplaceAll(undoCmd, placeholder, arg)
	}

	// For rm command, we need to restore from backup
	if command == "rm" && len(args) > 0 {
		backupMgr := backup.NewBackupManager()
		timestamp := strings.ReplaceAll(log.Timestamp, ":", "-") // Format for filename
		timestamp = strings.ReplaceAll(timestamp, "T", "-")
		timestamp = strings.Split(timestamp, ".")[0] // Remove milliseconds

		if err := backupMgr.RestoreBackup(timestamp); err != nil {
			fmt.Printf("Failed to restore files from backup: %v\n", err)
			fmt.Printf("Your last command was: %s\n", log.Cmd)
			return nil
		}
		fmt.Println("Files restored from backup.")
		return nil
	}

	// Execute the undo command
	fmt.Printf("Running: %s\n", undoCmd)
	// Note: In a real implementation, you'd execute this command
	// For now, just show what would be executed
	fmt.Printf("Undo command would be executed: %s\n", undoCmd)

	return nil
}

func Execute() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
