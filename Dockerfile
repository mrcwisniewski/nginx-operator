# Build the manager binary
FROM golang:1.20.4 as builder
ARG TARGETOS
ARG TARGETARCH

WORKDIR /workspace
# Copy the Go Modules manifests
RUN CGO_ENABLED=0 go install -ldflags "-s -w -extldflags '-static'" github.com/go-delve/delve/cmd/dlv@latest
# Custom cache invalidation
ARG CACHEBUST=1
RUN echo $(which dlv)
COPY go.mod go.mod
COPY go.sum go.sum
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN go mod download

# Copy the go source
COPY main.go main.go
COPY api/ api/
COPY controllers/ controllers/
COPY assets/ assets/

# Build
# the GOARCH has not a default value to allow the binary be built according to the host where the command
# was called. For example, if we call make docker-build in a local env which has the Apple Silicon M1 SO
# the docker BUILDPLATFORM arg will be linux/arm64 when for Apple x86 it will be linux/amd64. Therefore,
# by leaving it empty we can ensure that the container and binary shipped on it will have the same platform.
RUN CGO_ENABLED=0 GOOS=${TARGETOS:-linux} GOARCH=${TARGETARCH} go build -gcflags "all=-N -l" -a -o manager main.go

# Use distroless as minimal base image to package the manager binary
# Refer to https://github.com/GoogleContainerTools/distroless for more details
#FROM gcr.io/distroless/static:nonroot
FROM debian:buster
WORKDIR /
ENV XDG_CONFIG_HOME /tmp
COPY --from=builder /workspace/manager .
COPY --from=builder /go/bin/dlv .
EXPOSE 40000
USER 65532:65532

ENTRYPOINT [ "/dlv" , "--listen=:40000", "--headless=true", "--api-version=2", "--accept-multiclient", "exec", "/manager", "--"]