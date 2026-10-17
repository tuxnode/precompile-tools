#!/bin/sh
set -eu
. "$(dirname -- "$0")/common.sh"

PCAP_PREFIX="$BUILD_DIR/libpcap-install"

stage_source libpcap
cd "$BUILD_DIR/libpcap"

log "Configuring libpcap"
CFLAGS="$CFLAGS" LDFLAGS="-static" \
    ./configure \
        --prefix="$PCAP_PREFIX" \
        --disable-shared \
        --enable-static \
        --disable-dbus \
        --disable-bluetooth \
        --without-libnl

log "Building libpcap"
make -j"$JOBS"
make install

stage_source tcpdump
cd "$BUILD_DIR/tcpdump"

log "Configuring tcpdump"
PATH="$PCAP_PREFIX/bin:$PATH" \
CFLAGS="$CFLAGS -I$PCAP_PREFIX/include" \
LDFLAGS="-static -L$PCAP_PREFIX/lib" \
    ./configure --disable-shared

log "Building tcpdump"
make -j"$JOBS"

install_bin tcpdump "$OUT_DIR/net/tcpdump"
