#!/bin/bash
set -e

echo "=== FastAPI + Nginx Reverse Proxy Optimization ==="
echo "⚡ Testing FastAPI Docker optimization"
echo "📍 Working directory: $(pwd)"
echo

# Check Docker status
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker is not accessible"
    exit 1
else
    echo "✅ Docker is accessible"
fi

echo "📦 Building FastAPI Docker images..."

cd api

# Build bad version
echo "  Building bad (single-stage) version..."
time docker build -f Dockerfile.bad -t fastapi:bad . >/dev/null 2>&1

# Build optimized version
echo "  Building optimized (multi-stage) version..."
time docker build --target production -t fastapi:good . >/dev/null 2>&1

cd ..

echo "  Building Nginx reverse proxy..."
time docker build -t nginx-proxy:latest ./nginx >/dev/null 2>&1

echo
echo "=== FASTAPI IMAGE SIZE COMPARISON ==="
docker images | grep -E "(fastapi|nginx-proxy)" | awk '{printf "%-25s %-10s %-15s\n", $1":"$2, $7$8, "("$3")"}'

echo
echo "=== SYSTEM RESOURCES ==="
echo "💻 System Info:"
echo "  OS: $(lsb_release -d | cut -f2)"
echo "  Memory: $(free -h | grep Mem | awk '{print $3 "/" $2}')"
echo "  Disk: $(df -h . | tail -1 | awk '{print $3 "/" $2 " (" $5 " used)"}')"

echo
echo "🐳 Docker Resource Usage:"
docker system df

FASTAPI_BAD=$(docker images fastapi:bad --format "{{.Size}}")
FASTAPI_GOOD=$(docker images fastapi:good --format "{{.Size}}")
NGINX_SIZE=$(docker images nginx-proxy:latest --format "{{.Size}}")

echo
echo "=== IMPROVEMENT SUMMARY ==="
echo "FastAPI: $FASTAPI_BAD → $FASTAPI_GOOD"
echo "Nginx Proxy: $NGINX_SIZE"
echo
echo "🎉 FastAPI + Reverse Proxy optimization complete!"
echo "🛡️ Ready for production deployment with security!"