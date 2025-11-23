package builder

import (
	"fmt"
	"log"
	"os"
	"sync"
	"time"

	"github.com/addy-47/dockerz/internal/config"
	"github.com/addy-47/dockerz/internal/discovery"
)

// BuildImages builds Docker images for discovered services in parallel
func BuildImages(cfg *config.Config, discoveryResult *discovery.DiscoveryResult, maxProcesses int) ([]BuildResult, Summary) {
	startTime := time.Now()

	// Create build.log file
	logFile, err := os.OpenFile("build.log", os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
	if err != nil {
		log.Printf("Warning: Failed to create build.log file: %v", err)
	} else {
		defer logFile.Close()
		// Write header to log file
		fmt.Fprintf(logFile, "=== Dockerz Build Log ===\n")
		fmt.Fprintf(logFile, "Started at: %s\n", startTime.Format("2006-01-02 15:04:05"))
		fmt.Fprintf(logFile, "Services to build: %d\n", len(discoveryResult.Services))
		fmt.Fprintf(logFile, "Max processes: %d\n\n", maxProcesses)
	}

	// Prepare build tasks
	tasks := make([]BuildTask, 0, len(discoveryResult.Services))
	for _, service := range discoveryResult.Services {
		task := BuildTask{
			ServicePath: service.Path,
			ImageName:   service.ImageName,
			Tag:         service.Tag,
			Config:      cfg,
			NeedsBuild:  service.NeedsBuild,
		}
		tasks = append(tasks, task)
	}

	log.Printf("Starting parallel builds for %d services with max_processes=%d", len(tasks), maxProcesses)
	if logFile != nil {
		fmt.Fprintf(logFile, "Starting parallel builds for %d services with max_processes=%d\n", len(tasks), maxProcesses)
	}

	// Channel to receive results
	resultsChan := make(chan BuildResult, len(tasks))

	// Semaphore to limit concurrent goroutines
	sem := make(chan struct{}, maxProcesses)

	// WaitGroup to wait for all goroutines to complete
	var wg sync.WaitGroup

	// Start goroutines
	for _, task := range tasks {
		wg.Add(1)
		go func(t BuildTask) {
			defer wg.Done()
			sem <- struct{}{} // Acquire semaphore
			defer func() { <-sem }() // Release semaphore

			result := BuildDockerImage(t)
			resultsChan <- result
		}(task)
	}

	// Close results channel when all goroutines are done
	go func() {
		wg.Wait()
		close(resultsChan)
	}()

	// Collect results
	results := make([]BuildResult, 0, len(tasks))
	for result := range resultsChan {
		results = append(results, result)
		// Log individual build result to file
		if logFile != nil {
			fmt.Fprintf(logFile, "[%s] Service: %s, Image: %s, Status: %s", time.Now().Format("15:04:05"), result.Service, result.Image, result.Status)
			if result.Status == "failed" {
				fmt.Fprintf(logFile, ", Build Output: %s", result.BuildOutput)
			}
			fmt.Fprintf(logFile, "\n")
		}
	}

	// Calculate summary
	totalDuration := time.Since(startTime)
	successfulBuilds := 0
	failedBuilds := 0
	failedPushes := 0

	for _, result := range results {
		if result.Status == "success" {
			successfulBuilds++
		} else {
			failedBuilds++
		}
		if result.PushStatus == "failed" {
			failedPushes++
		}
	}

	summary := Summary{
		TotalServices:    len(tasks),
		SuccessfulBuilds: successfulBuilds,
		FailedBuilds:     failedBuilds,
		FailedPushes:     failedPushes,
		Duration:         totalDuration,
	}

	// Print summary
	log.Printf("\nBuild Summary:")
	log.Printf("Total services: %d", summary.TotalServices)
	log.Printf("Successful builds: %d", summary.SuccessfulBuilds)
	log.Printf("Failed builds: %d", summary.FailedBuilds)
	if summary.FailedBuilds > 0 {
		log.Printf("Failed builds:")
		for _, result := range results {
			if result.Status == "failed" {
				log.Printf("- %s: %s", result.Service, result.Image)
			}
		}
	}
	if summary.FailedPushes > 0 {
		log.Printf("Failed pushes:")
		for _, result := range results {
			if result.PushStatus == "failed" {
				log.Printf("- %s: %s", result.Service, result.Image)
			}
		}
	}

	// Write final summary to log file
	if logFile != nil {
		fmt.Fprintf(logFile, "\n=== Build Summary ===\n")
		fmt.Fprintf(logFile, "Total services: %d\n", summary.TotalServices)
		fmt.Fprintf(logFile, "Successful builds: %d\n", summary.SuccessfulBuilds)
		fmt.Fprintf(logFile, "Failed builds: %d\n", summary.FailedBuilds)
		fmt.Fprintf(logFile, "Duration: %v\n", summary.Duration)
		fmt.Fprintf(logFile, "Completed at: %s\n", time.Now().Format("2006-01-02 15:04:05"))
		if summary.FailedBuilds > 0 {
			fmt.Fprintf(logFile, "\nFailed builds:\n")
			for _, result := range results {
				if result.Status == "failed" {
					fmt.Fprintf(logFile, "- %s: %s\n", result.Service, result.Image)
				}
			}
		}
		if summary.FailedPushes > 0 {
			fmt.Fprintf(logFile, "\nFailed pushes:\n")
			for _, result := range results {
				if result.PushStatus == "failed" {
					fmt.Fprintf(logFile, "- %s: %s\n", result.Service, result.Image)
				}
			}
		}
	}

	return results, summary
}