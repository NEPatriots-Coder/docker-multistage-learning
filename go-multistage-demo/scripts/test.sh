#!/bin/bash
set -e

echo "=== Testing Go Application ==="

# Run Go tests
echo "Running Go tests..."
go test -v ./...

# Build the application
echo "Building application..."
go build -o bin/test-api main.go

# Start the application in background
echo "Starting application for integration tests..."
./bin/test-api &
PID=$!
sleep 2

# Test endpoints
echo "Testing API endpoints..."

# Test health endpoint
echo "  Testing /health..."
HEALTH_RESPONSE=$(curl -s http://localhost:8080/health)
if echo "$HEALTH_RESPONSE" | grep -q "healthy"; then
    echo "  ✅ Health check passed"
else
    echo "  ❌ Health check failed"
    echo "  Response: $HEALTH_RESPONSE"
fi

# Test users endpoint
echo "  Testing /api/users..."
USERS_RESPONSE=$(curl -s http://localhost:8080/api/users)
if echo "$USERS_RESPONSE" | grep -q "John Doe"; then
    echo "  ✅ Users endpoint passed"
else
    echo "  ❌ Users endpoint failed"
    echo "  Response: $USERS_RESPONSE"
fi

# Test status endpoint
echo "  Testing /api/status..."
STATUS_RESPONSE=$(curl -s http://localhost:8080/api/status)
if echo "$STATUS_RESPONSE" | grep -q "running"; then
    echo "  ✅ Status endpoint passed"
else
    echo "  ❌ Status endpoint failed"
    echo "  Response: $STATUS_RESPONSE"
fi

# Clean up
kill $PID 2>/dev/null || true
rm -f bin/test-api

echo "✅ All tests completed!"