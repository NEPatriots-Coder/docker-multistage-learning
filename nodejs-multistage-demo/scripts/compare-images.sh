#!/bin/bash
set -e

echo "=== Docker Multi-Stage Build Comparison ==="
echo "🐧 Running on Linux Mint VM"
echo "💪 Full system resources available!"
echo "📍 Working directory: $(pwd)"
echo

# Check Docker status
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker is not accessible. Please run:"
    echo "   sudo usermod -aG docker $USER"
    echo "   Then log out and log back in"
    exit 1
else
    echo "✅ Docker is accessible without sudo"
fi

# Determine which project we're in
if [ -f "server.js" ]; then
    PROJECT="nodejs"
    echo "📦 Detected Node.js project"
elif [ -f "main.go" ]; then
    PROJECT="go"
    echo "📦 Detected Go project"
else
    echo "❌ Unknown project type"
    exit 1
fi

# Build images with timing
echo "Building images..."
if [ "$PROJECT" = "nodejs" ]; then
    echo "  Building bad version..."
    time docker build -f Dockerfile.bad -t nodejs-api:bad . >/dev/null 2>&1
    echo "  Building optimized version..."
    time docker build --target production -t nodejs-api:good . >/dev/null 2>&1
    
    echo
    echo "=== NODE.JS IMAGE SIZE COMPARISON ==="
    docker images | grep nodejs-api | awk '{printf "%-20s %-10s %-15s\n", $1":"$2, $7$8, "("$3")"}'
    
    NODEJS_BAD=$(docker images nodejs-api:bad --format "{{.Size}}")
    NODEJS_GOOD=$(docker images nodejs-api:good --format "{{.Size}}")
    echo
    echo "=== IMPROVEMENT SUMMARY ==="
    echo "Node.js: $NODEJS_BAD → $NODEJS_GOOD"
    
elif [ "$PROJECT" = "go" ]; then
    echo "  Building bad version..."
    time docker build -f Dockerfile.bad -t go-api:bad . >/dev/null 2>&1
    echo "  Building optimized version..."
    time docker build -t go-api:good . >/dev/null 2>&1
    
    echo
    echo "=== GO IMAGE SIZE COMPARISON ==="
    docker images | grep go-api | awk '{printf "%-20s %-10s %-15s\n", $1":"$2, $7$8, "("$3")"}'
    
    GO_BAD=$(docker images go-api:bad --format "{{.Size}}")
    GO_GOOD=$(docker images go-api:good --format "{{.Size}}")
    echo
    echo "=== IMPROVEMENT SUMMARY ==="
    echo "Go: $GO_BAD → $GO_GOOD"
fi

echo
echo "=== LINUX MINT SYSTEM RESOURCES ==="
echo "💻 System Info:"
echo "  OS: $(lsb_release -d | cut -f2)"
echo "  Memory: $(free -h | grep Mem | awk '{print $3 "/" $2}')"
echo "  Disk: $(df -h $HOME | tail -1 | awk '{print $3 "/" $2 " (" $5 " used)"}')"

echo
echo "🐳 Docker Resource Usage:"
docker system df

echo
echo "🎉 Multi-stage builds significantly reduce image sizes!"
echo "🚀 Running on Linux Mint gives you full control and performance!"
