package logging

import (
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"
)

// Level represents logging level
type Level int

const (
	DEBUG Level = iota
	INFO
	WARN
	ERROR
)

// Category represents logging category
type Category string

const (
	CATEGORY_CONFIG      Category = "CONFIG"
	CATEGORY_DISCOVERY   Category = "DISCOVERY"
	CATEGORY_GIT         Category = "GIT"
	CATEGORY_CACHE       Category = "CACHE"
	CATEGORY_SMART       Category = "SMART"
	CATEGORY_BUILD       Category = "BUILD"
	CATEGORY_PERFORMANCE Category = "PERFORMANCE"
)

// Logger provides unified logging for both CLI and file output
type Logger struct {
	consoleLogger *log.Logger
	fileLogger    *log.Logger
	logFile       io.WriteCloser
	mu            sync.RWMutex
	enabled       map[Category]bool
	minLevel      Level
}

// NewLogger creates a new logger with both console and file output
func NewLogger(logFilePath string) (*Logger, error) {
	logger := &Logger{
		consoleLogger: log.New(os.Stdout, "", 0),
		enabled:       make(map[Category]bool),
		minLevel:      INFO,
	}

	// Enable all categories by default
	categories := []Category{CATEGORY_CONFIG, CATEGORY_DISCOVERY, CATEGORY_GIT, 
		CATEGORY_CACHE, CATEGORY_SMART, CATEGORY_BUILD, CATEGORY_PERFORMANCE}
	for _, cat := range categories {
		logger.enabled[cat] = true
	}

	// Setup file logging if path provided
	if logFilePath != "" {
		// Ensure directory exists
		logDir := filepath.Dir(logFilePath)
		if err := os.MkdirAll(logDir, 0755); err != nil {
			return nil, fmt.Errorf("failed to create log directory: %w", err)
		}

		file, err := os.OpenFile(logFilePath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
		if err != nil {
			return nil, fmt.Errorf("failed to open log file: %w", err)
		}

		logger.logFile = file
		logger.fileLogger = log.New(file, "", 0)
	}

	return logger, nil
}

// EnableCategory enables logging for a specific category
func (l *Logger) EnableCategory(category Category) {
	l.mu.Lock()
	defer l.mu.Unlock()
	l.enabled[category] = true
}

// DisableCategory disables logging for a specific category
func (l *Logger) DisableCategory(category Category) {
	l.mu.Lock()
	defer l.mu.Unlock()
	l.enabled[category] = false
}

// SetMinLevel sets the minimum logging level
func (l *Logger) SetMinLevel(level Level) {
	l.mu.Lock()
	defer l.mu.Unlock()
	l.minLevel = level
}

// formatMessage formats a log message with timestamp and category
func (l *Logger) formatMessage(level Level, category Category, message string) string {
	timestamp := time.Now().Format("15:04:05")
	levelStr := l.levelToString(level)
	return fmt.Sprintf("[%s] %s: %s", timestamp, levelStr, message)
}

// levelToString converts level to string
func (l *Logger) levelToString(level Level) string {
	switch level {
	case DEBUG:
		return "DEBUG"
	case INFO:
		return "INFO"
	case WARN:
		return "WARN"
	case ERROR:
		return "ERROR"
	default:
		return "UNKNOWN"
	}
}

// shouldLog checks if the message should be logged based on level and category
func (l *Logger) shouldLog(level Level, category Category) bool {
	l.mu.RLock()
	defer l.mu.RUnlock()
	return l.enabled[category] && level >= l.minLevel
}

// Debug logs a debug message
func (l *Logger) Debug(category Category, message string) {
	if l.shouldLog(DEBUG, category) {
		formatted := l.formatMessage(DEBUG, category, message)
		l.consoleLogger.Println(formatted)
		if l.fileLogger != nil {
			l.fileLogger.Println(formatted)
		}
	}
}

// Info logs an info message
func (l *Logger) Info(category Category, message string) {
	if l.shouldLog(INFO, category) {
		formatted := l.formatMessage(INFO, category, message)
		l.consoleLogger.Println(formatted)
		if l.fileLogger != nil {
			l.fileLogger.Println(formatted)
		}
	}
}

// Warn logs a warning message
func (l *Logger) Warn(category Category, message string) {
	if l.shouldLog(WARN, category) {
		formatted := l.formatMessage(WARN, category, message)
		l.consoleLogger.Println(formatted)
		if l.fileLogger != nil {
			l.fileLogger.Println(formatted)
		}
	}
}

// Error logs an error message
func (l *Logger) Error(category Category, message string) {
	if l.shouldLog(ERROR, category) {
		formatted := l.formatMessage(ERROR, category, message)
		l.consoleLogger.Println(formatted)
		if l.fileLogger != nil {
			l.fileLogger.Println(formatted)
		}
	}
}

// PrintBanner prints a formatted banner message
func (l *Logger) PrintBanner(title string, content []string) {
	l.Info(CATEGORY_CONFIG, fmt.Sprintf("=== %s ===", title))
	for _, line := range content {
		l.Info(CATEGORY_CONFIG, line)
	}
	l.Info(CATEGORY_CONFIG, strings.Repeat("=", 40))
}

// PrintSection prints a section header
func (l *Logger) PrintSection(title string) {
	l.Info(CATEGORY_CONFIG, fmt.Sprintf("--- %s ---", title))
}

// PrintSummary prints a summary with key-value pairs
func (l *Logger) PrintSummary(data map[string]interface{}) {
	l.Info(CATEGORY_CONFIG, "SUMMARY:")
	for key, value := range data {
		l.Info(CATEGORY_CONFIG, fmt.Sprintf("%s=%v", key, value))
	}
}

// PrintMetrics prints performance metrics
func (l *Logger) PrintMetrics(operation string, duration time.Duration, count int) {
	l.Info(CATEGORY_PERFORMANCE, fmt.Sprintf("%s: %v, %d ops, %.1f/sec",
		operation, duration, count, float64(count)/duration.Seconds()))
}

// Close closes the file logger
func (l *Logger) Close() error {
	l.mu.Lock()
	defer l.mu.Unlock()
	if l.logFile != nil {
		return l.logFile.Close()
	}
	return nil
}