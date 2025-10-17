package shell

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

type ShellHook struct {
	Shell   string
	File    string
	Content string
	Preview string
}

func DetectShell() string {
	// Try $SHELL first
	shell := os.Getenv("SHELL")
	if shell != "" {
		return filepath.Base(shell)
	}

	// Fallback: check what's running
	ppid := os.Getppid()
	out, err := exec.Command("ps", "-p", fmt.Sprintf("%d", ppid), "-o", "comm=").Output()
	if err == nil {
		return strings.TrimSpace(string(out))
	}

	return "bash" // default fallback
}

func GetShellHook() ShellHook {
	shell := DetectShell()
	homeDir, _ := os.UserHomeDir()

	switch shell {
	case "zsh":
		return ShellHook{
			Shell:   "zsh",
			File:    filepath.Join(homeDir, ".zshrc"),
			Preview: "preexec() { u track \"$1\" 0 &>/dev/null; }",
			Content: getZshHookContent(),
		}
	case "fish":
		return ShellHook{
			Shell:   "fish",
			File:    filepath.Join(homeDir, ".config/fish/conf.d/u.fish"),
			Preview: "function u_track --on-event fish_preexec ...",
			Content: getFishHookContent(),
		}
	default: // bash
		return ShellHook{
			Shell:   "bash",
			File:    filepath.Join(homeDir, ".bashrc"),
			Preview: "trap 'u_track_command' DEBUG",
			Content: getBashHookContent(),
		}
	}
}

func getBashHookContent() string {
	return `
# u-cli: Universal undo command tracking
if command -v u &> /dev/null; then
    u_track_command() {
        local exit_code=$?
        # Only track successful commands
        if [ $exit_code -eq 0 ]; then
            u track "$BASH_COMMAND" "$exit_code" &>/dev/null &
        fi
    }
    trap 'u_track_command' DEBUG
fi
`
}

func getZshHookContent() string {
	return `
# u-cli: Universal undo command tracking
if command -v u &> /dev/null; then
    preexec() {
        # Store exit code for post-command check
        local last_exit=$?
        # Only track if command was successful (will be checked after execution)
        if [[ $last_exit -eq 0 ]]; then
            u track "$1" "$last_exit" &>/dev/null &
        fi
    }
fi
`
}

func getFishHookContent() string {
	return `# u-cli: Universal undo command tracking
if command -v u &> /dev/null
    function u_track --on-event fish_preexec
        # Only track successful commands
        set -l last_status $status
        if test $last_status -eq 0
            u track $argv[1] $last_status &>/dev/null &
        end
    end
end
`
}

func InstallShellHook() error {
	hook := GetShellHook()

	// Create directory if needed (for fish)
	dir := filepath.Dir(hook.File)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return fmt.Errorf("failed to create directory: %w", err)
	}

	// Check if hook already exists
	if hookAlreadyInstalled(hook.File) {
		return fmt.Errorf("hook already installed")
	}

	// Append to shell config
	f, err := os.OpenFile(hook.File, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		return fmt.Errorf("failed to open shell config: %w", err)
	}
	defer f.Close()

	// Add a newline before our content
	if _, err := f.WriteString("\n" + hook.Content); err != nil {
		return fmt.Errorf("failed to write hook: %w", err)
	}

	return nil
}

func hookAlreadyInstalled(configFile string) bool {
	content, err := os.ReadFile(configFile)
	if err != nil {
		return false
	}

	// Check if our marker comment exists
	return strings.Contains(string(content), "u-cli: Universal undo command tracking")
}

func UninstallShellHook() error {
	hook := GetShellHook()

	content, err := os.ReadFile(hook.File)
	if err != nil {
		return err
	}

	// Remove our section
	lines := strings.Split(string(content), "\n")
	var filtered []string
	skip := false

	for _, line := range lines {
		if strings.Contains(line, "u-cli: Universal undo command tracking") {
			skip = true
		}
		if !skip {
			filtered = append(filtered, line)
		}
		if skip && strings.TrimSpace(line) == "fi" || strings.TrimSpace(line) == "end" {
			skip = false
		}
	}

	return os.WriteFile(hook.File, []byte(strings.Join(filtered, "\n")), 0644)
}
