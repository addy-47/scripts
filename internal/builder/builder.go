package builder

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"strings"
	"time"
)

// GetGitCommitID fetches the short Git commit ID for default tagging
func GetGitCommitID() string {
	cmd := exec.Command("git", "rev-parse", "--short", "HEAD")
	output, err := cmd.Output()
	if err != nil {
		log.Printf("Failed to fetch Git commit ID. Ensure this is a Git repository.")
		return "unknown"
	}
	return strings.TrimSpace(string(output))
}

// CheckGARAuth checks if GAR authentication is set up
func CheckGARAuth() error {
	cmd := exec.Command("gcloud", "auth", "print-access-token")
	return cmd.Run()
}

// BuildDockerImage builds a single Docker image
func BuildDockerImage(task BuildTask) BuildResult {
	result := BuildResult{
		Service:   task.ServicePath,
		StartTime: time.Now(),
	}

	// Skip build if smart features indicate it shouldn't be built
	if !task.NeedsBuild {
		result.Status = "skipped"
		result.EndTime = time.Now()
		log.Printf("Skipping build for %s (smart orchestration)", task.ServicePath)
		return result
	}

	// Construct full image name
	var imageFullName string
	if task.Config.UseGAR {
		imageFullName = fmt.Sprintf("%s-docker.pkg.dev/%s/%s/%s:%s",
			task.Config.Region, task.Config.ProjectID, task.Config.GARName, task.ImageName, task.Tag)
	} else {
		imageFullName = fmt.Sprintf("%s:%s", task.ImageName, task.Tag)
	}

	result.Image = imageFullName

	log.Printf("Building image for %s: %s", task.ServicePath, imageFullName)

	// Build the image
	buildCmd := exec.Command("docker", "build", "-t", imageFullName, ".")
	buildCmd.Dir = task.ServicePath
	buildCmd.Stdout = os.Stdout
	buildCmd.Stderr = os.Stderr

	if err := buildCmd.Run(); err != nil {
		log.Printf("Failed to build %s", imageFullName)
		result.Status = "failed"
		result.BuildOutput = err.Error()
		result.EndTime = time.Now()
		return result
	}

	log.Printf("Successfully built %s", imageFullName)
	result.Status = "success"
	result.EndTime = time.Now()

	// Push to GAR if enabled and build was successful
	if task.Config.UseGAR && task.Config.PushToGAR && result.Status == "success" {
		log.Printf("Pushing image to GAR: %s", imageFullName)

		pushCmd := exec.Command("docker", "push", imageFullName)
		pushCmd.Stdout = os.Stdout
		pushCmd.Stderr = os.Stderr

		if err := pushCmd.Run(); err != nil {
			log.Printf("Failed to push %s", imageFullName)
			result.PushStatus = "failed"
			result.PushOutput = err.Error()
		} else {
			log.Printf("Successfully pushed %s", imageFullName)
			result.PushStatus = "success"
		}
	}

	return result
}