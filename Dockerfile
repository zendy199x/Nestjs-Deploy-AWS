# Base stage to install node dependencies
FROM --platform=linux/amd64 node:16-alpine AS base
WORKDIR /app

# Copy package.json and package-lock.json to leverage Docker cache
COPY package*.json ./

# Install Node.js dependencies
RUN npm install

# Build stage to transpile `src` into `dist`
FROM base AS build

# Copy necessary files for the build stage
COPY --from=base package*.json ./
COPY --from=base /app/node_modules ./node_modules
COPY . .

# Run the build script and prune unnecessary dependencies
RUN npm run build \
  && npm prune --production

# Display the contents of the /app directory for debugging
RUN ls -la /app

# Final stage for the production app image
FROM node:16-alpine AS production

# Set environment variables
ENV NODE_ENV="production"
ENV PORT=3000

# Create a non-system user for running the application
RUN adduser -s /bin/sh -D myuser \
  && mkdir -p /app/shared/public \
  && chown -R myuser:myuser /app

USER myuser

# Display the contents of the /app directory for debugging
RUN ls -la /app

# Copy the built application files from the build stage
COPY --from=build --chown=myuser:myuser /app/dist ./dist

# Remove the following lines if you don't have public files
# COPY --from=build --chown=myuser:myuser /app/public ./public
RUN mkdir -p /app/shared/public

# Display the contents of the /app directory for debugging
RUN ls -la /app

# Expose the application port
EXPOSE $PORT

# Command to run the application
CMD ["node", "dist/src/main.js"]

