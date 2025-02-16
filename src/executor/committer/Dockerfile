# Stage 1: Build
FROM node:20-alpine AS builder
WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install

# Copy the rest of the project source code
COPY . .

# Build the project (assumes you have a "build" script in package.json that compiles TypeScript)
RUN npm run build

# Stage 2: Production Image
FROM node:20-alpine
WORKDIR /app

# Copy the built output from the builder stage
COPY --from=builder /app/dist ./dist

COPY package*.json ./
RUN npm install --only=production


CMD ["node", "dist/index.js"]
