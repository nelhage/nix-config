FROM golang:1.15-buster
RUN git clone https://github.com/nelhage/taktician /src/
WORKDIR /src
RUN go build -o taktician ./cmd/taktician

FROM debian:stretch
RUN mkdir /opt/bin
COPY --from=0 /src/taktician /opt/bin/

ENTRYPOINT ["/opt/bin/taktician"]
