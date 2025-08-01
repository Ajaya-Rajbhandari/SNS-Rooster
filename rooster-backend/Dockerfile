# syntax=docker/dockerfile:1

ARG NODE_VERSION=22.13.1
FROM node:${NODE_VERSION}-slim AS base
WORKDIR /app

# Install dependencies in a separate layer for better caching
COPY --link package.json package-lock.json ./

# Use npm ci for deterministic, clean installs
RUN --mount=type=cache,target=/root/.npm \
    npm ci --production

# Copy application source code (excluding files via .dockerignore)
COPY --link . .

# Create a non-root user and group for security
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser

# Set environment variables
ENV NODE_ENV=production
ENV NODE_OPTIONS="--max-old-space-size=4096"

# Expose the default port (change if your app uses a different port)
EXPOSE 5000

# Set ownership and switch to non-root user
RUN chown -R appuser:appgroup /app
USER appuser

# Start the application
CMD ["npm", "start"]
