package builder

import (
	"fmt"
	"log"
	"runtime"
	"sync"
	"time"

	"github.com/shirou/gopsutil/v3/cpu"
	"github.com/shirou/gopsutil/v3/disk"
	"github.com/shirou/gopsutil/v3/mem"
)

// ResourceMonitor tracks system resource usage for dynamic scheduling
type ResourceMonitor struct {
	maxCPUThreshold    float64
	maxMemoryThreshold float64
	maxDiskThreshold   float64
	checkInterval      time.Duration
	stopChan          chan struct{}
	mu                sync.Mutex
	currentLoad       float64
	currentMemory     float64
	currentDisk       float64
}

// NewResourceMonitor creates a new resource monitor
type ResourceMonitorConfig struct {
	MaxCPUThreshold    float64
	MaxMemoryThreshold float64
	MaxDiskThreshold   float64
	CheckInterval      time.Duration
}

func NewResourceMonitor(config ResourceMonitorConfig) *ResourceMonitor {
	if config.MaxCPUThreshold == 0 {
		config.MaxCPUThreshold = 80.0 // Default 80%
	}
	if config.MaxMemoryThreshold == 0 {
		config.MaxMemoryThreshold = 85.0 // Default 85%
	}
	if config.MaxDiskThreshold == 0 {
		config.MaxDiskThreshold = 90.0 // Default 90%
	}
	if config.CheckInterval == 0 {
		config.CheckInterval = 2 * time.Second // Default 2 seconds
	}

	return &ResourceMonitor{
		maxCPUThreshold:    config.MaxCPUThreshold,
		maxMemoryThreshold: config.MaxMemoryThreshold,
		maxDiskThreshold:   config.MaxDiskThreshold,
		checkInterval:      config.CheckInterval,
		stopChan:          make(chan struct{}),
		currentLoad:       0,
		currentMemory:     0,
		currentDisk:       0,
	}
}

// Start begins monitoring system resources
func (rm *ResourceMonitor) Start() {
	go func() {
		ticker := time.NewTicker(rm.checkInterval)
		defer ticker.Stop()

		for {
			select {
			case <-ticker.C:
				rm.updateResourceMetrics()
			case <-rm.stopChan:
				return
			}
		}
	}()
}

// Stop stops the resource monitoring
func (rm *ResourceMonitor) Stop() {
	close(rm.stopChan)
}

// updateResourceMetrics updates the current resource usage metrics
func (rm *ResourceMonitor) updateResourceMetrics() {
	// Get CPU usage
	cpuPercent, err := cpu.Percent(0, false)
	if err != nil {
		log.Printf("Warning: Failed to get CPU usage: %v", err)
		cpuPercent = []float64{0}
	}

	// Get memory usage
	memInfo, err := mem.VirtualMemory()
	if err != nil {
		log.Printf("Warning: Failed to get memory usage: %v", err)
		memInfo = &mem.VirtualMemoryStat{UsedPercent: 0}
	}

	// Get disk usage
	diskInfo, err := disk.Usage("/")
	if err != nil {
		log.Printf("Warning: Failed to get disk usage: %v", err)
		diskInfo = &disk.UsageStat{UsedPercent: 0}
	}

	rm.mu.Lock()
	defer rm.mu.Unlock()
	
	if len(cpuPercent) > 0 {
		rm.currentLoad = cpuPercent[0]
	}
	rm.currentMemory = memInfo.UsedPercent
	rm.currentDisk = diskInfo.UsedPercent

	log.Printf("Resource Monitor: CPU=%.1f%%, Memory=%.1f%%, Disk=%.1f%%", 
		rm.currentLoad, rm.currentMemory, rm.currentDisk)
}

// CanSchedule returns true if resources are available for another build
func (rm *ResourceMonitor) CanSchedule() bool {
	rm.mu.Lock()
	defer rm.mu.Unlock()

	cpuOK := rm.currentLoad < rm.maxCPUThreshold
	memoryOK := rm.currentMemory < rm.maxMemoryThreshold
	diskOK := rm.currentDisk < rm.maxDiskThreshold

	return cpuOK && memoryOK && diskOK
}

// GetSystemInfo returns basic system information
func GetSystemInfo() string {
	cpuCount := runtime.NumCPU()
	goMaxProcs := runtime.GOMAXPROCS(0)

	memInfo, _ := mem.VirtualMemory()
	diskInfo, _ := disk.Usage("/")

	return fmt.Sprintf("System: %d CPUs, GOMAXPROCS=%d, Memory=%.1fGB/%.1fGB (%.1f%% used), Disk=%.1fGB/%.1fGB (%.1f%% used)",
		cpuCount, goMaxProcs,
		float64(memInfo.Used)/1024/1024/1024,
		float64(memInfo.Total)/1024/1024/1024,
		memInfo.UsedPercent,
		float64(diskInfo.Used)/1024/1024/1024,
		float64(diskInfo.Total)/1024/1024/1024,
		diskInfo.UsedPercent)
}