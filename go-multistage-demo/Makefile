.PHONY: build run test docker-build docker-run clean size-compare

# Go commands
build:
	go build -o bin/api main.go

run:
	go run main.go

test:
	go test ./...

# Docker commands
docker-build:
	docker build -t go-api:latest .

docker-build-bad:
	docker build -f Dockerfile.bad -t go-api:bad .

docker-run:
	docker run -p 8080:8080 go-api:latest

# Utilities
clean:
	rm -rf bin/
	docker image prune -f

size-compare:
	@echo "Image sizes:"
	@docker images | grep go-api

# Development
dev:
	go run main.go

# Build optimized binary locally
build-optimized:
	CGO_ENABLED=0 GOOS=linux go build -ldflags='-w -s' -o bin/api main.go