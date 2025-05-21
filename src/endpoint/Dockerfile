# Use multi-stage build for both arm64 and amd64
FROM --platform=$BUILDPLATFORM ubuntu:24.04 as builder

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

# Install the protocol's own dependencies (uses remappings in foundry.toml)
RUN forge install


FROM --platform=$TARGETPLATFORM ubuntu:24.04

# Install runtime dependencies needed by entrypoint scripts
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl jq ca-certificates nodejs npm git \
     && rm -rf /var/lib/apt/lists/*

# Install foundry
RUN curl -L https://foundry.paradigm.xyz | bash
ENV PATH="/root/.foundry/bin:${PATH}"
RUN foundryup

# Copy compiled contracts from builder
COPY --from=builder /app/LayerZero-v2/packages/layerzero-v2/evm/protocol /app/endpoint

WORKDIR /app/endpoint

RUN npm install
RUN mkdir -p /lib && cd /lib && git clone --depth 1 https://github.com/foundry-rs/forge-std.git
RUN forge build

# Add entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
