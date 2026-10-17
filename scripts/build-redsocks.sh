#!/bin/sh
set -eu
. "$(dirname -- "$0")/common.sh"

stage_source redsocks
cd "$BUILD_DIR/redsocks"

log "Building redsocks"
make -j"$JOBS" \
    CFLAGS="$CFLAGS" \
    LDFLAGS="-static" \
    VERSION="0.5-11-g19b822e"

install_bin redsocks "$OUT_DIR/net/redsocks"
