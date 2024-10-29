FROM golang:1.22-bookworm
RUN git clone https://github.com/nelhage/taktician /src/
WORKDIR /src
RUN go build -o taktician ./cmd/taktician

FROM debian:bookworm
RUN mkdir /opt/bin
COPY --from=0 /src/taktician /opt/bin/

ENTRYPOINT ["/opt/bin/taktician"]
