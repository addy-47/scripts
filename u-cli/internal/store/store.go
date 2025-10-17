package store

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"

	"github.com/gofrs/flock"
	"go.etcd.io/bbolt"
)

// CommandLog represents the metadata for a tracked command
type CommandLog struct {
	Cmd          string   `json:"cmd"`
	Cwd          string   `json:"cwd"`
	Timestamp    string   `json:"timestamp"`
	ChangedFiles []string `json:"changed_files"`
}

// Store manages the BoltDB database for command metadata storage
type Store struct {
	db   *bbolt.DB
	path string
	lock *flock.Flock
}

// NewStore creates a new Store instance with the default database path
func NewStore() *Store {
	home := os.Getenv("HOME")
	path := filepath.Join(home, ".u", "state", "tracking.db")
	lockPath := filepath.Join(home, ".u", ".lock")
	return &Store{
		path: path,
		lock: flock.New(lockPath),
	}
}

// Open opens or creates the BoltDB database and initializes the commands bucket
func (s *Store) Open() error {
	// Acquire file lock
	if err := s.lock.Lock(); err != nil {
		return fmt.Errorf("failed to acquire file lock: %w", err)
	}

	// Ensure the directory exists
	dir := filepath.Dir(s.path)
	if err := os.MkdirAll(dir, 0755); err != nil {
		s.lock.Unlock()
		return fmt.Errorf("failed to create database directory: %w", err)
	}

	// Open the database
	db, err := bbolt.Open(s.path, 0600, nil)
	if err != nil {
		s.lock.Unlock()
		return fmt.Errorf("failed to open database: %w", err)
	}
	s.db = db

	// Create the commands bucket if it doesn't exist
	err = s.db.Update(func(tx *bbolt.Tx) error {
		_, err := tx.CreateBucketIfNotExists([]byte("commands"))
		if err != nil {
			return fmt.Errorf("failed to create commands bucket: %w", err)
		}
		return nil
	})

	if err != nil {
		s.lock.Unlock()
		return err
	}

	return nil
}

// Close closes the BoltDB database
func (s *Store) Close() error {
	if s.db != nil {
		err := s.db.Close()
		s.lock.Unlock() // Release lock after closing DB
		return err
	}
	s.lock.Unlock() // Release lock even if DB is nil
	return nil
}

// StoreCommandLog stores a command log in the database using timestamp as key
func (s *Store) StoreCommandLog(log *CommandLog) error {
	data, err := json.Marshal(log)
	if err != nil {
		return fmt.Errorf("failed to marshal command log: %w", err)
	}

	key := []byte(log.Timestamp)
	return s.db.Update(func(tx *bbolt.Tx) error {
		b := tx.Bucket([]byte("commands"))
		return b.Put(key, data)
	})
}

// GetRecentCommands retrieves the last n command logs (most recent first)
func (s *Store) GetRecentCommands(n int) ([]*CommandLog, error) {
	var logs []*CommandLog

	err := s.db.View(func(tx *bbolt.Tx) error {
		b := tx.Bucket([]byte("commands"))
		c := b.Cursor()

		// Collect all keys
		var keys [][]byte
		for k, _ := c.First(); k != nil; k, _ = c.Next() {
			keys = append(keys, k)
		}

		// Reverse keys to get most recent first (ISO 8601 timestamps are lexicographically sortable)
		for i := 0; i < len(keys)/2; i++ {
			j := len(keys) - 1 - i
			keys[i], keys[j] = keys[j], keys[i]
		}

		// Get the last n logs
		count := 0
		for _, k := range keys {
			if count >= n {
				break
			}
			v := b.Get(k)
			var log CommandLog
			if err := json.Unmarshal(v, &log); err != nil {
				return fmt.Errorf("failed to unmarshal command log: %w", err)
			}
			logs = append(logs, &log)
			count++
		}
		return nil
	})

	if err != nil {
		return nil, err
	}
	return logs, nil
}

// GetCommandLog retrieves a specific command log by index (0 = most recent)
func (s *Store) GetCommandLog(index int) (*CommandLog, error) {
	logs, err := s.GetRecentCommands(index + 1)
	if err != nil {
		return nil, err
	}
	if len(logs) <= index {
		return nil, fmt.Errorf("no command log at index %d", index)
	}
	return logs[index], nil
}