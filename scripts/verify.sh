#!/bin/sh
set -eu
. "$(dirname -- "$0")/common.sh"

BINARIES="
busybox
inotify-tools/inotifywait
inotify-tools/inotifywatch
libnfs/nfs-cat
libnfs/nfs-cp
libnfs/nfs-ls
libnfs/nfs-stat
net/fscan
net/nmap
net/redsocks
net/socat
net/tcpdump
"

check_static() {
    rel="$1"
    path="$OUT_DIR/$rel"
    [ -f "$path" ] || fail "missing binary: $path"

    desc=$(file -b "$path")
    case "$desc" in
        *"statically linked"*|*"static-pie linked"*) ;;
        *) fail "not statically linked: $rel ($desc)" ;;
    esac
    printf '  [static] %s\n' "$rel"
}

check_output() {
    name="$1"
    pattern="$2"
    shift 2

    output=$("$@" 2>&1 || true)
    printf '%s\n' "$output" | grep -qi "$pattern" ||
        fail "smoke test failed for $name"
    printf '  [smoke]  %s\n' "$name"
}

log "Verifying binaries"
for rel in $BINARIES; do
    check_static "$rel"
done

log "Running smoke tests"
check_output busybox 'BusyBox' "$OUT_DIR/busybox" --help
check_output inotifywait 'inotifywait' "$OUT_DIR/inotify-tools/inotifywait" --help
check_output nfs-ls 'usage' "$OUT_DIR/libnfs/nfs-ls" --help
check_output nmap 'Nmap version' "$OUT_DIR/net/nmap" --version
check_output fscan 'fscan' "$OUT_DIR/net/fscan" -h
check_output redsocks 'redsocks' "$OUT_DIR/net/redsocks" -v
check_output socat 'socat version' "$OUT_DIR/net/socat" -V
check_output tcpdump 'tcpdump version' "$OUT_DIR/net/tcpdump" --version

log "Verification passed"
