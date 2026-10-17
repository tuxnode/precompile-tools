#!/bin/sh
set -eu
. "$(dirname -- "$0")/common.sh"

stage_source inotify-tools
cd "$BUILD_DIR/inotify-tools"

log "Bootstrapping inotify-tools"
./autogen.sh

log "Configuring inotify-tools"
CFLAGS="$CFLAGS" LDFLAGS="-static" \
    ./configure --disable-shared --enable-static --enable-static-binary

log "Building inotify-tools"
make -j"$JOBS"

install_bin src/inotifywait "$OUT_DIR/inotify-tools/inotifywait"
install_bin src/inotifywatch "$OUT_DIR/inotify-tools/inotifywatch"
