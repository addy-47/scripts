//go:build linux || darwin || freebsd || openbsd || netbsd

package backup

import (
	"os"

	"golang.org/x/sys/unix"
)

// getAvailableDiskSpace returns available disk space in bytes for Unix-like systems
func getAvailableDiskSpace() (uint64, error) {
	home := os.Getenv("HOME")
	var stat unix.Statfs_t
	if err := unix.Statfs(home, &stat); err != nil {
		return 0, err
	}
	return stat.Bavail * uint64(stat.Bsize), nil
}