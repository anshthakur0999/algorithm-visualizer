# Multi-stage build for optimized production image
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files (if they exist)
COPY package*.json ./

# Install dependencies if package.json exists
RUN if [ -f package.json ]; then npm ci --only=production; fi

# Copy source code
COPY . .

# Build step (if needed for any preprocessing)
# For static files, this is mainly for copying and organizing
RUN mkdir -p /app/dist && \
    cp index.html /app/dist/ && \
    cp style.css /app/dist/ && \
    cp app.js /app/dist/ && \
    cp -r assets /app/dist/ 2>/dev/null || true

# Production stage
FROM nginx:alpine

# Install curl for health checks
RUN apk add --no-cache curl

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Copy static files from builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy static files directly (for projects without build step)
COPY index.html /usr/share/nginx/html/
COPY style.css /usr/share/nginx/html/
COPY app.js /usr/share/nginx/html/
COPY app_1.js /usr/share/nginx/html/

# Create non-root user for security
RUN addgroup -g 1001 -S nginx && \
    adduser -S -D -H -u 1001 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx

# Set proper permissions
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    chown -R nginx:nginx /etc/nginx/conf.d

# Switch to non-root user
USER nginx

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
