package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"
)

// AppInfo holds application metadata
type AppInfo struct {
	Name      string    `json:"name"`
	Version   string    `json:"version"`
	Hostname  string    `json:"hostname"`
	Timestamp time.Time `json:"timestamp"`
	Message   string    `json:"message"`
}

// HealthStatus represents health check response
type HealthStatus struct {
	Status  string    `json:"status"`
	Uptime  string    `json:"uptime"`
	Checked time.Time `json:"checked"`
}

var startTime = time.Now()

func main() {
	// Configuration
	port := getEnv("PORT", "8080")
	appName := getEnv("APP_NAME", "go-demo-app")
	appVersion := getEnv("APP_VERSION", "1.0.0")

	// Routes
	http.HandleFunc("/", homeHandler(appName, appVersion))
	http.HandleFunc("/health", healthHandler)
	http.HandleFunc("/ready", readyHandler)
	http.HandleFunc("/api/info", apiInfoHandler(appName, appVersion))

	// Start server
	addr := ":" + port
	log.Printf("Starting %s v%s on %s", appName, appVersion, addr)
	log.Printf("Endpoints: /, /health, /ready, /api/info")

	if err := http.ListenAndServe(addr, nil); err != nil {
		log.Fatalf("Server failed to start: %v", err)
	}
}

// homeHandler serves the main HTML page
func homeHandler(appName, appVersion string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		hostname, _ := os.Hostname()

		html := fmt.Sprintf(`
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>%s - Kubernetes Demo</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #667eea 0%%, #764ba2 100%%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            padding: 60px;
            max-width: 600px;
            width: 100%%;
        }
        h1 {
            color: #333;
            font-size: 2.5em;
            margin-bottom: 10px;
            text-align: center;
        }
        .emoji { font-size: 4em; text-align: center; margin: 20px 0; }
        .info {
            background: #f7f7f7;
            border-left: 4px solid #667eea;
            padding: 20px;
            margin: 20px 0;
            border-radius: 5px;
        }
        .info-item {
            display: flex;
            justify-content: space-between;
            padding: 10px 0;
            border-bottom: 1px solid #e0e0e0;
        }
        .info-item:last-child { border-bottom: none; }
        .label { font-weight: bold; color: #666; }
        .value { color: #333; font-family: 'Courier New', monospace; }
        .badge {
            display: inline-block;
            background: #667eea;
            color: white;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 0.9em;
            margin-top: 10px;
        }
        .links {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 15px;
            margin-top: 30px;
        }
        .link-btn {
            background: #667eea;
            color: white;
            padding: 15px;
            text-align: center;
            border-radius: 10px;
            text-decoration: none;
            transition: all 0.3s;
        }
        .link-btn:hover {
            background: #764ba2;
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(0,0,0,0.2);
        }
        footer {
            margin-top: 30px;
            text-align: center;
            color: #999;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="emoji">🚀</div>
        <h1>Kubernetes Demo</h1>
        <p style="text-align: center; color: #666; margin-bottom: 30px;">
            Running on KIND (Kubernetes IN Docker)
        </p>

        <div class="info">
            <div class="info-item">
                <span class="label">Application:</span>
                <span class="value">%s</span>
            </div>
            <div class="info-item">
                <span class="label">Version:</span>
                <span class="value">%s</span>
            </div>
            <div class="info-item">
                <span class="label">Pod/Hostname:</span>
                <span class="value">%s</span>
            </div>
            <div class="info-item">
                <span class="label">Request Time:</span>
                <span class="value">%s</span>
            </div>
        </div>

        <div class="links">
            <a href="/api/info" class="link-btn">📊 API Info</a>
            <a href="/health" class="link-btn">💚 Health Check</a>
        </div>

        <footer>
            <p>Learning Kubernetes with KIND</p>
            <p style="margin-top: 5px;">Refresh the page to see which pod handles the request!</p>
        </footer>
    </div>
</body>
</html>
`, appName, appName, appVersion, hostname, time.Now().Format(time.RFC3339))

		w.Header().Set("Content-Type", "text/html; charset=utf-8")
		w.WriteHeader(http.StatusOK)
		fmt.Fprint(w, html)

		log.Printf("Served request from %s to pod %s", r.RemoteAddr, hostname)
	}
}

// healthHandler provides liveness probe endpoint
func healthHandler(w http.ResponseWriter, r *http.Request) {
	uptime := time.Since(startTime)

	status := HealthStatus{
		Status:  "healthy",
		Uptime:  uptime.String(),
		Checked: time.Now(),
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(status)
}

// readyHandler provides readiness probe endpoint
func readyHandler(w http.ResponseWriter, r *http.Request) {
	// In a real app, check dependencies (DB, cache, etc.)
	status := map[string]string{
		"status": "ready",
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(status)
}

// apiInfoHandler provides JSON API endpoint
func apiInfoHandler(appName, appVersion string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		hostname, _ := os.Hostname()

		info := AppInfo{
			Name:      appName,
			Version:   appVersion,
			Hostname:  hostname,
			Timestamp: time.Now(),
			Message:   "Hello from Kubernetes!",
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(info)
	}
}

// getEnv gets environment variable with fallback
func getEnv(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}
