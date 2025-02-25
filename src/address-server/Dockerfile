# Use Node 20 as the base image
FROM node:20

# Set the working directory
WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install

# Copy the rest of the application code
COPY . .

# Build the TypeScript code
RUN npm run build

# Expose the port (default 3000)
EXPOSE 3000

# Start the server
CMD ["node", "dist/index.js"]