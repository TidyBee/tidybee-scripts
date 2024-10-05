# Use the Golang base image to build the grpcwebproxy
FROM golang:1.20-alpine AS builder

# Install necessary tools
RUN apk add --no-cache git

# Set the working directory
WORKDIR /app

# Clone the grpcwebproxy repository
RUN git clone https://github.com/improbable-eng/grpc-web.git

# Build the grpcwebproxy binary
WORKDIR /app/grpc-web/go/grpcwebproxy
RUN go build -o grpcwebproxy .

# Final stage - minimal image
FROM alpine:latest

# Copy the built binary from the builder stage
COPY --from=builder /app/grpc-web/go/grpcwebproxy/grpcwebproxy /usr/local/bin/grpcwebproxy

# Command to run the grpcwebproxy
ENTRYPOINT ["/usr/local/bin/grpcwebproxy"]
