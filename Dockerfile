FROM alpine:3.22

LABEL maintainer="precompile-tools"
LABEL description="Alpine-based environment for statically compiling precompile-tools"

RUN apk add --no-cache \
    build-base \
    linux-headers \
    cmake \
    autoconf \
    automake \
    libtool \
    pkgconf \
    flex \
    bison \
    git \
    curl \
    wget \
    file \
    tar \
    bzip2 \
    xz \
    perl \
    go \
    openssl-dev openssl-libs-static \
    readline-dev readline-static \
    ncurses-dev ncurses-static \
    zlib-dev zlib-static \
    libevent-dev libevent-static \
    pcre2-dev pcre2-static

WORKDIR /workspace
CMD ["/bin/sh"]
