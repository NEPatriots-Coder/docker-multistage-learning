#!/bin/bash
set -e

echo "=== Performance Testing on Linux Mint VM ==="
echo "💪 Full system resources available for testing"
echo

# Determine which project we're in
if [ -f "server.js" ]; then
    PROJECT="nodejs"
    PORT_BASE=3000
    IMAGE_PREFIX="nodejs-api"
    HEALTH_ENDPOINT="/health"
elif [ -f "main.go" ]; then
    PROJECT="go"
    PORT_BASE=8080
    IMAGE_PREFIX="go-api"
    HEALTH_ENDPOINT="/health"
else
    echo "❌ Unknown project type"
    exit 1
fi

echo "📦 Testing $PROJECT project"

# Function to test startup time
test_startup_time() {
    local image=$1
    local port=$2
    local name=$3
    
    echo "Testing startup time for $image..."
    
    # Remove any existing container
    docker rm -f $name >/dev/null 2>&1 || true
    
    # Time the startup with better precision
    start_time=$(date +%s.%N)
    docker run -d -p $port:$PORT_BASE --name $name $image >/dev/null
    
    # Wait for health check
    for i in {1..30}; do
        if curl -s http://localhost:$port$HEALTH_ENDPOINT >/dev/null 2>&1; then
            end_time=$(date +%s.%N)
            startup_time=$(echo "$end_time - $start_time" | bc -l)
            printf "✅ %-15s started in %.3fs\n" $image $startup_time
            break
        fi
        sleep 0.1  # Faster polling on native Linux
    done
    
    # Clean up
    docker stop $name >/dev/null
    docker rm $name >/dev/null
}

# System performance baseline
echo "=== System Performance Baseline ==="
echo "CPU cores: $(nproc)"
echo "Memory: $(free -h | grep Mem | awk '{print $2}')"
echo "Available memory: $(free -h | grep Mem | awk '{print $7}')"
echo "Docker version: $(docker --version)"
echo "Disk I/O test:"
dd if=/dev/zero of=/tmp/test_io bs=1M count=100 2>&1 | grep -o '[0-9.]* [MG]B/s'
rm /tmp/test_io
echo

# Test applications
echo "=== Container Startup Performance ==="
if [ "$PROJECT" = "nodejs" ]; then
    test_startup_time "nodejs-api:bad" "3010" "nodejs-test-bad"
    test_startup_time "nodejs-api:good" "3011" "nodejs-test-good"
    
    echo
    echo "=== Memory Usage Comparison ==="
    echo "Starting optimized containers for memory testing..."
    
    # Start containers
    docker run -d -p 3020:3000 --name nodejs-mem-test nodejs-api:good >/dev/null
    sleep 2
    
    echo "Memory usage:"
    docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}\t{{.CPUPerc}}\t{{.BlockIO}}" nodejs-mem-test
    
    # Clean up
    docker stop nodejs-mem-test >/dev/null
    docker rm nodejs-mem-test >/dev/null
    
elif [ "$PROJECT" = "go" ]; then
    test_startup_time "go-api:bad" "8090" "go-test-bad"
    test_startup_time "go-api:good" "8091" "go-test-good"
    
    echo
    echo "=== Memory Usage Comparison ==="
    echo "Starting optimized containers for memory testing..."
    
    # Start containers
    docker run -d -p 8092:8080 --name go-mem-test go-api:good >/dev/null
    sleep 2
    
    echo "Memory usage:"
    docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}\t{{.CPUPerc}}\t{{.BlockIO}}" go-mem-test
    
    # Clean up
    docker stop go-mem-test >/dev/null
    docker rm go-mem-test >/dev/null
fi

echo
echo "=== Linux Mint System Impact ==="
echo "System memory after testing:"
free -h | grep Mem
echo "System load average:"
uptime

echo
echo "✅ Performance testing complete on Linux Mint!"
echo "🎯 Your VM environment provides excellent performance for development!"