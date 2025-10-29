//go:build !linux && !darwin && !freebsd && !openbsd && !netbsd

package backup

// getAvailableDiskSpace returns available disk space in bytes for non-Unix systems
func getAvailableDiskSpace() (uint64, error) {
	// For non-Unix systems, skip disk space check
	return 1<<63 - 1, nil // Return max uint64 value to indicate unlimited space
}