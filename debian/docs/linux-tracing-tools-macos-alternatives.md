# Linux Tracing Tools & macOS Alternatives

A comprehensive guide to important tracing, debugging, and observability tools on Linux with their closest alternatives on macOS.

## 1. System Call & Library Tracing

| Tool               | Description                                                     | macOS Alternative                         |
| ------------------ | --------------------------------------------------------------- | ----------------------------------------- |
| `strace`           | Traces system calls and signals                                 | `dtruss` (via DTrace)                     |
| `ltrace`           | Traces library (userspace) calls                                | Limited support (use `dtrace` or `frida`) |
| `truss`            | Similar to strace (older)                                       | Native on macOS (but limited)             |
| `strace-log-merge` | Merges multi-thread/multi-process strace logs into one timeline | —                                         |
| `perf trace`       | Lightweight strace-like tool built on `perf`                    | —                                         |
| `frida-trace`      | Dynamic instrumentation-based function tracer (cross-platform)  | `frida-trace` (works natively)            |

## 2. Kernel & Performance Tracing

| Tool                                 | Description                                                          | macOS Alternative                |
| ------------------------------------ | -------------------------------------------------------------------- | -------------------------------- |
| `ftrace`                             | Kernel function tracer                                               | — (Limited)                      |
| `perf`                               | Powerful performance profiling & tracing                             | `instruments` (Xcode) + `dtrace` |
| `bpftrace`                           | High-level eBPF tracing (very powerful)                              | No direct equivalent             |
| `SystemTap`                          | Scripting-based kernel tracing                                       | No direct equivalent             |
| `trace-cmd`                          | Frontend for ftrace                                                  | —                                |
| `kernelshark`                        | GUI visualizer for ftrace/trace-cmd data                             | —                                |
| `LTTng`                              | Low-overhead, high-throughput tracing framework (kernel + userspace) | No direct equivalent             |
| `ply`                                | Lightweight dynamic tracer, DTrace-like syntax on top of BPF         | —                                |
| `retsnoop`                           | Traces function entry/exit with return values via BPF                | —                                |
| `kprobe`/`uprobe` (via `perf probe`) | Dynamic kernel/userspace probe points                                | `dtrace` probes                  |

## 3. eBPF Tools (Modern Standard)

| Tool                               | Description                                                 |
| ---------------------------------- | ----------------------------------------------------------- |
| `bpftrace`                         | One-liner eBPF tracing                                      |
| `bcc-tools`                        | Collection of powerful eBPF tools                           |
| `sysdig`                           | System visibility and troubleshooting                       |
| `Falco`                            | Behavioral monitoring & security                            |
| `bpftool`                          | Inspect/manage loaded BPF programs and maps                 |
| `opensnoop`                        | Traces `open()` syscalls system-wide (bcc-tools)            |
| `execsnoop`                        | Traces new process execution (bcc-tools)                    |
| `tcplife`/`tcpconnect`/`tcpaccept` | BPF-based TCP lifecycle tracing (bcc-tools)                 |
| `biosnoop`/`biotop`                | Block I/O latency and top-style I/O monitor (bcc-tools)     |
| `ebpf_exporter`                    | Exports custom eBPF metrics to Prometheus                   |
| `Pixie`                            | eBPF-based, no-instrumentation observability for Kubernetes |
| `Cilium Hubble`                    | eBPF-based network observability for Kubernetes/Cilium      |

## 4. General Debugging & Monitoring Tools

| Tool           | Description                                     | macOS Alternative                        |
| -------------- | ----------------------------------------------- | ---------------------------------------- |
| `dmesg`        | Kernel ring buffer messages                     | `log` command                            |
| `gdb`          | GNU Debugger                                    | `lldb`                                   |
| `valgrind`     | Memory debugging & profiling                    | Limited support                          |
| `lsof`         | List open files                                 | `lsof` (available)                       |
| `htop`         | Interactive process viewer                      | `htop` (via Homebrew)                    |
| `iotop`        | Disk I/O monitoring                             | `iotop` (via Homebrew)                   |
| `tcpdump`      | Packet capture                                  | `tcpdump` (native)                       |
| `wireshark`    | GUI packet analyzer                             | Native app                               |
| `vmstat`       | Virtual memory / process / CPU stats            | `vm_stat`                                |
| `mpstat`       | Per-CPU utilization (sysstat)                   | `iostat` covers some overlap             |
| `iostat`       | Device I/O statistics (sysstat)                 | `iostat` (native, different output)      |
| `sar`          | Historical system activity reporting (sysstat)  | No direct equivalent                     |
| `pidstat`      | Per-process resource stats over time (sysstat)  | —                                        |
| `nmon`         | Combined performance monitor (CPU/mem/disk/net) | —                                        |
| `glances`      | Cross-platform system monitor                   | `glances` (works natively)               |
| `netstat`/`ss` | Socket/connection statistics                    | `netstat`, `nettop`                      |
| `auditd`       | Kernel audit subsystem (security event logging) | `eslogger` (Endpoint Security framework) |
| `strace -c`    | Syscall summary/counting mode                   | —                                        |
| `criu`         | Checkpoint/restore of running processes         | No direct equivalent                     |

## 5. Memory Debugging & Sanitizers

| Tool                      | Description                                                                                              | macOS Alternative                                                |
| ------------------------- | -------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| `valgrind` (memcheck)     | Detects memory leaks, invalid access                                                                     | Limited support                                                  |
| `valgrind` (cachegrind)   | Cache/branch-prediction profiler                                                                         | —                                                                |
| `valgrind` (callgrind)    | Call-graph based profiler                                                                                | —                                                                |
| `valgrind` (helgrind/drd) | Thread error/race detector                                                                               | `Thread Sanitizer`                                               |
| `AddressSanitizer (ASan)` | Fast compiler-instrumented memory error detector                                                         | Native (Clang/Xcode support)                                     |
| `ThreadSanitizer (TSan)`  | Data race detector                                                                                       | Native (Clang/Xcode support)                                     |
| `heaptrack`               | Heap memory profiler with call-graph visualization                                                       | `leaks` / `heap` (Xcode Instruments)                             |
| `massif` (valgrind)       | Heap usage profiler over time                                                                            | Instruments "Allocations"                                        |
| `scanmem`                 | Interactive process memory scanner — locates/edits live variable values (game hacking, memory forensics) | No direct equivalent (closest: manual `lldb`/`vmmap` inspection) |

## 6. C/C++ Binary Inspection & Build Tooling

| Tool                                          | Description                                                                           | macOS Alternative                                             |
| --------------------------------------------- | ------------------------------------------------------------------------------------- | ------------------------------------------------------------- |
| `ldd`                                         | Lists shared library dependencies of a binary                                         | `otool -L`                                                    |
| `nm`                                          | Lists symbols in an object file/binary                                                | `nm` (native, same tool)                                      |
| `objdump`                                     | Disassembles binaries, shows section headers, relocations                             | `objdump` (via Homebrew) or `otool -tv`                       |
| `readelf`                                     | Detailed ELF file format inspector                                                    | No direct equivalent (Mach-O differs) — use `otool`           |
| `addr2line`                                   | Converts addresses to file/line numbers (needs debug symbols)                         | `atos`                                                        |
| `size`                                        | Reports section sizes (text/data/bss) of a binary                                     | `size` (native)                                               |
| `strings`                                     | Extracts printable strings from a binary                                              | `strings` (native)                                            |
| `file`                                        | Identifies file type (ELF, Mach-O, etc.)                                              | `file` (native)                                               |
| `ldconfig`                                    | Manages/caches shared library search paths                                            | `dyld` cache is managed automatically; `dyld_info` to inspect |
| `strip`                                       | Removes symbol/debug info from a binary                                               | `strip` (native)                                              |
| `ar`                                          | Creates/manages static library archives (`.a`)                                        | `ar` (native)                                                 |
| `ranlib`                                      | Generates index for static library archives                                           | `ranlib` (native)                                             |
| `patchelf`                                    | Modifies ELF RPATH, interpreter, dependencies post-build                              | `install_name_tool` (Mach-O equivalent)                       |
| `ldd`-style dyld inspection                   | —                                                                                     | `dyld_info -dependents <binary>`                              |
| `elfutils` (`eu-readelf`, `eu-nm`, etc.)      | Alternative ELF toolchain, often more detailed than GNU binutils                      | —                                                             |
| `objcopy`                                     | Copies/translates object files, extracts sections                                     | No direct equivalent                                          |
| `ldd -v` / `ld.so --list`                     | Dynamic linker diagnostics, verbose dependency resolution                             | `DYLD_PRINT_LIBRARIES=1 <binary>`                             |
| `LD_DEBUG=libs`/`LD_PRELOAD`                  | Env vars to debug dynamic linking / inject shared libs                                | `DYLD_PRINT_APIS`, `DYLD_INSERT_LIBRARIES`                    |
| `ccache`                                      | Compiler cache to speed up repeated C/C++ builds                                      | Works natively                                                |
| `cppcheck`                                    | Static analysis for C/C++                                                             | Works natively                                                |
| `clang-tidy`                                  | Static analysis & linting built on Clang/LLVM                                         | Works natively                                                |
| `include-what-you-use` (IWYU)                 | Analyzes and fixes unnecessary/missing `#include`s                                    | Works natively                                                |
| `cscope`/`ctags`                              | Source code navigation/indexing for large C/C++ codebases                             | Works natively                                                |
| `compiler-explorer` (Godbolt, local instance) | Interactive assembly-output viewer for C/C++ snippets                                 | Works natively (web-based)                                    |
| `radare2`                                     | Full reverse-engineering framework: disassembler, debugger, binary analysis, patching | Works natively (also supports Mach-O)                         |

## 7. Network Tracing & Analysis

| Tool                 | Description                                            | macOS Alternative      |
| -------------------- | ------------------------------------------------------ | ---------------------- |
| `tcpdump`            | CLI packet capture                                     | Native                 |
| `wireshark`/`tshark` | GUI/CLI packet analysis                                | Native app             |
| `ss`                 | Modern socket statistics (replaces netstat)            | `nettop`, `lsof -i`    |
| `nethogs`            | Per-process bandwidth usage                            | —                      |
| `iftop`              | Real-time bandwidth usage by connection                | `iftop` (via Homebrew) |
| `conntrack`          | Inspect/manipulate netfilter connection tracking table | —                      |
| `mtr`                | Combined traceroute + ping diagnostics                 | `mtr` (via Homebrew)   |
| `ngrep`              | grep-style search over network traffic                 | `ngrep` (via Homebrew) |

## 8. Container & Cgroup Tracing

| Tool                            | Description                                                       |
| ------------------------------- | ----------------------------------------------------------------- |
| `crictl`                        | CLI for inspecting CRI-compatible container runtimes (Kubernetes) |
| `nsenter`                       | Enter namespaces of another process for inspection                |
| `systemd-cgtop`                 | Real-time cgroup resource usage viewer                            |
| `docker stats` / `podman stats` | Live container resource usage                                     |
| `ctop`                          | Top-like interface for container metrics                          |
| `runc events`                   | Low-level container runtime event stream                          |

## 9. Flame Graphs & Visualization

| Tool                            | Description                                                                  |
| ------------------------------- | ---------------------------------------------------------------------------- |
| `FlameGraph` (Brendan Gregg)    | Perl/shell scripts to render stack traces as flame graphs                    |
| `perf script` + `stackcollapse` | Pipeline to convert `perf` samples into flame-graph input                    |
| `speedscope`                    | Browser-based interactive flame graph viewer                                 |
| `hotspot`                       | GUI frontend for `perf` data analysis                                        |
| `py-spy` / `async-profiler`     | Language-specific sampling profilers that output flame-graph-compatible data |

## 10. macOS Native Tracing Tools (Strong Points)

- **`dtrace`** — Most powerful built-in tracing tool (similar to combination of strace + ftrace)
- **`Instruments`** — GUI performance analysis tool (Xcode)
- **`dtruss`** — strace equivalent (`sudo dtruss -p <PID>`)
- **`fs_usage`** — File system activity monitor
- **`sc_usage`** — System call usage
- **`vmmap`** — Virtual memory map
- **`sample`** — Sampling profiler
- **`ktrace`** — Kernel tracing (newer)
- **`spindump`** — System-wide sampling of all processes (hang diagnosis)
- **`log`/`log stream`** — Unified logging system (structured, replaces syslog)
- **`eslogger`** — Endpoint Security framework CLI event logger (security auditing)
- **`leaks`** — CLI memory leak detector
- **`heap`** — CLI heap allocation summary

## Quick Reference Commands

### Linux

```bash
strace -f -o trace.log ./program
perf top
perf record -F 99 -a -g -- sleep 30 && perf script | stackcollapse-perf.pl | flamegraph.pl > out.svg
bpftrace -e 'tracepoint:syscalls:sys_enter_openat { @[args.filename] = count(); }'
sar -u 1 5
ss -tulpn
```

### macOS

```bash
sudo dtruss -p <PID>
sudo fs_usage -w -f filesys <PID>
sudo dtrace -n 'syscall::open*:entry { printf("%s %s", execname, copyinstr(arg0)); }'
sample <PID> 5
log stream --predicate 'process == "myapp"' --info
```
