ARG livegrep_image_version

FROM golang:1.22-bookworm
ADD fetch-version/ /src/
WORKDIR /src
ENV CGO_ENABLED 0
RUN go build -o fetch-linux-version main.go

FROM ghcr.io/livegrep/livegrep/indexer:${livegrep_image_version}
COPY --from=0 /src/fetch-linux-version /usr/local/bin/
ADD rebuild-index /usr/local/bin/
