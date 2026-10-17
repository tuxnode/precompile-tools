#!/bin/sh
set -eu
. "$(dirname -- "$0")/common.sh"

stage_source busybox
cd "$BUILD_DIR/busybox"

log "Configuring busybox"
make defconfig

sed -i \
    -e 's/^# CONFIG_STATIC is not set/CONFIG_STATIC=y/' \
    -e 's/^# CONFIG_PIE is not set/CONFIG_PIE=y/' \
    .config
grep -q '^CONFIG_STATIC=y' .config || echo 'CONFIG_STATIC=y' >> .config
grep -q '^CONFIG_PIE=y' .config || echo 'CONFIG_PIE=y' >> .config

log "Building busybox"
make -j"$JOBS"

install_bin busybox "$OUT_DIR/busybox"
