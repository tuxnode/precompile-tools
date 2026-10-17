#!/bin/sh
set -eu
. "$(dirname -- "$0")/common.sh"

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
    VERSION=$(git -C "$ROOT_DIR" describe --tags --always 2>/dev/null || date +%Y%m%d)
fi

NAME="precompile-tools-${VERSION}-x86_64"
STAGE_ROOT="$BUILD_DIR/package"
STAGE="$STAGE_ROOT/$NAME"

log "Packaging $NAME"
rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -a "$OUT_DIR/." "$STAGE/"
cp "$ROOT_DIR/README.md" "$STAGE/"

mkdir -p "$OUT_DIR"
tar -C "$STAGE_ROOT" -czf "$OUT_DIR/$NAME.tar.gz" "$NAME"

cd "$OUT_DIR"
sha256sum "$NAME.tar.gz" >SHA256SUMS

log "Created $OUT_DIR/$NAME.tar.gz"
cat "$OUT_DIR/SHA256SUMS"
