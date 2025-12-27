# Use a smaller base image with just the essentials
FROM alpine:latest as builder

# Install Go and build dependencies
RUN apk add --no-cache \
    ca-certificates \
    curl \
    git \
    go \
    make \
    gcc \
    musl-dev \
    && update-ca-certificates

# Set Go environment
ENV GO111MODULE=on \
    GOPROXY=https://proxy.golang.org,direct \
    CGO_ENABLED=0

# Build dockerz from source
WORKDIR /build
COPY . .
RUN go mod tidy && \
    go build -ldflags="-s -w" -o dockerz ./cmd/dockerz

# Create a minimal runtime image
FROM alpine:latest

# Install only runtime dependencies
RUN apk add --no-cache \
    ca-certificates \
    bash \
    curl \
    docker-cli \
    git \
    && update-ca-certificates

# Copy the built binary from builder stage
COPY --from=builder /build/dockerz /usr/local/bin/dockerz

# Set working directory
WORKDIR /workspace

# Verify installations
RUN dockerz --version

# Use dockerz as the default entrypoint
ENTRYPOINT ["dockerz"]