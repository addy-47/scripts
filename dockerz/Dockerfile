FROM google/cloud-sdk:latest

# Install necessary dependencies and Docker CLI
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y --no-install-recommends docker-ce-cli

# Install Go
ENV GO_VERSION=1.21.0
RUN curl -fsSL "https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o go.tar.gz && \
    tar -C /usr/local -xzf go.tar.gz && \
    rm go.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"

# Build dockerz from source
COPY . /app/dockerz
WORKDIR /app/dockerz
RUN go mod tidy && \
    go build -o dockerz ./cmd/dockerz && \
    mv dockerz /usr/local/bin/

# Set the working directory for the final image
WORKDIR /workspace

# Verify installations
RUN gcloud --version && docker --version && git --version && dockerz --version

ENTRYPOINT ["/bin/bash"]