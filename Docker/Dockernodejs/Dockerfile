# Use official Node.js runtime as base image
FROM node:18-slim

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install only production dependencies
RUN npm ci --only=production \
    && npm cache clean --force

# Create and switch to non-root user
RUN useradd -m appuser \
    && chown appuser:appuser -R /app
USER appuser

# Copy application code
COPY --chown=appuser:appuser . .

# Expose port 8080
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl -f http://localhost:8080/health || exit 1

# Run the app
CMD ["node", "app.js"]