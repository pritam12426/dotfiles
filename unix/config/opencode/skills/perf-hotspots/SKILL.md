---
name: perf-hotspots
description: Identifies likely performance-sensitive paths and hotspots in a repository by reading the actual code. Use when a user asks for performance analysis, hotspot detection, optimization opportunities, or profiling guidance based on source.
---

# Performance Hotspots

Identify likely performance-sensitive code paths from static inspection of the repository. Report only patterns that are visible in the source. Do not invent bottlenecks or claim measured timings.

## Mandatory First Steps

1. Walk the repository and identify the primary runtime (language, framework, server model).
2. Locate hot-path candidates:
   - Request or message handlers
   - Tight loops and recursive functions
   - Serialization / deserialization
   - Database or external service calls
   - Allocation-heavy or copying operations
   - Unbounded collections or buffers
   - Locking and synchronization points
3. Note any existing benchmarks, profiling hooks, or performance tests.
4. Distinguish development-only paths from production paths when the code makes the distinction clear.

## Output File

Write or update `./PERF_HOTSPOTS.md`.

## Required Sections

### 1. Runtime Shape
- Concurrency model (single-threaded event loop, thread pool, async tasks, etc.) as implemented
- How work enters the system (HTTP, queue, CLI, library call)
- Any explicit performance-related configuration found in code or config

### 2. Candidate Hotspots
For each notable location:
- File path and symbol
- Why it is likely performance-sensitive (loop, allocation, I/O, lock, etc.)
- Observed complexity characteristics when obvious (e.g. nested loops over request data, unbounded growth)
- Whether the path sits on a request/response critical path or a background path

Group by subsystem when helpful.

### 3. Allocation & Copy Patterns
Call out clear sources of repeated allocation, large copies, or unnecessary materialization that appear in hot paths.

### 4. I/O and External Calls
List synchronous or sequential external calls that sit on latency-critical paths. Note batching or concurrency that already exists.

### 5. Existing Measurement Points
Document any benchmarks, timers, metrics, or profiling endpoints already present in the repository. Prefer extending these over inventing new ones.

### 6. Suggested Measurement Order
A short prioritized list of what to measure first, derived only from the hotspots above. Do not prescribe specific tools unless they are already used by the project.

### 7. Open Questions
Note paths whose cost cannot be judged from static inspection alone.

## Rules

- Never claim a measured slowdown or speedup. This skill is static only.
- Do not recommend rewrites or new frameworks. Stay inside the current architecture.
- Prefer concrete references (file + function) over general advice.
- If the project already has a performance document, update it rather than creating conflicting guidance.
- Cross-link to `CODEBASE_MAP.md` or `./docs/DEV_IN_DEPTH.md` for architectural context.
