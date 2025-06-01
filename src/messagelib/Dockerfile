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

# Copy our deployment scripts
COPY messagelib-contracts/script/DeployReceiveLib.sol /app/LayerZero-v2/packages/layerzero-v2/evm/messagelib/script/DeployReceiveLib.sol
COPY messagelib-contracts/script/DeploySendLib.sol /app/LayerZero-v2/packages/layerzero-v2/evm/messagelib/script/DeploySendLib.sol

WORKDIR /app/LayerZero-v2/packages/layerzero-v2/evm/messagelib

# Install dependencies and build
RUN forge install

WORKDIR /app/LayerZero-v2/packages/layerzero-v2/evm/messagelib

RUN forge install


FROM --platform=$TARGETPLATFORM ubuntu:24.04

# Runtime tools required by entry‑point scripts
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl jq ca-certificates nodejs npm git build-essential python3 make g++ && \
    rm -rf /var/lib/apt/lists/*

# Install foundry
RUN curl -L https://foundry.paradigm.xyz | bash
ENV PATH="/root/.foundry/bin:${PATH}"
RUN foundryup

# Copy compiled contracts from builder
COPY --from=builder /app/LayerZero-v2/packages/layerzero-v2/evm/messagelib /app/messagelib

WORKDIR /app/messagelib

RUN rm package.json && npm init -y
RUN npm install --omit=optional \
      @layerzerolabs/lz-evm-v1-0.7@2.0.1 \
      @openzeppelin/contracts@4.8.1 \
      @openzeppelin/contracts-upgradeable@4.8.1 \
      solidity-bytes-utils@0.8.0 \
      hardhat-deploy@0.11.44 \
      @layerzerolabs/lz-evm-protocol-v2@2.0.20 \
      @chainlink/contracts-ccip@0.7.4 \
      @axelar-network/axelar-gmp-sdk-solidity@4.0.1
RUN mkdir -p /lib && cd /lib && git clone --depth 1 https://github.com/foundry-rs/forge-std.git
RUN forge build

# Add entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
