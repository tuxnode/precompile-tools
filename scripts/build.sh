#!/bin/sh
set -eu
. "$(dirname -- "$0")/common.sh"

ALL_TOOLS="busybox inotify-tools libnfs nmap redsocks socat tcpdump fscan"

usage() {
    cat <<EOF
Usage: $0 [tool ...]

Build all tools or only the selected ones. Available tools:
  $ALL_TOOLS

Environment:
  OUT_DIR    output directory (default: <repo>/dist)
  BUILD_DIR  temporary build directory (default: <repo>/.build)
EOF
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 0
fi

if [ "$#" -eq 0 ]; then
    set -- $ALL_TOOLS
fi

mkdir -p "$OUT_DIR" "$BUILD_DIR"

for tool in "$@"; do
    script="$SCRIPT_DIR/build-$tool.sh"
    [ -f "$script" ] || fail "unknown tool: $tool"
done

for tool in "$@"; do
    log "Building tool: $tool"
    OUT_DIR="$OUT_DIR" BUILD_DIR="$BUILD_DIR" sh "$SCRIPT_DIR/build-$tool.sh"
done

log "Build complete: $OUT_DIR"
