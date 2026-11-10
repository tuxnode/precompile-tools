# Precompile Tools —— 静态编译网络安全工具集

[English](README.md) | 简体中文

本仓库提供一套通过 musl libc **静态编译**的网络安全工具，适用于 **AWD Plus (AWDP)** 和**渗透挑战赛**场景。所有二进制文件均为独立可执行文件，无需依赖系统动态库，可直接上传至目标靶机使用。

## 仓库说明

本仓库**不保存预编译二进制**，只保存构建脚本、Alpine 编译环境和上游源码子模块。二进制在推送 `v*` tag 后由 GitHub Actions 自动编译，并上传到 GitHub Releases。

源码通过 `git submodule` 固定在 `third_party/` 下，克隆时需要初始化子模块：

```bash
git clone --recurse-submodules https://github.com/tuxnode/precompile-tools.git
# 已经克隆过：
git submodule update --init --recursive
```

## 目录结构

```
precompile-tools/
├── README.md                   # 英文 README（默认）
├── README.zh-CN.md             # 中文 README
├── Dockerfile                  # Alpine 静态编译环境
├── docker-compose.yml          # 本地编译入口
├── docs/                       # 使用文档（英文默认 / 简体中文）
├── scripts/                    # 各工具构建/校验/打包脚本
├── third_party/                # 上游源码子模块（固定 commit）
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
    └── release.yml             # tag 自动编译并发布 Release
```

编译产物目录（不提交到 Git）：

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
    ├── nmap-data/            # nmap 运行所需数据文件
    ├── redsocks
    ├── socat
    └── tcpdump
```

## 下载预编译二进制

前往 [GitHub Releases](https://github.com/tuxnode/precompile-tools/releases) 下载：

```text
precompile-tools-<tag>-x86_64.tar.gz
SHA256SUMS
```

解压后即可使用，目录结构与上方的 `dist/` 一致。

## 构建环境

`Dockerfile` 基于 `alpine:3.21`，包含静态编译所需的工具链和库：

| 组件 | 用途 |
|------|------|
| `build-base` / `linux-headers` | GCC、make、musl 头文件 |
| `cmake` / `autoconf` / `automake` / `libtool` | 自动构建工具 |
| `openssl-libs-static` | TLS/SSL 静态链接 |
| `readline-static` / `ncurses-static` | 终端交互静态链接 |
| `zlib-static` / `libevent-static` | 压缩、事件静态链接 |
| `go` | 编译 fscan |

### 版本锁定

| 工具 | 版本 | 子模块 |
|------|------|--------|
| busybox | 1.36.1 | `third_party/busybox` |
| inotify-tools | 4.23.9.0 | `third_party/inotify-tools` |
| libnfs | 6.0.2 | `third_party/libnfs` |
| nmap | 7.992 | `third_party/nmap` |
| redsocks | 0.5-11-g19b822e | `third_party/redsocks` |
| socat | 1.8.0.1 | `third_party/socat` |
| tcpdump / libpcap | 4.99.4 / 1.10.4 | `third_party/tcpdump`、`third_party/libpcap` |
| fscan | 2.1.3 | `third_party/fscan` |

### 本地编译

```bash
# 构建编译环境
docker build -t precompile-tools-build .

# 全量编译到 dist/
docker run --rm \
    -v "$PWD:/workspace" \
    -v "$PWD/dist:/out" \
    -e OUT_DIR=/out \
    -w /workspace \
    precompile-tools-build ./scripts/build.sh

# 只编译单个工具
docker run --rm \
    -v "$PWD:/workspace" \
    -v "$PWD/dist:/out" \
    -e OUT_DIR=/out \
    -w /workspace \
    precompile-tools-build ./scripts/build.sh nmap

# 校验静态链接并执行冒烟测试
docker run --rm \
    -v "$PWD:/workspace" \
    -v "$PWD/dist:/out" \
    -e OUT_DIR=/out \
    -w /workspace \
    precompile-tools-build ./scripts/verify.sh
```

也可以使用 Docker Compose：

```bash
docker compose run --rm builder ./scripts/build.sh
```

所有二进制文件格式：**x86-64 ELF, static-pie/static linked**，包括 `fscan`（使用 `CGO_ENABLED=0` 静态编译）。

## 使用文档

包含各工具详解、CTF/AWDP 实战场景、反弹 Shell 专题与综合流程：

- [English（默认）](docs/USAGE.md)
- [简体中文](docs/USAGE.zh-CN.md)
