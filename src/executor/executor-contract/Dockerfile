# syntax=docker/dockerfile:1

###############################
# Stage 1: Build the Contracts
###############################
FROM ghcr.io/foundry-rs/foundry:latest as builder

WORKDIR /app

# Copy all project files into the container.
COPY . .

# Update Foundry and install dependencies.
RUN foundryup && forge install

# Compile/build the contracts.
RUN forge build

###############################
# Stage 2: Runtime Container
###############################
FROM ghcr.io/foundry-rs/foundry:latest
WORKDIR /app

# Copy the entire project (including built artifacts) from the builder stage.
COPY --from=builder /app /app

# Make sure the deploy script is executable.
RUN chmod +x deploy.sh

# (Optional) Define a volume for caching if needed.
VOLUME ["/app/cache"]

# Set the default entrypoint to our deploy script.
# You can override this command when running the container.
ENTRYPOINT ["/app/deploy.sh"]
# Default CMD shows usage help.
CMD ["--help"]