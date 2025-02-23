############################
# Build
############################
# golang:1.16.2-buster
FROM golang@sha256:a23a7e49a820f9ae69df0fedf64f037cb15b004997effa93ec885e5032277bc1 AS build

# Ensure ca-certficates are up to date
RUN update-ca-certificates

# Set the current Working Directory inside the container
RUN mkdir /asset-registry
WORKDIR /asset-registry

# Use Go Modules
COPY go.mod .
COPY go.sum .

ENV GO111MODULE=on
RUN go mod download
RUN go mod verify

# Copy everything from the current directory to the PWD(Present Working Directory) inside the container
COPY . .

# Build the binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
      -ldflags='-w -s -extldflags "-static"' -a \
       -o /go/bin/asset-registry

############################
# Image
############################
# using static nonroot image
# user:group is nonroot:nonroot, uid:gid = 65532:65532
FROM gcr.io/distroless/static@sha256:23aa732bba4c8618c0d97c26a72a32997363d591807b0d4c31b0bbc8a774bddf

EXPOSE 80/tcp

# Copy the Pre-built binary file from the previous stage
COPY --from=build /go/bin/asset-registry /run/asset-registry

ENTRYPOINT ["/run/asset-registry"]
