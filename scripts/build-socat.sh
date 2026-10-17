#!/bin/sh
set -eu
. "$(dirname -- "$0")/common.sh"

stage_source socat
cd "$BUILD_DIR/socat"

log "Bootstrapping socat"
autoconf

log "Configuring socat"
CFLAGS="$CFLAGS" LDFLAGS="-static" \
    ./configure --disable-shared

log "Building socat"
make -j"$JOBS"

install_bin socat "$OUT_DIR/net/socat"
