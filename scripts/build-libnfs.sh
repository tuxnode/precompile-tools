#!/bin/sh
set -eu
. "$(dirname -- "$0")/common.sh"

stage_source libnfs
cd "$BUILD_DIR/libnfs"

log "Bootstrapping libnfs"
./bootstrap

log "Configuring libnfs"
CFLAGS="$CFLAGS" LDFLAGS="-static" \
    ./configure \
        --disable-shared \
        --enable-static \
        --enable-utils \
        --without-libkrb5

log "Building libnfs"
make -j"$JOBS"

install_bin utils/nfs-cat "$OUT_DIR/libnfs/nfs-cat"
install_bin utils/nfs-cp "$OUT_DIR/libnfs/nfs-cp"
install_bin utils/nfs-ls "$OUT_DIR/libnfs/nfs-ls"
install_bin utils/nfs-stat "$OUT_DIR/libnfs/nfs-stat"
