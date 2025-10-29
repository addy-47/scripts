package cmd

// cmd/init.go .

import (
	"fmt"
	"os"
	"path/filepath"

	"u/internal/shell"
	"u/internal/store"

	"github.com/gofrs/flock"
	"github.com/spf13/cobra"
)

func runInit(cmd *cobra.Command, args []string) error {
	homeDir, _ := os.UserHomeDir()
	uDir := filepath.Join(homeDir, ".u")

	// 1. Check if already initialized
	if isAlreadyInitialized(uDir) {
		return handleAlreadyInitialized(uDir)
	}

	// 2. Try to acquire initialization lock
	lockPath := filepath.Join(os.TempDir(), "u-init.lock")
	lock := flock.New(lockPath)

	locked, err := lock.TryLock()
	if err != nil {
		return fmt.Errorf("failed to acquire init lock: %w", err)
	}
	if !locked {
		return fmt.Errorf("another 'u init' is already running")
	}
	defer lock.Unlock()

	// 3. Double-check after acquiring lock (another process might have finished)
	if isAlreadyInitialized(uDir) {
		return handleAlreadyInitialized(uDir)
	}

	// 4. Proceed with initialization...
	fmt.Println("🚀 Initializing u-cli...")

	// Create directories
	if err := setupDirectories(uDir); err != nil {
		return err
	}

	// Create config
	if err := createDefaultConfig(uDir); err != nil {
		return err
	}

	// Initialize database
	if err := initializeDatabase(uDir); err != nil {
		return err
	}

	// Install shell hook (with user confirmation)
	if err := promptAndInstallShellHook(); err != nil {
		// Non-fatal, just warn
		fmt.Printf("⚠️  Could not install shell hook: %v\n", err)
	}

	fmt.Println("\n✅ u-cli initialized successfully!")
	printWelcomeBanner()

	return nil
}

func setupDirectories(uDir string) error {
	dirs := []string{
		uDir,
		filepath.Join(uDir, "backups"),
		filepath.Join(uDir, "state"),
		filepath.Join(uDir, "pool"),
	}

	for _, dir := range dirs {
		if err := os.MkdirAll(dir, 0755); err != nil {
			return fmt.Errorf("failed to create directory %s: %w", dir, err)
		}
	}
	return nil
}

func createDefaultConfig(uDir string) error {
	configPath := filepath.Join(uDir, "config.yaml")
	defaultConfig := `ignored_dirs:
  - .cache
  - .git
  - node_modules
  - venv
  - /tmp
  - /proc
  - /sys
ttl: 24h
max_file_size: 10485760
max_total_size: 104857600
text_files_only: true
`
	return os.WriteFile(configPath, []byte(defaultConfig), 0644)
}

func initializeDatabase(uDir string) error {
	store := store.NewStore()
	if err := store.Open(); err != nil {
		return fmt.Errorf("failed to initialize database: %w", err)
	}
	store.Close()
	return nil
}

func promptAndInstallShellHook() error {
	fmt.Println("\n🔗 Shell Integration Setup")
	hook := shell.GetShellHook()
	fmt.Printf("Detected shell: %s\n", hook.Shell)

	fmt.Printf("\nThis will add the following to %s:\n\n", hook.File)
	fmt.Println(hook.Preview)

	fmt.Print("\nInstall shell hook? [Y/n]: ")
	var response string
	fmt.Scanln(&response)

	if response == "" || response == "y" || response == "Y" {
		return shell.InstallShellHook()
	}

	fmt.Println("Shell hook installation skipped.")
	return nil
}

func printWelcomeBanner() {
	fmt.Println(`
┌─────────────────────────────────────────┐
│  🧰 u - Universal Undo Command          │
│                                         │
│  Commands:                              │
│    u          Undo last command         │
│    u log      Show tracked commands     │
│    u help     Show all commands         │
│                                         │
│  Happy undoing! 🎉                      │
└─────────────────────────────────────────┘`)
}

func fileExists(path string) bool {
	_, err := os.Stat(path)
	return !os.IsNotExist(err)
}

func isAlreadyInitialized(uDir string) bool {
	// Check for essential files
	configPath := filepath.Join(uDir, "config.yaml")
	dbPath := filepath.Join(uDir, "history.db")

	configExists := fileExists(configPath)
	dbExists := fileExists(dbPath)

	return configExists && dbExists
}

func handleAlreadyInitialized(uDir string) error {
	fmt.Println("✅ u-cli is already initialized.")
	fmt.Println("\nCurrent status:")

	// Show current config
	configPath := filepath.Join(uDir, "config.yaml")
	fmt.Printf("  Config: %s\n", configPath)

	// Check if tracking is enabled
	if fileExists(filepath.Join(uDir, ".disabled")) {
		fmt.Println("  Status: ⏸️  Tracking disabled")
		fmt.Println("\nRun 'u enable' to start tracking commands.")
	} else {
		fmt.Println("  Status: ✅ Tracking enabled")
	}

	fmt.Println("\nOptions:")
	fmt.Println("  • Run 'u status' to see details")
	fmt.Println("  • Run 'u disable' to stop tracking")
	fmt.Println("  • Delete ~/.u and run 'u init' again to reset")

	return nil // Not an error, just informational
}

// Add a u enable command
func runEnable(cmd *cobra.Command, args []string) error {
	homeDir, _ := os.UserHomeDir()
	disabledPath := filepath.Join(homeDir, ".u", ".disabled")

	if !fileExists(disabledPath) {
		fmt.Println("✅ Tracking is already enabled")
		return nil
	}

	if err := os.Remove(disabledPath); err != nil {
		return fmt.Errorf("failed to enable tracking: %w", err)
	}

	fmt.Println("✅ Tracking enabled")
	fmt.Println("Commands will now be tracked automatically.")

	return nil
}
