package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"runtime"
	"syscall"
	"time"
)

type User struct {
	ID    int    `json:"id"`
	Name  string `json:"name"`
	Email string `json:"email"`
	Role  string `json:"role"`
}

type StatusResponse struct {
	Service   string          `json:"service"`
	Status    string          `json:"status"`
	Uptime    string          `json:"uptime"`
	Memory    runtime.MemStats `json:"memory"`
	Timestamp string          `json:"timestamp"`
	GoVersion string          `json:"go_version"`
}

type HealthResponse struct {
    Status      string `json:"status"`
    Timestamp   string `json:"timestamp"`
    Environment string `json:"environment"`
    Version     string `json:"version"`
}

var startTime = time.Now()

func healthHandler(w http.ResponseWriter, r *http.Request) {
    response := HealthResponse{
        Status:      "healthy",
        Timestamp:   time.Now().UTC().Format(time.RFC3339),
        Environment: getEnv("ENV", "development"),
        Version:     "1.0.0",
    }
    
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(http.StatusOK)
    json.NewEncoder(w).Encode(response)
}

func usersHandler(w http.ResponseWriter, r *http.Request) {
    users := []User{
        {ID: 1, Name: "John Doe", Email: "john@example.com", Role: "admin"},
        {ID: 2, Name: "Jane Smith", Email: "jane@example.com", Role: "user"},
        {ID: 3, Name: "Bob Johnson", Email: "bob@example.com", Role: "user"},
        {ID: 4, Name: "Alice Wilson", Email: "alice@example.com", Role: "moderator"},
    }
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(users)
}

func statusHandler(w http.ResponseWriter, r *http.Request) {
    var m runtime.MemStats
    runtime.ReadMemStats(&m)
    
    uptime := time.Since(startTime)
    
    response := StatusResponse{
        Service:   "go-multistage-demo",
        Status:    "running",
        Uptime:    uptime.String(),
        Memory:    m,
        Timestamp: time.Now().UTC().Format(time.RFC3339),
        GoVersion: runtime.Version(),
    }
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(response)
}

func rootHandler(w http.ResponseWriter, r *http.Request) {
    response := map[string]interface{}{
        "message": "Go Multi-Stage Docker Demo API",
        "version": "1.0.0",
        "endpoints": []string{
            "GET /health - Health check",
            "GET /api/users - Get all users",
            "GET /api/status - Service status",
        },
        "go_version": runtime.Version(),
    }
    
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(response)
}

func getEnv(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}

func main() {
    http.HandleFunc("/", rootHandler)
    http.HandleFunc("/health", healthHandler)
    http.HandleFunc("/api/users", usersHandler)
    http.HandleFunc("/api/status", statusHandler)

    port := getEnv("PORT", "8080")
    
    // Graceful shutdown
    c := make(chan os.Signal, 1)
    signal.Notify(c, os.Interrupt, syscall.SIGTERM)
    
    go func() {
        log.Printf("🚀 Server starting on port %s", port)
        log.Printf("📍 Environment: %s", getEnv("ENV", "development"))
        log.Printf("🔗 Health check: http://localhost:%s/health", port)
        
        if err := http.ListenAndServe(fmt.Sprintf(":%s", port), nil); err != nil {
            log.Fatal(err)
        }
    }()

    <-c
    log.Println("🛑 Shutting down gracefully...")
}