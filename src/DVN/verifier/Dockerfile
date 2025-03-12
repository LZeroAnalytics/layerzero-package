# Stage 1: Build
FROM node:20-alpine AS builder
WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install

# Copy the rest of the source code
COPY . .

# Build the project (assumes a "build" script exists)
RUN npm run build

# Stage 2: Production Image
FROM node:20-alpine
WORKDIR /app

# Copy the built code
COPY --from=builder /app/dist ./dist
COPY package*.json ./
RUN npm install --only=production

# Set the command to run your application
CMD ["node", "dist/index.js"]
