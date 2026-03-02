ARG GO_VERSION=1.25
ARG XX_VERSION=1.6.1

FROM --platform=$BUILDPLATFORM swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/tonistiigi/xx:1.4.0 AS xx

# Docker buildkit multi-arch build requires golang alpine
FROM --platform=$BUILDPLATFORM swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/library/golang:1.25.7-alpine AS builder

# Copy the build utilities.
COPY --from=xx / /

ARG TARGETPLATFORM

# Configure workspace
WORKDIR /workspace

# Copy api submodule
COPY api/ api/

# Copy modules manifests
COPY go.mod go.mod
COPY go.sum go.sum

# Cache modules
RUN go env -w GOPROXY=https://goproxy.cn,direct && go mod download

# Copy source code
COPY main.go main.go
COPY internal/ internal/

ARG TARGETPLATFORM
ARG TARGETARCH

# build without specifing the arch
ENV CGO_ENABLED=0
RUN xx-go build -trimpath -a -o source-controller main.go

FROM swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/library/alpine:3.22.2

ARG TARGETPLATFORM
RUN apk --no-cache add ca-certificates \
  && update-ca-certificates

COPY --from=builder /workspace/source-controller /usr/local/bin/

USER 65534:65534
ENTRYPOINT [ "source-controller" ]
