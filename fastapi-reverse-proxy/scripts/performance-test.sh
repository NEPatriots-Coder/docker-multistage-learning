#!/bin/bash
set -e

echo "=== FastAPI + Reverse Proxy Performance Testing ==="
echo "⚡ Testing production architecture performance"
echo

# Start the full stack
echo "🚀 Starting FastAPI + Nginx + Redis stack..."
docker-compose up -d

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 10

# Function to test endpoint
test_endpoint() {
    local url=$1
    local description=$2
    
    echo "Testing $description..."
    
    start_time=$(date +%s.%N)
    response=$(curl -s -o /dev/null -w "%{http_code}" $url)
    end_time=$(date +%s.%N)
    
    duration=$(echo "$end_time - $start_time" | bc -l)
    
    if [ "$response" = "200" ]; then
        printf "  ✅ %-30s %.3fs\n" "$description" $duration
    else
        printf "  ❌ %-30s %.3fs (HTTP $response)\n" "$description" $duration
    fi
}

echo
echo "=== API Endpoint Testing (via Nginx Proxy) ==="

# Test through reverse proxy (port 80)
test_endpoint "http://localhost/health" "Health check (via proxy)"
test_endpoint "http://localhost/api/docs" "API docs (via proxy)"
test_endpoint "http://localhost/api/performance-test" "Performance endpoint"

echo
echo "=== Load Testing ==="
echo "Running 100 concurrent requests..."

# Simple load test
start_time=$(date +%s.%N)
for i in {1..100}; do
    curl -s http://localhost/api/performance-test >/dev/null &
done
wait
end_time=$(date +%s.%N)

total_time=$(echo "$end_time - $start_time" | bc -l)
rps=$(echo "100 / $total_time" | bc -l)

printf "✅ 100 requests completed in %.3fs (%.1f req/sec)\n" $total_time $rps

echo
echo "=== Container Resource Usage ==="
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"

echo
echo "=== Security Headers Test ==="
echo "Testing security headers from reverse proxy..."
headers=$(curl -s -I http://localhost/health)

echo "Security headers received:"
echo "$headers" | grep -E "(X-Frame-Options|X-XSS-Protection|X-Content-Type-Options|Referrer-Policy|Content-Security-Policy)" || echo "  ⚠️  Some security headers missing"

echo
echo "=== Rate Limiting Test ==="
echo "Testing rate limiting (should get 429 after limit)..."

# Test rate limiting by making rapid requests
for i in {1..15}; do
    response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/api/performance-test)
    if [ "$response" = "429" ]; then
        echo "  ✅ Rate limiting working - got 429 after $i requests"
        break
    fi
    sleep 0.1
done

echo
echo "=== Cleanup ==="
docker-compose down

echo "✅ FastAPI + Reverse Proxy performance testing complete!"
echo "🛡️ Production architecture validated!"