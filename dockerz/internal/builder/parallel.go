package builder

import (
	"log"
	"sync"
	"time"

	"github.com/addy-47/dockerz/internal/config"
	"github.com/addy-47/dockerz/internal/discovery"
)

// BuildImages builds Docker images for discovered services in parallel
func BuildImages(cfg *config.Config, discoveryResult *discovery.DiscoveryResult, maxProcesses int) ([]BuildResult, Summary) {
	startTime := time.Now()

	// Prepare build tasks
	tasks := make([]BuildTask, 0, len(discoveryResult.Services))
	for _, service := range discoveryResult.Services {
		task := BuildTask{
			ServicePath: service.Path,
			ImageName:   service.ImageName,
			Tag:         service.Tag,
			Config:      cfg,
		}
		tasks = append(tasks, task)
	}

	log.Printf("Starting parallel builds for %d services with max_processes=%d", len(tasks), maxProcesses)

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

	return results, summary
}