#!/bin/sh
set -eu
. "$(dirname -- "$0")/common.sh"

stage_source nmap
cd "$BUILD_DIR/nmap"

log "Configuring nmap"
CFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS" LDFLAGS="-static" \
    ./configure \
        --without-zenmap \
        --without-ncat \
        --without-nping \
        --without-ndiff \
        --without-libssh2 \
        --with-openssl=/usr \
        --with-libpcap=included \
        --with-libpcre=included \
        --with-libz=included \
        --with-liblua=included \
        --with-libdnet=included

log "Building nmap"
make -j"$JOBS" nmap

install_bin nmap "$OUT_DIR/net/nmap"

log "Copying nmap runtime data"
mkdir -p "$OUT_DIR/net/nmap-data"
for item in nmap-services nmap-protocols nmap-rpc nmap-mac-prefixes \
    nmap-service-probes nmap-os-db nmap-payloads nse_main.lua scripts; do
    if [ -e "$item" ]; then
        cp -a "$item" "$OUT_DIR/net/nmap-data/"
    fi
done
