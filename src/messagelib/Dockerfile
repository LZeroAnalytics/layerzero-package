# Use multi-stage build for both arm64 and amd64
FROM --platform=$BUILDPLATFORM node:18 as builder

# Install dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Foundry
RUN curl -L https://foundry.paradigm.xyz | bash
ENV PATH="/root/.foundry/bin:${PATH}"
RUN foundryup

WORKDIR /app

# Clone the official LayerZero repository
RUN git clone --depth 1 --branch main https://github.com/LayerZero-Labs/LayerZero-v2.git

# Copy our deployment scripts
COPY messagelib-contracts/script/Deploy.sol /app/LayerZero-v2/packages/layerzero-v2/evm/messagelib/script/Deploy.sol
COPY messagelib-contracts/script/DeploySendLib.sol /app/LayerZero-v2/packages/layerzero-v2/evm/messagelib/script/DeploySendLib.sol

WORKDIR /app/LayerZero-v2/packages/layerzero-v2/evm/messagelib

# Install dependencies and build
RUN forge install

FROM --platform=$TARGETPLATFORM node:18-slim

# Copy compiled contracts from builder
COPY --from=builder /app/LayerZero-v2/packages/layerzero-v2/evm/messagelib /app/messagelib

WORKDIR /app/messagelib

# Add entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
