# Multi-stage build for smaller final image

# Stage 1: Build the Go binary
FROM golang:1.22-alpine AS builder

# Set working directory
WORKDIR /app

# Copy go mod files (if you had them, but we're using a single file)
COPY main.go .

# Build the application
# CGO_ENABLED=0 for static binary
# -ldflags="-w -s" to strip debug info (smaller binary)
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o app main.go

# Stage 2: Create minimal runtime image
FROM alpine:latest

# Add ca-certificates for HTTPS requests (if needed)
RUN apk --no-cache add ca-certificates

# Create non-root user for security
RUN addgroup -g 1000 appuser && \
    adduser -D -u 1000 -G appuser appuser

# Set working directory
WORKDIR /home/appuser

# Copy binary from builder stage
COPY --from=builder /app/app .

# Change ownership to non-root user
RUN chown -R appuser:appuser /home/appuser

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Run the application
CMD ["./app"]
