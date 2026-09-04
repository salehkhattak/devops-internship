FROM node:20-alpine

# Set working directory
WORKDIR /app

# Install dependencies first (better layer caching)
COPY package*.json ./
RUN npm ci --omit=dev

# Copy source code
COPY . .

# Expose service port
EXPOSE 3000

# Run as non-root for security
USER node

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', r => r.statusCode === 200 ? process.exit(0) : process.exit(1)).on('error', () => process.exit(1))"

CMD ["node", "app.js"]
