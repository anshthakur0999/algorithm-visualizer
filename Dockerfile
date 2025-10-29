FROM node:18-alpine

WORKDIR /app

# Copy application files
COPY index.html .
COPY app.js .
COPY style.css .
COPY package.json .
COPY server.js .

# Install dependencies
RUN npm install --production

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080 || exit 1

# Start application
CMD ["node", "server.js"]
