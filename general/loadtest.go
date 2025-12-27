package main

import (
	"bytes"
	"context"
	"crypto/tls"
	"encoding/csv"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"math"
	"math/rand"
	"net/http"
	"os"
	"os/signal"
	"sort"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"syscall"
	"time"

	"github.com/google/uuid"
)

// ========= CONFIG =========
var questions = []string{
	"What is rainwater harvesting?",
	"Explain POSH act",
	"How does BigQuery work?",
	"What is RAG in AI?",
	"Explain vector search",
	"What is Karmayogi Bharat?",
	"How does Gemini LLM work?",
	"Explain cosine similarity",
	"What is cloud storage?",
	"What is an embedding model?",
}

type Result struct {
	TimeStamp    time.Time
	Latency      time.Duration
	Status       int
	Success      bool
	Bytes        int64
	UserID       string
	Query        string
	Err          error
	ResponseBody string // Debug: Captures server error message
}

type Config struct {
	URL        string
	TargetRPS  int
	SteadyDur  int
	RampUp     int
	RampDown   int
	OutPrefix  string
	TimeoutSec int
}

type FailureSignature struct {
	Status int
	Body   string
	Err    string
}

// ========= HELPER FUNCTIONS =========
func percentile(sorted []float64, p float64) float64 {
	if len(sorted) == 0 {
		return 0
	}
	i := int(math.Ceil((p/100)*float64(len(sorted)))) - 1
	if i < 0 {
		i = 0
	}
	return sorted[i]
}

func progressBar(pct float64, width int) string {
	filled := int(pct * float64(width))
	if filled > width {
		filled = width
	}
	return "[" + strings.Repeat("█", filled) + strings.Repeat("-", width-filled) + "]"
}

func getCurrentRPS(elapsedSec float64, cfg Config) float64 {
	// Ramp Up
	if elapsedSec < float64(cfg.RampUp) {
		if cfg.RampUp == 0 { return float64(cfg.TargetRPS) }
		return float64(cfg.TargetRPS) * (elapsedSec / float64(cfg.RampUp))
	}
	// Steady
	steadyEnd := float64(cfg.RampUp + cfg.SteadyDur)
	if elapsedSec < steadyEnd {
		return float64(cfg.TargetRPS)
	}
	// Ramp Down
	totalDur := float64(cfg.RampUp + cfg.SteadyDur + cfg.RampDown)
	if elapsedSec < totalDur {
		if cfg.RampDown == 0 { return 0 }
		remaining := totalDur - elapsedSec
		return float64(cfg.TargetRPS) * (remaining / float64(cfg.RampDown))
	}
	return 0
}

func main() {
	// ========= CLI FLAGS =========
	url := flag.String("url", "", "Target URL")
	rps := flag.Int("rps", 10, "Target RPS")
	duration := flag.Int("duration", 60, "Steady state duration (s)")
	rampUp := flag.Int("ramp-up", 0, "Ramp up duration (s)")
	rampDown := flag.Int("ramp-down", 0, "Ramp down duration (s)")
	out := flag.String("out", "loadtest_report", "Output filename prefix")
	timeout := flag.Int("timeout", 30, "HTTP Timeout (s)")
	flag.Parse()

	if *url == "" {
		fmt.Println("❌ --url required")
		os.Exit(1)
	}

	cfg := Config{
		URL:        *url,
		TargetRPS:  *rps,
		SteadyDur:  *duration,
		RampUp:     *rampUp,
		RampDown:   *rampDown,
		OutPrefix:  *out,
		TimeoutSec: *timeout,
	}

	totalTestTime := time.Duration(cfg.RampUp+cfg.SteadyDur+cfg.RampDown) * time.Second

	// HTTP Client Optimization
	t := http.DefaultTransport.(*http.Transport).Clone()
	t.MaxIdleConns = 2000
	t.MaxConnsPerHost = 2000
	t.MaxIdleConnsPerHost = 2000
	t.TLSClientConfig = &tls.Config{InsecureSkipVerify: true}

	client := &http.Client{
		Timeout:   time.Duration(cfg.TimeoutSec) * time.Second,
		Transport: t,
	}

	var (
		results  []Result
		mu       sync.Mutex
		inflight int64
		sent     uint64
		success  uint64
		fail     uint64
	)

	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer cancel()

	start := time.Now()
	wg := sync.WaitGroup{}

	fmt.Printf("🚀 Starting Load Test (JMeter Style Report)\n")
	fmt.Printf("   URL: %s\n", cfg.URL)
	fmt.Printf("   RampUp: %ds | Steady: %ds | RampDown: %ds | MaxRPS: %d\n\n", cfg.RampUp, cfg.SteadyDur, cfg.RampDown, cfg.TargetRPS)

	// ========= PROGRESS BAR =========
	go func() {
		ticker := time.NewTicker(500 * time.Millisecond)
		defer ticker.Stop()
		for {
			select {
			case <-ctx.Done():
				return
			case t := <-ticker.C:
				elapsed := t.Sub(start).Seconds()
				if elapsed > totalTestTime.Seconds() && atomic.LoadInt64(&inflight) == 0 {
					return
				}
				pct := elapsed / totalTestTime.Seconds()
				if pct > 1.0 { pct = 1.0 }

				fmt.Printf(
					"\r%s %3.0f%% | %s/%s | Inflight: %3d | OK: %d | Err: %d",
					progressBar(pct, 20), pct*100,
					time.Duration(elapsed)*time.Second, totalTestTime,
					atomic.LoadInt64(&inflight),
					atomic.LoadUint64(&success),
					atomic.LoadUint64(&fail),
				)
			}
		}
	}()

	// ========= LOAD GENERATOR =========
	go func() {
		nextRequestTime := start
		for {
			select {
			case <-ctx.Done():
				return
			default:
				now := time.Now()
				elapsed := now.Sub(start).Seconds()
				if elapsed >= totalTestTime.Seconds() {
					return
				}

				targetRPS := getCurrentRPS(elapsed, cfg)
				if targetRPS <= 0.1 {
					time.Sleep(100 * time.Millisecond)
					nextRequestTime = time.Now()
					continue
				}

				waitDuration := time.Duration(float64(time.Second) / targetRPS)
				if nextRequestTime.After(now) {
					time.Sleep(nextRequestTime.Sub(now))
				}

				wg.Add(1)
				atomic.AddUint64(&sent, 1)
				atomic.AddInt64(&inflight, 1)

				go func() {
					defer wg.Done()
					defer atomic.AddInt64(&inflight, -1)

					userID := uuid.New().String()
					chatID := uuid.New().String()
					q := questions[rand.Intn(len(questions))]
					body, _ := json.Marshal(map[string]string{"query": q})

					req, _ := http.NewRequest(
						"POST",
						fmt.Sprintf("%s?chatID=%s&userID=%s", cfg.URL, chatID, userID),
						bytes.NewBuffer(body),
					)
					req.Header.Set("Content-Type", "application/json")

					startReq := time.Now()
					resp, err := client.Do(req)
					lat := time.Since(startReq)

					res := Result{
						TimeStamp: startReq,
						Latency:   lat,
						Err:       err,
						UserID:    userID,
						Query:     q,
					}

					if err == nil {
						res.Status = resp.StatusCode
						res.Bytes = resp.ContentLength
						
						// If ContentLength is -1 (unknown), we approximate from body read later
						
						// --- BODY CAPTURE (Debug) ---
						if resp.StatusCode >= 300 {
							bodyBytes, _ := io.ReadAll(resp.Body)
							if res.Bytes <= 0 { res.Bytes = int64(len(bodyBytes)) }
							
							// Truncate to avoid massive logs for CSV
							limit := 500
							if len(bodyBytes) < limit { limit = len(bodyBytes) }
							res.ResponseBody = string(bodyBytes[:limit])
						} else {
							// For success, consume body to free connection
							io.Copy(io.Discard, resp.Body)
						}
						resp.Body.Close()

						if resp.StatusCode >= 200 && resp.StatusCode < 300 {
							res.Success = true
							atomic.AddUint64(&success, 1)
						} else {
							res.Success = false
							atomic.AddUint64(&fail, 1)
						}
					} else {
						res.Success = false
						atomic.AddUint64(&fail, 1)
					}

					mu.Lock()
					results = append(results, res)
					mu.Unlock()
				}()

				nextRequestTime = nextRequestTime.Add(waitDuration)
				if time.Since(nextRequestTime) > 1*time.Second {
					nextRequestTime = time.Now()
				}
			}
		}
	}()

	time.Sleep(totalTestTime + 500*time.Millisecond)
	if atomic.LoadInt64(&inflight) > 0 {
		fmt.Printf("\n\n⚠️  Waiting for %d inflight requests...", atomic.LoadInt64(&inflight))
	}
	wg.Wait()
	
	totalRealTime := time.Since(start)

	// ========= CSV EXPORT (JMeter Friendly) =========
	// Columns: timeStamp,elapsed,label,responseCode,responseMessage,threadName,success,bytes,url,Latency,Error,DebugBody
	if cfg.OutPrefix != "" {
		csvFile, _ := os.Create(cfg.OutPrefix + ".csv")
		csvWriter := csv.NewWriter(csvFile)
		
		// Header
		csvWriter.Write([]string{
			"timeStamp", 
			"elapsed", 
			"label", 
			"responseCode", 
			"responseMessage", 
			"threadName", 
			"success", 
			"bytes", 
			"url",
			"query", // Extra field useful for you
			"failureMessage",
			"debugBody",
		})

		for _, r := range results {
			// timeStamp: Unix ms
			ts := fmt.Sprintf("%d", r.TimeStamp.UnixMilli())
			// elapsed: ms
			el := fmt.Sprintf("%d", r.Latency.Milliseconds())
			// responseMessage: "OK" or error text
			msg := "OK"
			if r.Err != nil { msg = r.Err.Error() } else if r.Status >= 400 { msg = http.StatusText(r.Status) }
			
			// failureMessage: Grouped error for pivot tables
			failMsg := ""
			if !r.Success {
				if r.Err != nil {
					failMsg = r.Err.Error()
				} else {
					failMsg = fmt.Sprintf("HTTP %d", r.Status)
				}
			}

			// clean body
			cleanBody := strings.ReplaceAll(r.ResponseBody, "\n", " ")
			cleanBody = strings.ReplaceAll(cleanBody, "\"", "'")

			csvWriter.Write([]string{
				ts,
				el,
				"Search_API", // Label
				strconv.Itoa(r.Status),
				msg,
				r.UserID, // threadName
				strconv.FormatBool(r.Success),
				fmt.Sprintf("%d", r.Bytes),
				cfg.URL,
				r.Query,
				failMsg,
				cleanBody,
			})
		}
		csvWriter.Flush()
		csvFile.Close()
	}

	// ========= CONSOLE REPORT =========
	var latencies []float64
	uniqueErrors := make(map[FailureSignature]int)
	statusCodes := make(map[int]int)

	for _, r := range results {
		if r.Success {
			latencies = append(latencies, float64(r.Latency.Milliseconds()))
		}

		statusCodes[r.Status]++

		if !r.Success {
			errStr := ""
			if r.Err != nil { errStr = r.Err.Error() }
			
			if strings.Contains(errStr, "Timeout") || strings.Contains(errStr, "deadline exceeded") {
				errStr = "Client Timeout"
			}

			sig := FailureSignature{
				Status: r.Status,
				Body:   strings.TrimSpace(r.ResponseBody),
				Err:    errStr,
			}
			uniqueErrors[sig]++
		}
	}

	sort.Float64s(latencies)
	avg := 0.0
	if len(latencies) > 0 {
		sum := 0.0
		for _, l := range latencies { sum += l }
		avg = sum / float64(len(latencies))
	}

	fmt.Println("\n\n================ LOAD TEST REPORT ================")
	fmt.Printf("Total Duration : %s\n", totalRealTime)
	fmt.Printf("Requests Sent  : %d\n", len(results))
	fmt.Printf("Success        : %d\n", success)
	fmt.Printf("Failures       : %d\n", fail)

	fmt.Println("\n🐢 LATENCY (Success Only)")
	fmt.Printf("   Avg  : %.0fms\n", avg)
	fmt.Printf("   P50  : %.0fms\n", percentile(latencies, 50))
	fmt.Printf("   P90  : %.0fms\n", percentile(latencies, 90))
	fmt.Printf("   P95  : %.0fms\n", percentile(latencies, 95))
	fmt.Printf("   P99  : %.0fms\n", percentile(latencies, 99))
	fmt.Printf("   Max  : %.0fms\n", percentile(latencies, 100))

	if len(uniqueErrors) > 0 {
		fmt.Println("\n🔍 FAILURE ANALYSIS")
		fmt.Println("--------------------------------------------------")
		for sig, count := range uniqueErrors {
			fmt.Printf("Count: %d\n", count)
			if sig.Err != "" {
				fmt.Printf("❌ Error:  %s\n", sig.Err)
			}
			if sig.Status > 0 {
				fmt.Printf("📡 Status: %d\n", sig.Status)
			}
			if sig.Body != "" {
				fmt.Printf("📄 Body:   \"%s\"\n", sig.Body)
			}
			fmt.Println("--------------------------------------------------")
		}
	}

	if cfg.OutPrefix != "" {
		fmt.Printf("\n💾 Results saved to: %s.csv\n", cfg.OutPrefix)
	}
	fmt.Println("==================================================")
}