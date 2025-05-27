#!/bin/bash
set -e

echo "=== Building Go Application ==="

# Create bin directory if it doesn't exist
mkdir -p bin

echo "Building optimized binary..."
CGO_ENABLED=0 GOOS=linux go build -ldflags='-w -s' -o bin/api main.go

echo "✅ Build complete: bin/api"
echo "📊 Binary size: $(ls -lh bin/api | awk '{print $5}')"

# Test the binary
echo "🧪 Testing binary..."
./bin/api &
PID=$!
sleep 2

# Test health endpoint
if curl -s http://localhost:8080/health >/dev/null; then
    echo "✅ Health check passed"
else
    echo "❌ Health check failed"
fi

# Clean up
kill $PID 2>/dev/null || true
echo "✅ Build and test complete!"