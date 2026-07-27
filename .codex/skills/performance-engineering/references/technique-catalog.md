# Performance technique catalog

Use this catalog after a cost model and baseline identify the kind of cost that
dominates. Techniques are hypotheses until measured on the target workload.

## Contents

- [Eliminate unnecessary work](#eliminate-unnecessary-work)
- [Improve algorithms and data access](#improve-algorithms-and-data-access)
- [Design efficient interfaces](#design-efficient-interfaces)
- [Reduce allocation and copying](#reduce-allocation-and-copying)
- [Choose representations by access pattern](#choose-representations-by-access-pattern)
- [Control hot-path overhead](#control-hot-path-overhead)
- [Use concurrency deliberately](#use-concurrency-deliberately)
- [Apply runtime-specific reasoning](#apply-runtime-specific-reasoning)
- [Build trustworthy benchmarks](#build-trustworthy-benchmarks)
- [Source and scope](#source-and-scope)

## Eliminate unnecessary work

### Batch across expensive boundaries

Replace repeated per-item calls with bulk operations when the boundary has fixed
overhead, such as a database query, remote procedure call (RPC), lock, task
dispatch, serialization, or framework callback.

Check:

- Whether the batch has a bounded size and memory footprint.
- Whether partial failure and retry semantics remain clear.
- Whether latency-sensitive items can be starved while a batch fills.

### Defer, skip, or precompute

- Move loop-invariant work outside loops.
- Check cheap predicates before expensive computation.
- Compute optional data only when a consumer requests it.
- Precompute stable derived values when read frequency justifies update cost.
- Validate malformed input at a trust boundary instead of repeating equivalent
  checks inside trusted code.

Eager computation is preferable when laziness adds synchronization, repeated
misses, unpredictable latency, or lifecycle complexity.

### Add a narrow fast path

Optimize the common case while retaining the general implementation as the slow
path. Keep the fast path small enough to reduce instruction and maintenance cost.
Use measured input distributions, not anecdotes, to define "common."

### Cache repeated work

Cache only when reuse exists and the hit avoids meaningful cost. Define:

- Key correctness and collision behavior.
- Invalidation or versioning.
- Size bound, eviction, and memory accounting.
- Concurrency and stampede behavior.
- Negative-result handling.
- Whether cached data may cross authorization or tenant boundaries.

## Improve algorithms and data access

Start with asymptotic behavior, but include constants and data shape.

- Replace nested scans with indexing, hashing, sorting, or a single pass.
- Construct heaps, graphs, indexes, and other structures in bulk when the data is
  already available.
- Avoid repeated membership, cardinality, parsing, or normalization work.
- Match ordered, hashed, bitmap, array, and tree structures to the operations and
  domain size actually needed.
- Push filters or aggregation closer to the data when this reduces transfer and
  preserves correctness.
- Check for N+1 query and request patterns across service boundaries.

A theoretically better algorithm can lose on small inputs. Benchmark the actual
size distribution and retain a simple small-input path when justified.

## Design efficient interfaces

### Offer bulk operations

Use a bulk application programming interface (API) to amortize boundary and
synchronization costs or unlock a better whole-input algorithm.

### Make ownership explicit

Accept views, iterables, streams, references, or borrowed data when ownership is
not transferred and lifetime remains safe. Accept owned values when the callee
must retain or mutate them. Avoid defensive copies whose contract is unclear.

### Accept reusable context when appropriate

For frequently called routines, allow a higher layer to provide scratch storage,
precomputed metadata, timestamps, compiled expressions, or another value it
already owns. Do not expose implementation details merely to avoid a small local
cost.

### Keep modules deep

Put optimization freedom behind a narrow interface. Resist interface promises
such as stable iteration, universal thread safety, or arbitrary generality unless
callers need them; such promises can force every caller to pay.

## Reduce allocation and copying

- Reserve or pre-size collections when a reliable size estimate exists.
- Reuse temporary objects and buffers across iterations, while periodically
  releasing unexpectedly large retained capacity if needed.
- Prefer contiguous or chunked storage over one allocation per element.
- Store references or indices in transient structures instead of copying large
  objects when lifetime is safe.
- Move owned values rather than copying when the language and contract support it.
- Avoid materializing intermediate collections when an iterator, generator,
  stream, or fused operation retains clarity.
- Keep wire or storage formats at boundaries; use a purpose-fit internal
  representation for repeated computation.

Allocation reduction can lower allocator or garbage collection (GC) work and
improve locality, but pooling can increase retained memory and lifecycle risk.

## Choose representations by access pattern

Consider:

- Typical and maximum cardinality.
- Lookup, iteration, mutation, ordering, and deletion frequency.
- Hot fields versus cold fields.
- Density of integer or enumeration domains.
- Memory locality, pointer chasing, and serialization format.

Candidate changes include:

- Arrays for small dense integer domains.
- Bit vectors for dense sets of small identifiers.
- Compact numeric or enumeration widths when bounds are enforced.
- Inline storage for usually-small collections.
- Flat or chunked containers for iteration and cache locality.
- Compound keys instead of nested maps when keys are not heavily duplicated.
- Nested maps when the first key is highly repeated and accesses cluster by it.
- Indices into contiguous storage instead of pointer-rich object graphs.

Measure memory as well as speed. Compact layouts can add decoding cost, alignment
problems, false sharing, or hard-to-maintain invariants.

## Control hot-path overhead

- Move invariant computation out of loops.
- Replace overly general operations with a simpler equivalent, such as a prefix
  check instead of a regular expression.
- Maintain expensive statistics on demand or by representative sampling.
- Keep error formatting and rare paths out of the hot path.
- Avoid logging that performs formatting, allocation, or locking when disabled.
- Inspect generated code only after a profile points to compiler or runtime
  overhead.
- Inline with care: it can remove call overhead or increase code size and
  instruction-cache pressure.

Observability is part of correctness. Remove or sample telemetry only after
confirming that detection and debugging needs remain covered.

## Use concurrency deliberately

Parallelism helps when independent work is large enough to amortize scheduling
and when central processing unit (CPU), memory bandwidth, database, and downstream
capacity are available.

- Partition into coarse batches rather than scheduling every tiny item.
- Keep critical sections short; never perform unexpected network or file
  input/output (I/O) while holding a lock.
- Acquire a lock once around a safe batch when that does not increase contention.
- Shard state only when cross-shard invariants are absent or explicit.
- Separate frequently mutated state to reduce false sharing only with evidence.
- Avoid context switches for work cheaper than dispatch overhead.
- Prefer proven concurrency abstractions over custom lock-free or atomic code.

Test concurrency changes under representative contention. Single-thread
microbenchmarks cannot prove multithreaded scalability.

## Apply runtime-specific reasoning

### Python services and jobs

- First reduce algorithmic work, database calls, serialization, and Python-level
  loops.
- Prefer well-tested native or vectorized operations when they preserve memory
  bounds and readability.
- Profile wall time and allocation behavior; do not infer hotspots from line
  length.
- Include process model, interpreter warmup, and external calls in representative
  tests.

### Java Virtual Machine and Scala services

- Check allocation rate, garbage collection, boxing, collections, lock
  contention, and warmup.
- Use Java Flight Recorder or an established profiler when available.
- Benchmark after warmup and watch for dead-code elimination and constant
  folding.
- Treat fewer allocations as a hypothesis; retained heap can matter more than
  allocation count.

### Structured Query Language and Spark workloads

- Start with the query or execution plan, scanned bytes, shuffle volume, skew,
  partition pruning, spill, task count, and remote reads.
- Reduce repeated scans and tiny jobs; batch reads and writes where semantics
  allow.
- Avoid caching data without a reuse and eviction plan.
- Validate improvements on production-shaped data because small samples hide
  skew and distributed overhead.

### Remote services and databases

- Count round trips and payload bytes before tuning local code.
- Batch or pipeline independent operations while preserving rate limits and
  failure semantics.
- Avoid overfetching and repeated serialization.
- Consider queueing, pool saturation, retries, and downstream capacity in load
  tests.

## Build trustworthy benchmarks

### Microbenchmarks

Use for a small deterministic routine. Isolate setup when it is not part of the
target cost, but include it when real callers pay it. Prevent the runtime from
eliminating unused results. Cover typical and boundary input sizes.

### Integration and load benchmarks

Use when databases, networks, queues, concurrency, or framework behavior
dominates. Match request mix, payload distribution, connection pools, cache
state, and arrival pattern. Observe saturation rather than reporting only a
single low-load latency.

### Common validity failures

- Comparing debug and optimized builds.
- Changing hardware, dependencies, data, or configuration between runs.
- Reporting the best run instead of a distribution.
- Running too briefly to exceed timer and scheduler noise.
- Ignoring warmup, cold-start, or cache state.
- Benchmarking only uniform or tiny data.
- Including unrelated setup in one version but not the other.
- Measuring throughput without checking error rate or dropped work.
- Improving a microbenchmark while end-to-end latency is unchanged.

Record the command or harness, revision, environment, workload, repetitions, raw
before/after values, variability, and correctness checks.

## Source and scope

This catalog adapts the general principles from Jeff Dean and Sanjay Ghemawat's
[Performance Hints](https://abseil.io/fast/hints.html), last updated December 16,
2025. Their concrete examples focus mainly on C++ and single-binary tuning. This
reference generalizes the reasoning to Parafin's service, data, and application
code and does not treat any one library or language-specific container as a
universal recommendation.
