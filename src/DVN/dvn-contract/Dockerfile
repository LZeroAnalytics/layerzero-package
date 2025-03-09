# syntax=docker/dockerfile:1

#############################
# Stage 1: Build the Contracts
#############################
FROM ghcr.io/foundry-rs/foundry:latest AS builder
USER root
WORKDIR /app

# Copy the project files into the container.
COPY . .

# Ensure the cache directory exists and is writable
RUN mkdir -p /app/cache && chmod -R 777 /app/cache

# Install dependencies and compile the contracts.
RUN forge build

#############################
# Stage 2: Runtime Container
#############################
FROM ghcr.io/foundry-rs/foundry:latest
USER root
WORKDIR /app

RUN apt-get update && apt-get install -y jq

# Copy all project files (including built artifacts) from the builder stage.
COPY --from=builder /app /app

# Set the default command to bash.
CMD ["bash"]