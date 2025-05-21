# Use multi-stage build for both arm64 and amd64
FROM --platform=$BUILDPLATFORM node:18 as builder

# Install dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    build-essential \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install Foundry
RUN curl -L https://foundry.paradigm.xyz | bash
ENV PATH="/root/.foundry/bin:${PATH}"
RUN foundryup

WORKDIR /app

# Clone the official LayerZero repository
RUN git clone --depth 1 --branch main https://github.com/LayerZero-Labs/LayerZero-v2.git

# Copy our deployment script
COPY endpoint-contracts/script/Deploy.sol /app/LayerZero-v2/packages/layerzero-v2/evm/protocol/script/Deploy.sol

WORKDIR /app/LayerZero-v2/packages/layerzero-v2/evm/protocol

# Install dependencies and build
RUN forge install


FROM --platform=$TARGETPLATFORM node:18-slim

# Install runtime dependencies needed by entrypoint scripts
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl jq ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Copy Foundry binaries from the builder stage
COPY --from=builder /root/.foundry /root/.foundry
ENV PATH="/root/.foundry/bin:${PATH}"

# Copy compiled contracts from builder
COPY --from=builder /app/LayerZero-v2/packages/layerzero-v2/evm/protocol /app/endpoint

WORKDIR /app/endpoint

# Add entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
