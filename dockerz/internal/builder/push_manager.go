package builder

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"sync"
	"time"

	"github.com/addy-47/dockerz/internal/config"
	"github.com/addy-47/dockerz/internal/logging"
)

// PushManager handles throttled and retried Docker image pushes
type PushManager struct {
	config         *config.Config
	maxConcurrent  int
	semaphore      chan struct{}
	retryDelay     time.Duration
	maxRetries     int
	pushQueue      chan PushTask
	wg             sync.WaitGroup
	logger         *logging.Logger
}

// PushTask represents a single push operation
type PushTask struct {
	ImageName   string
	ServicePath string
	ResultChan  chan<- PushResult
}

// PushResult represents the result of a push operation
type PushResult struct {
	ImageName  string
	Status     string
	Output     string
	RetryCount int
}

// NewPushManager creates a new push manager
func NewPushManager(cfg *config.Config, maxConcurrent int) *PushManager {
	if maxConcurrent <= 0 {
		maxConcurrent = 2 // Default to 2 concurrent pushes
	}

	return &PushManager{
		config:        cfg,
		maxConcurrent: maxConcurrent,
		semaphore:     make(chan struct{}, maxConcurrent),
		retryDelay:    5 * time.Second,
		maxRetries:    3,
		pushQueue:     make(chan PushTask, 100), // Buffered channel for push tasks
	}
}

// SetLogger sets the logger for the push manager
func (pm *PushManager) SetLogger(logger *logging.Logger) {
	pm.logger = logger
}

// Start starts the push manager workers
func (pm *PushManager) Start() {
	for i := 0; i < pm.maxConcurrent; i++ {
		pm.wg.Add(1)
		go pm.worker(i)
	}
}

// Stop stops the push manager and waits for all pushes to complete
func (pm *PushManager) Stop() {
	close(pm.pushQueue)
	pm.wg.Wait()
}

// worker processes push tasks with retry logic
func (pm *PushManager) worker(workerID int) {
	defer pm.wg.Done()

	for task := range pm.pushQueue {
		pm.semaphore <- struct{}{} // Acquire semaphore
		
		result := pm.pushWithRetry(task)
		
		<-pm.semaphore // Release semaphore
		
		// Send result back
		if task.ResultChan != nil {
			task.ResultChan <- result
		}
	}
}

// pushWithRetry attempts to push an image with retry logic
func (pm *PushManager) pushWithRetry(task PushTask) PushResult {
	var result PushResult
	result.ImageName = task.ImageName

	for attempt := 1; attempt <= pm.maxRetries; attempt++ {
		if pm.logger != nil {
			pm.logger.Info(logging.CATEGORY_BUILD, fmt.Sprintf("Attempt %d/%d: Pushing image to GAR: %s", attempt, pm.maxRetries, task.ImageName))
		} else {
			log.Printf("Attempt %d/%d: Pushing image to GAR: %s", attempt, pm.maxRetries, task.ImageName)
		}

		pushCmd := exec.Command("docker", "push", task.ImageName)
		pushCmd.Stdout = os.Stdout
		pushCmd.Stderr = os.Stderr

		if err := pushCmd.Run(); err != nil {
			result.Status = "failed"
			result.Output = err.Error()
			result.RetryCount = attempt

			if attempt < pm.maxRetries {
				if pm.logger != nil {
					pm.logger.Warn(logging.CATEGORY_BUILD, fmt.Sprintf("Push failed, retrying in %v: %v", pm.retryDelay, err))
				} else {
					log.Printf("Push failed, retrying in %v: %v", pm.retryDelay, err)
				}
				time.Sleep(pm.retryDelay)
				continue
			}

			if pm.logger != nil {
				pm.logger.Error(logging.CATEGORY_BUILD, fmt.Sprintf("Failed to push %s after %d attempts", task.ImageName, pm.maxRetries))
			} else {
				log.Printf("Failed to push %s after %d attempts", task.ImageName, pm.maxRetries)
			}
			return result
		}

		// Success
		result.Status = "success"
		result.RetryCount = attempt
		
		if pm.logger != nil {
			pm.logger.Info(logging.CATEGORY_BUILD, fmt.Sprintf("Successfully pushed %s (attempt %d)", task.ImageName, attempt))
		} else {
			log.Printf("Successfully pushed %s (attempt %d)", task.ImageName, attempt)
		}
		return result
	}

	return result
}

// QueuePush adds a push task to the queue
func (pm *PushManager) QueuePush(imageName, servicePath string) chan PushResult {
	resultChan := make(chan PushResult, 1)
	
	pm.pushQueue <- PushTask{
		ImageName:   imageName,
		ServicePath: servicePath,
		ResultChan:  resultChan,
	}
	
	return resultChan
}

// GetPushStats returns statistics about the push manager
func (pm *PushManager) GetPushStats() map[string]interface{} {
	return map[string]interface{}{
		"max_concurrent": pm.maxConcurrent,
		"retry_delay":    pm.retryDelay.String(),
		"max_retries":    pm.maxRetries,
	}
}