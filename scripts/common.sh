#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
THIRD_PARTY_DIR="$ROOT_DIR/third_party"
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/.build}"
OUT_DIR="${OUT_DIR:-$ROOT_DIR/dist}"

export ROOT_DIR THIRD_PARTY_DIR BUILD_DIR OUT_DIR
export CFLAGS="${CFLAGS:--O2}"
export CXXFLAGS="${CXXFLAGS:--O2}"
export MAKEFLAGS="${MAKEFLAGS:-}"

if command -v nproc >/dev/null 2>&1; then
    JOBS=$(nproc)
else
    JOBS=2
fi
export JOBS

log() {
    printf '\n==> %s\n' "$*"
}

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

stage_source() {
    name="$1"
    src="$THIRD_PARTY_DIR/$name"
    dst="$BUILD_DIR/$name"

    [ -d "$src" ] || fail "missing source for $name at $src (run: git submodule update --init --recursive)"
    [ -e "$src/.git" ] || fail "third_party/$name is not a git submodule (run: git submodule update --init --recursive)"

    log "Staging $name source"
    rm -rf "$dst"
    mkdir -p "$dst"
    git -c safe.directory='*' -C "$src" archive --format=tar HEAD | tar -x -C "$dst"
}

install_bin() {
    src="$1"
    dest="$2"
    [ -f "$src" ] || fail "expected binary not found: $src"
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    strip "$dest" 2>/dev/null || true
}

build_version() {
    name="$1"
    git -C "$THIRD_PARTY_DIR/$name" describe --tags --always 2>/dev/null || true
}
