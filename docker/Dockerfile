FROM ubuntu:latest AS base
RUN apt-get update && apt-get -y install curl less vim-tiny
RUN apt-get update && apt-get -y install zip unzip build-essential
RUN apt-get update && apt-get -y install python3
RUN groupadd -g 1000 nelhage
RUN useradd -m -g 1000 -u 1000 nelhage

FROM base AS bazel
RUN curl -Lo /usr/local/bin/bazel \
    https://github.com/bazelbuild/bazelisk/releases/download/v1.26.0/bazelisk-linux-amd64 && \
    chmod +x /usr/local/bin/bazel
USER nelhage
