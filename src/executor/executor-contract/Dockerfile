# syntax=docker/dockerfile:1

#############################
# Stage 1: Build the Contracts
#############################
FROM ghcr.io/foundry-rs/foundry:latest AS builder
WORKDIR /app

# Copy the project files into the container.
COPY . .

# Install dependencies and compile the contracts.
RUN forge build

#############################
# Stage 2: Runtime Container
#############################
FROM ghcr.io/foundry-rs/foundry:latest
WORKDIR /app

# Copy all project files (including built artifacts) from the builder stage.
COPY --from=builder /app /app

# Set the default command to bash.
CMD ["bash"]