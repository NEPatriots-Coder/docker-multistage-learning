# Docker Multi-Stage Build Learning Project

This repository contains two demo applications that showcase the power of Docker multi-stage builds - one built with Go and another with Node.js. Both demonstrate how to create efficient, secure, and production-ready container images.

## What's Inside

### Go API Demo

The Go application is a lightweight REST API that shows how incredibly small and efficient Go containers can be when properly optimized. It's like comparing a sports car (optimized Go container) to an SUV (standard container) - both will get you there, but one is much more efficient!

**Key Features:**
- Lightning-fast startup times (typically under 10ms!)
- Tiny final image size (just a few MB compared to hundreds of MB)
- Multiple endpoints including health checks, user data, and system status
- Graceful shutdown handling
- Built using the "scratch" base image - the absolute minimum needed to run

The multi-stage build process:
1. **Builder stage**: Compiles the Go code with optimizations
2. **Security stage**: Could add security scanning (commented example)
3. **Final stage**: Creates an ultra-minimal production image

### Node.js API Demo

The Node.js application provides a similar REST API but demonstrates best practices for containerizing JavaScript applications. Think of it as transforming a regular coffee shop into a streamlined, efficient operation where only the essential equipment and ingredients are kept.

**Key Features:**
- Proper separation of development and production dependencies
- Non-root user execution for enhanced security
- Built-in health checks for container orchestration
- Multiple API endpoints mirroring the Go version
- Graceful shutdown handling

The multi-stage build process:
1. **Dependencies stage**: Installs production dependencies
2. **Development stage**: Optional stage for local development
3. **Production stage**: Creates a secure, optimized image

## Why Multi-Stage Builds Matter

Multi-stage builds are like having a professional kitchen crew that preps everything behind the scenes, then hands off only the finished dish to the server. The customer (your production environment) never sees the mess of preparation - they just get a clean, efficient result.

Benefits include:
- **Smaller images**: Less storage, faster deployments
- **Improved security**: Fewer vulnerabilities with minimal components
- **Better caching**: Faster builds when only certain parts change
- **Cleaner process**: No build tools or artifacts in production

## Getting Started

To run either demo:

```bash
# For the Go demo
cd go-multistage-demo
docker compose up

# For the Node.js demo
cd nodejs-multistage-demo
docker compose up
```

Each demo includes both an optimized version and an unoptimized "bad" version for comparison.

## Performance Comparison

Run the included performance scripts to see the dramatic difference between optimized and unoptimized containers:

```bash
cd go-multistage-demo/scripts
./performance-test.sh

# or

cd nodejs-multistage-demo/scripts
./performance-test.sh
```

You'll see significant improvements in startup time, memory usage, and image size with the optimized builds!