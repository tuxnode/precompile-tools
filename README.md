# Precompile Tools — Statically Compiled Network Security Toolkit

English | [简体中文](README.zh-CN.md)

This repository provides a set of network security tools **statically compiled** against musl libc, intended for **AWD Plus (AWDP)** and **penetration challenge** scenarios. Every binary is a standalone executable that does not depend on system dynamic libraries, so it can be uploaded directly to a target machine.

## About the Repository

This repository **does not store prebuilt binaries**; it only contains build scripts, the Alpine build environment, and upstream source submodules. Binaries are compiled automatically by GitHub Actions after pushing a `v*` tag and uploaded to GitHub Releases.

Sources are pinned under `third_party/` via `git submodule`. Initialize submodules when cloning:

```bash
git clone --recurse-submodules https://github.com/tuxnode/precompile-tools.git
# Already cloned:
git submodule update --init --recursive
```

## Directory Structure

```
precompile-tools/
├── README.md                   # English README (default)
├── README.zh-CN.md             # Chinese README
├── Dockerfile                  # Alpine static build environment
├── docker-compose.yml          # Local build entry point
├── docs/                       # Usage guide (English default / Chinese)
├── scripts/                    # Per-tool build/verify/package scripts
├── third_party/                # Upstream source submodules (pinned commits)
│   ├── busybox/
│   ├── inotify-tools/
│   ├── libnfs/
│   ├── nmap/
│   ├── redsocks/
│   ├── socat/
│   ├── tcpdump/
│   ├── libpcap/
│   └── fscan/
└── .github/workflows/
    └── release.yml             # Auto-build and publish releases on tags
```

Build output directory (not committed to Git):

```
dist/
├── busybox
├── inotify-tools/
│   ├── inotifywait
│   └── inotifywatch
├── libnfs/
│   ├── nfs-cat
│   ├── nfs-cp
│   ├── nfs-ls
│   └── nfs-stat
└── net/
    ├── fscan
    ├── nmap
    ├── nmap-data/            # Data files required by nmap at runtime
    ├── redsocks
    ├── socat
    └── tcpdump
```

## Download Prebuilt Binaries

Go to [GitHub Releases](https://github.com/tuxnode/precompile-tools/releases) and download:

```text
precompile-tools-<tag>-x86_64.tar.gz
SHA256SUMS
```

Extract the archive and use it directly; the directory structure matches `dist/` above.

## Build Environment

The `Dockerfile` is based on `alpine:3.21` and includes the toolchain and libraries needed for static compilation:

| Component | Purpose |
|-----------|---------|
| `build-base` / `linux-headers` | GCC, make, musl headers |
| `cmake` / `autoconf` / `automake` / `libtool` | Build automation tools |
| `openssl-libs-static` | Static TLS/SSL linking |
| `readline-static` / `ncurses-static` | Static terminal interaction linking |
| `zlib-static` / `libevent-static` | Static compression/event linking |
| `go` | Build fscan |

### Pinned Versions

| Tool | Version | Submodule |
|------|---------|-----------|
| busybox | 1.36.1 | `third_party/busybox` |
| inotify-tools | 4.23.9.0 | `third_party/inotify-tools` |
| libnfs | 6.0.2 | `third_party/libnfs` |
| nmap | 7.992 | `third_party/nmap` |
| redsocks | 0.5-11-g19b822e | `third_party/redsocks` |
| socat | 1.8.0.1 | `third_party/socat` |
| tcpdump / libpcap | 4.99.4 / 1.10.4 | `third_party/tcpdump`, `third_party/libpcap` |
| fscan | 2.1.3 | `third_party/fscan` |

### Local Build

```bash
# Build the build environment
docker build -t precompile-tools-build .

# Build everything into dist/
docker run --rm \
    -v "$PWD:/workspace" \
    -v "$PWD/dist:/out" \
    -e OUT_DIR=/out \
    -w /workspace \
    precompile-tools-build ./scripts/build.sh

# Build a single tool
docker run --rm \
    -v "$PWD:/workspace" \
    -v "$PWD/dist:/out" \
    -e OUT_DIR=/out \
    -w /workspace \
    precompile-tools-build ./scripts/build.sh nmap

# Verify static linking and run smoke tests
docker run --rm \
    -v "$PWD:/workspace" \
    -v "$PWD/dist:/out" \
    -e OUT_DIR=/out \
    -w /workspace \
    precompile-tools-build ./scripts/verify.sh
```

You can also use Docker Compose:

```bash
docker compose run --rm builder ./scripts/build.sh
```

All binaries are **x86-64 ELF, static-pie/static linked**, including `fscan` (built statically with `CGO_ENABLED=0`).

## Usage Documentation

Detailed tool references, CTF/AWDP scenarios, reverse shell guide, and complete workflows:

- [English (default)](docs/USAGE.md)
- [简体中文](docs/USAGE.zh-CN.md)
