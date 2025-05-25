# Stage 1: Build stage
FROM golang:1.22.2-alpine AS builder

# Install git and ca-certificates for any dependencies
RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /app

# Copy go mod files first for better caching
COPY go.mod ./
RUN go mod download && go mod verify

# Copy source code
COPY . .

# Build with optimizations for small binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags='-w -s -extldflags "-static"' \
    -a -installsuffix cgo \
    -o app main.go

# Stage 2: Security scan stage (optional but professional)
FROM alpine:3.19 AS security
RUN apk add --no-cache ca-certificates tzdata
COPY --from=builder /app/app /app
# You could add security scanning tools here
# RUN some-security-scanner /app

# Stage 3: Final ultra-minimal image
FROM scratch

# Copy timezone data for time functionality
COPY --from=security /usr/share/zoneinfo /usr/share/zoneinfo

# Copy CA certificates for HTTPS calls
COPY --from=security /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy our binary
COPY --from=builder /app/app /app

# Health check isn't available in scratch, but we can document the endpoint
LABEL healthcheck.endpoint="/health"
LABEL maintainer="your-email@company.com"
LABEL description="Optimized Go API with multi-stage build"

EXPOSE 8080
ENTRYPOINT ["/app"]