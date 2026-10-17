#!/bin/sh
set -eu
. "$(dirname -- "$0")/common.sh"

stage_source fscan
cd "$BUILD_DIR/fscan"

log "Building fscan"
CGO_ENABLED=0 GOTOOLCHAIN=local \
    go build -trimpath -buildvcs=false \
    -ldflags "-s -w" \
    -o "$OUT_DIR/net/fscan" .

strip "$OUT_DIR/net/fscan" 2>/dev/null || true
