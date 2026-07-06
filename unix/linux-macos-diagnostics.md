# Kernel & System Diagnostics — CLI Reference

A practical reference for system engineers, SREs, and power users. Covers process inspection, network diagnostics, memory and disk analysis, eBPF tracing, and crash analysis across **Linux** and **macOS**.

---

## Table of Contents

1. [Quick Reference — Top 10 Commands](#quick-reference)
2. [Tool Compatibility Matrix](#tool-compatibility-matrix)
3. [Categories](#categories)
   - [System Call Tracing](#system-call-tracing)
   - [Process Inspection](#process-inspection)
   - [File Activity](#file-activity)
   - [Network Diagnostics](#network-diagnostics)
   - [Kernel Logs](#kernel-logs)
   - [Performance Profiling](#performance-profiling)
   - [eBPF / Dynamic Tracing](#ebpf--dynamic-tracing)
   - [Memory Diagnostics](#memory-diagnostics)
   - [Disk / I/O Diagnostics](#disk--io-diagnostics)
   - [Hardware Inspection](#hardware-inspection)
4. [Linux → macOS Equivalents](#linux--macos-equivalents)
5. [Power User Stacks](#power-user-stacks)
6. [Recommended Learning Order](#recommended-learning-order)

---

## Quick Reference

The essential 10 commands for each platform — start here.

### Linux

| Command     | Purpose                  |
|-------------|--------------------------|
| `strace`    | Syscall debugging        |
| `lsof`      | Open files and sockets   |
| `ss`        | Network connections      |
| `tcpdump`   | Packet capture           |
| `perf`      | CPU profiling            |
| `bpftrace`  | Dynamic tracing          |
| `opensnoop` | File activity            |
| `execsnoop` | Process execution        |
| `vmstat`    | Memory statistics        |
| `iostat`    | Disk statistics          |

### macOS

| Command       | Purpose                  |
|---------------|--------------------------|
| `dtruss`      | Syscall tracing          |
| `lsof`        | Open files and sockets   |
| `netstat`     | Network connections      |
| `tcpdump`     | Packet capture           |
| `Instruments` | Performance profiling    |
| `bpftrace`    | Dynamic tracing          |
| `opensnoop`   | File activity            |
| `execsnoop`   | Process execution        |
| `vm_stat`     | Memory statistics        |
| `iostat`      | Disk statistics          |

---

## Tool Compatibility Matrix

Full list of tools and their availability across platforms.

| Tool              | Linux                | macOS        |
|-------------------|----------------------|--------------|
| `strace`          | ✅                   | ❌            |
| `ltrace`          | ✅                   | ❌            |
| `dtruss`          | ❌                   | ✅            |
| `dtrace`          | Limited / Deprecated | ✅            |
| `ps`              | ✅                   | ✅            |
| `top`             | ✅                   | ✅            |
| `htop`            | ✅                   | ✅ (brew)     |
| `pidstat`         | ✅                   | ❌            |
| `lsof`            | ✅                   | ✅            |
| `fuser`           | ✅                   | ❌            |
| `ss`              | ✅                   | ❌            |
| `netstat`         | ✅                   | ✅            |
| `tcpdump`         | ✅                   | ✅            |
| `iftop`           | ✅                   | ✅ (brew)     |
| `nethogs`         | ✅                   | ❌            |
| `dmesg`           | ✅                   | Limited      |
| `journalctl`      | ✅ (systemd)         | ❌            |
| `perf`            | ✅                   | ❌            |
| `ftrace`          | ✅                   | ❌            |
| `trace-cmd`       | ✅                   | ❌            |
| `kernelshark`     | ✅                   | ❌            |
| `bpftrace`        | ✅                   | ✅            |
| `BCC Tools`       | ✅                   | Partial      |
| `vmstat`          | ✅                   | ✅            |
| `slabtop`         | ✅                   | ❌            |
| `smem`            | ✅                   | ❌            |
| `iostat`          | ✅                   | ✅            |
| `iotop`           | ✅                   | ❌            |
| `blktrace`        | ✅                   | ❌            |
| `kdump`           | ✅                   | ❌            |
| `crash`           | ✅                   | ❌            |
| `gdb`             | ✅                   | Partial      |
| `hwinfo`          | ✅                   | ❌            |
| `lspci`           | ✅                   | ❌            |
| `lsusb`           | ✅                   | ❌            |
| `sysctl`          | ✅                   | ✅            |
| `sar`             | ✅                   | ❌            |
| `mpstat`          | ✅                   | ❌            |
| `free`            | ✅                   | ❌            |
| `uname`           | ✅                   | ✅            |
| `watch`           | ✅                   | ❌            |
| `pmap`            | ✅                   | ❌            |
| `pstree`          | ✅                   | ❌            |
| `procfs (/proc)`  | ✅                   | ❌            |
| `Activity Monitor`| ❌                   | ✅            |
| `Instruments`     | ❌                   | ✅            |
| `sample`          | ❌                   | ✅            |
| `spindump`        | ❌                   | ✅            |
| `fs_usage`        | ❌                   | ✅            |
| `opensnoop`       | BCC/eBPF             | ✅            |
| `execsnoop`       | BCC/eBPF             | ✅            |
| `iosnoop`         | BCC/eBPF             | ✅            |
| `nettop`          | ❌                   | ✅            |

---

## Categories

### System Call Tracing

Trace system calls made by a process to understand its runtime behavior.

| Tool      | Linux   | macOS |
|-----------|---------|-------|
| `strace`  | ✅      | ❌    |
| `ltrace`  | ✅      | ❌    |
| `dtruss`  | ❌      | ✅    |
| `dtrace`  | Limited | ✅    |

---

### Process Inspection

Monitor running processes, CPU usage, and process trees.

| Tool       | Linux | macOS |
|------------|-------|-------|
| `ps`       | ✅    | ✅    |
| `top`      | ✅    | ✅    |
| `htop`     | ✅    | ✅    |
| `pidstat`  | ✅    | ❌    |
| `pstree`   | ✅    | ❌    |
| `sample`   | ❌    | ✅    |

---

### File Activity

Track which files, sockets, and devices are open or being accessed.

| Tool        | Linux | macOS |
|-------------|-------|-------|
| `lsof`      | ✅    | ✅    |
| `fuser`     | ✅    | ❌    |
| `opensnoop` | ✅    | ✅    |
| `fs_usage`  | ❌    | ✅    |

---

### Network Diagnostics

Inspect connections, capture packets, and monitor per-process bandwidth.

| Tool       | Linux | macOS |
|------------|-------|-------|
| `ss`       | ✅    | ❌    |
| `netstat`  | ✅    | ✅    |
| `tcpdump`  | ✅    | ✅    |
| `iftop`    | ✅    | ✅    |
| `nethogs`  | ✅    | ❌    |
| `nettop`   | ❌    | ✅    |

---

### Kernel Logs

Access kernel and system log output for event auditing and debugging.

| Tool         | Linux | macOS   |
|--------------|-------|---------|
| `dmesg`      | ✅    | Limited |
| `journalctl` | ✅    | ❌      |
| `log show`   | ❌    | ✅      |

---

### Performance Profiling

Find CPU hot spots, cache misses, scheduler delays, and performance bottlenecks.

| Tool          | Linux | macOS |
|---------------|-------|-------|
| `perf`        | ✅    | ❌    |
| `ftrace`      | ✅    | ❌    |
| `trace-cmd`   | ✅    | ❌    |
| `kernelshark` | ✅    | ❌    |
| `Instruments` | ❌    | ✅    |
| `spindump`    | ❌    | ✅    |

---

### eBPF / Dynamic Tracing

Runtime tracing of kernel and userspace events without rebooting or recompiling.

| Tool       | Linux   | macOS   |
|------------|---------|---------|
| `bpftrace` | ✅      | ✅      |
| `BCC`      | ✅      | Partial |
| `dtrace`   | Limited | ✅      |

---

### Memory Diagnostics

Analyze memory pressure, paging, slab caches, and per-process memory maps.

| Tool      | Linux | macOS |
|-----------|-------|-------|
| `vmstat`  | ✅    | ✅    |
| `slabtop` | ✅    | ❌    |
| `smem`    | ✅    | ❌    |
| `pmap`    | ✅    | ❌    |
| `vmmap`   | ❌    | ✅    |

---

### Disk / I/O Diagnostics

Monitor disk throughput, utilization, and I/O latency.

| Tool       | Linux | macOS |
|------------|-------|-------|
| `iostat`   | ✅    | ✅    |
| `iotop`    | ✅    | ❌    |
| `blktrace` | ✅    | ❌    |
| `iosnoop`  | ✅    | ✅    |

---

### Hardware Inspection

Enumerate and inspect hardware devices including PCI, USB, and system profiles.

| Tool              | Linux | macOS |
|-------------------|-------|-------|
| `hwinfo`          | ✅    | ❌    |
| `lspci`           | ✅    | ❌    |
| `lsusb`           | ✅    | ❌    |
| `system_profiler` | ❌    | ✅    |

---

## Linux → macOS Equivalents

Migrating from Linux? Use this table to find the closest macOS alternative.

| Linux Tool    | macOS Alternative               | Notes                                          |
|---------------|---------------------------------|------------------------------------------------|
| `strace`      | `dtruss`                        | DTrace-based syscall tracer                    |
| `ltrace`      | `dtrace`                        | Trace library and function calls               |
| `ss`          | `netstat`                       | macOS lacks a direct `ss` equivalent           |
| `perf`        | `Instruments`                   | Apple's primary performance profiler           |
| `perf top`    | `sample`                        | Snapshot of CPU-consuming stacks               |
| `perf record` | `Instruments`                   | Full profiling session with call graphs        |
| `ftrace`      | `dtrace`                        | Closest kernel tracing framework               |
| `trace-cmd`   | `Instruments`                   | Partial replacement                            |
| `kernelshark` | `Instruments`                   | GUI timeline and scheduler analysis            |
| `journalctl`  | `log show`                      | Unified Logging system                         |
| `slabtop`     | `vmmap`                         | Memory analysis (no slab cache equivalent)     |
| `smem`        | `vmmap`                         | Process memory accounting                      |
| `pmap`        | `vmmap`                         | Detailed process memory maps                   |
| `iotop`       | `fs_usage`                      | Filesystem and I/O activity                    |
| `blktrace`    | `iosnoop`                       | Disk I/O tracing                               |
| `nethogs`     | `nettop`                        | Network usage by process                       |
| `pidstat`     | `top`                           | Limited process statistics                     |
| `hwinfo`      | `system_profiler`               | Hardware inventory and details                 |
| `lspci`       | `system_profiler`               | PCI devices shown indirectly                   |
| `lsusb`       | `system_profiler SPUSBDataType` | USB device enumeration                         |
| `crash`       | `spindump`                      | Hang/crash diagnostics                         |
| `/proc`       | `sysctl`, `vmmap`, `lsof`, `ps` | macOS has no procfs                            |

---

## Power User Stacks

The full toolkit for deep system investigation on each platform.

### Linux Power User Stack

1. `strace` — syscall tracing
2. `lsof` — open files and sockets
3. `ss` — network connections
4. `tcpdump` — packet capture
5. `perf` — CPU profiling
6. `ftrace` — kernel function tracing
7. `bpftrace` — eBPF dynamic tracing
8. `opensnoop` — file open monitoring
9. `execsnoop` — process execution monitoring
10. `iostat` — disk throughput
11. `vmstat` — memory and paging
12. `slabtop` — kernel slab cache
13. `blktrace` — block-level I/O analysis

### macOS Power User Stack

1. `dtruss` — syscall tracing
2. `dtrace` — dynamic tracing framework
3. `fs_usage` — filesystem activity
4. `opensnoop` — file open monitoring
5. `execsnoop` — process execution monitoring
6. `nettop` — per-process network usage
7. `tcpdump` — packet capture
8. `vm_stat` — virtual memory statistics
9. `vmmap` — process memory maps
10. `sample` — CPU stack snapshots
11. `spindump` — hang and crash analysis
12. `Instruments` — full performance profiler
13. `Activity Monitor` — GUI system overview

---

## Recommended Learning Order

Build skills progressively — start with observation tools, then move into deep tracing.

### Linux

| Step | Tool         | Why                                      |
|------|--------------|------------------------------------------|
| 1    | `ps`         | Understand running processes             |
| 2    | `top` / `htop` | Real-time CPU and memory overview      |
| 3    | `lsof`       | See open files and network sockets       |
| 4    | `ss`         | Inspect TCP/UDP connections              |
| 5    | `tcpdump`    | Capture live network traffic             |
| 6    | `strace`     | Trace syscalls for a specific process    |
| 7    | `vmstat`     | Understand memory pressure and paging    |
| 8    | `iostat`     | Monitor disk throughput                  |
| 9    | `perf`       | Profile CPU hot spots                    |
| 10   | `bpftrace`   | Write custom kernel/userspace probes     |
| 11   | `ftrace`     | Deep kernel function tracing             |
| 12   | `blktrace`   | Block I/O latency analysis               |

### macOS

| Step | Tool         | Why                                      |
|------|--------------|------------------------------------------|
| 1    | `ps`         | Understand running processes             |
| 2    | `top`        | Real-time CPU and memory overview        |
| 3    | `lsof`       | See open files and network sockets       |
| 4    | `netstat`    | Inspect TCP/UDP connections              |
| 5    | `tcpdump`    | Capture live network traffic             |
| 6    | `fs_usage`   | Monitor filesystem activity              |
| 7    | `dtruss`     | Trace syscalls for a specific process    |
| 8    | `sample`     | CPU stack snapshot profiling             |
| 9    | `vmmap`      | Inspect process memory layout            |
| 10   | `nettop`     | Per-process network usage                |
| 11   | `bpftrace`   | Write custom kernel/userspace probes     |
| 12   | `dtrace`     | Full DTrace scripting and kernel tracing |
| 13   | `Instruments`| Complete performance profiling suite     |

---

> **Legend:** ✅ Native support &nbsp;|&nbsp; ❌ Not available &nbsp;|&nbsp; `(brew)` Install via Homebrew &nbsp;|&nbsp; `Limited` Partial or deprecated support
