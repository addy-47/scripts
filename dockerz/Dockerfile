# Use a smaller base image with just the essentials for building
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
COPY go.mod go.sum .
COPY . .
RUN go mod tidy && \
    go build -ldflags="-s -w" -o dockerz ./cmd/dockerz

# Use the official Docker image as the base
FROM docker:latest

# Install additional dependencies
RUN apk add --no-cache \
    ca-certificates \
    bash \
    curl \
    git \
    python3 \
    py3-pip \
    && update-ca-certificates

# Install gcloud CLI
RUN curl -sSL https://sdk.cloud.google.com | bash -s -- --disable-prompts \
    && /root/google-cloud-sdk/bin/gcloud --quiet components update

# Ensure gcloud is on PATH at runtime and make `gcloud` callable from /usr/local/bin
ENV PATH="/root/google-cloud-sdk/bin:${PATH}"
RUN ln -s /root/google-cloud-sdk/bin/gcloud /usr/local/bin/gcloud || true

# Install docker-buildx plugin (already included in docker:latest, but ensure it's up-to-date)
RUN mkdir -p /usr/libexec/docker/cli-plugins \
    && curl -sSL -o /usr/libexec/docker/cli-plugins/docker-buildx \
       "https://github.com/docker/buildx/releases/latest/download/buildx-$(uname -s)-$(uname -m)" \
    && chmod +x /usr/libexec/docker/cli-plugins/docker-buildx

# Build dockerz from source
WORKDIR /build
COPY go.mod go.sum .
COPY . .
RUN go mod tidy && \
    go build -ldflags="-s -w" -o dockerz ./cmd/dockerz

# Copy the built binary to the final image
COPY --from=builder /build/dockerz /usr/local/bin/dockerz

# Set working directory
WORKDIR /workspace

# Verify installations
RUN dockerz --version

# Use dockerz as the default entrypoint
ENTRYPOINT ["dockerz"]