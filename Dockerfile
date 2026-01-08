# Build stage
FROM golang:1.25-alpine AS builder

ARG TARGETOS
ARG TARGETARCH
ARG VERSION=dev

WORKDIR /build

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source
COPY . .

# Build static binary (pure Go, no CGO needed for modernc.org/sqlite)
# The binary embeds the generated CSS via //go:embed
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build \
    -ldflags="-w -s -extldflags '-static' -X main.version=${VERSION}" \
    -o webtail \
    .

# Runtime stage - distroless for minimal image
FROM gcr.io/distroless/static-debian12:nonroot

# Copy binary (migrations are embedded in the binary)
COPY --from=builder /build/webtail /usr/local/bin/webtail

# Use non-root user (distroless nonroot UID: 65532)
USER 65532:65532

# Data directory (mount volume here for persistence)
VOLUME ["/data"]

# Expose HTTPS port
EXPOSE 443

# Entry point
ENTRYPOINT ["/usr/local/bin/webtail"]
