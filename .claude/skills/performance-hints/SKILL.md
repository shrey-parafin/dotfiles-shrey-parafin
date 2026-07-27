---
name: performance-hints
description: Use when writing or reviewing performance-sensitive code, optimizing a hot path, or investigating slow endpoints, jobs, or queries. Applies Dean & Ghemawat's "Performance Hints" (abseil.io/fast/hints) generalized beyond C++ — estimation, measure-first profiling, bulk APIs, algorithm and data-layout choices, allocation/copy reduction, avoiding unnecessary work, lock hygiene, and serialization costs — with translations for Parafin's stack (Scala backend, Python/Spark data platform, SQL/dbt) and a reviewer checklist.
---

# Performance Hints (Dean & Ghemawat)

Write and review performance-sensitive code per
[Performance Hints](https://abseil.io/fast/hints.html) by Jeff Dean and Sanjay Ghemawat,
generalized from its C++ origins to any Parafin codebase (Scala/Akka backend,
Python + Spark/Databricks data platform, SQL/dbt, TypeScript/React frontend).

**Scope guard:** this is Knuth's "critical 3%" — hot paths (per-request, per-record,
per-row), widely reused library code, and code whose scale is unbounded. Don't trade
readability for speed in cold code, and don't apply micro-optimizations without a
profile or an estimate showing they matter.

## Core stance

- "Write it simple, profile later" fails at scale: you end up with a flat profile that
  loses performance everywhere, users of your library can't fix it themselves, in-use
  systems resist change, and the fallback is overprovisioning. **When writing new code,
  choose the faster alternative whenever it doesn't significantly hurt
  readability/complexity.**
- Triage by code type: test code → asymptotics only (and keep tests fast). Application
  code → decide whether it's setup/one-off or a hot path. Library code → assume hot;
  follow the cheap, non-invasive habits below by default.

## Estimation

Back-of-envelope before building: count the expensive low-level ops (network round
trips, disk/S3 reads, DB queries, bytes shuffled/transferred), multiply each by its
rough unit cost, and sum. Use the result to discard slow designs without implementing
them. Reference costs:

```
L1 cache reference                 0.5 ns      Read 1MB sequentially from memory   64 µs
Branch mispredict                    5 ns      Read 1MB over 100 Gbps network     100 µs
Mutex lock/unlock (uncontended)     15 ns      Read 1MB from SSD                    1 ms
Main memory reference               50 ns      Disk seek                            5 ms
Read 4KB from SSD                   20 µs      Read 1MB sequentially from disk     10 ms
Round trip within same datacenter   50 µs      Packet CA→Netherlands→CA           150 ms
```

Maintain the same table for higher-level ops in the system you're touching — a Postgres
point read, a Redis get, one partner-API round trip, p50 of key internal RPCs, a Spark
shuffle per GB. Without unit costs you can't estimate.

## Measure first

- Before optimizing (or resolving a perf-vs-simplicity tradeoff), profile: Datadog
  APM/continuous profiler for services, py-spy/cProfile for Python, the Spark UI (stage
  times, shuffle sizes, task skew) for Databricks jobs, `EXPLAIN`/query profiles for SQL.
- Write a microbenchmark for the code being improved when feasible — it tightens the
  iteration loop, verifies the win, and prevents regressions. Beware benchmarks that
  aren't representative of full-system behavior.
- When the profile is flat: stack many ~1% wins; find loops near the top of the call
  stack and restructure them; step back and look for algorithmic/structural changes
  rather than micro-optimizations; replace overly general code with specialized code
  (regex → prefix match); get an allocation profile and cut the biggest allocators.

## API design

- Keep modules deep so perf work stays inside an encapsulation boundary without
  breaking callers. Resist feature creep in widely used APIs — every guarantee (e.g.
  iterator stability) taxes users who don't need it.
- **Provide and use bulk APIs.** One call for N items beats N calls: batched DB queries
  (`WHERE id IN (...)`), bulk partner-API endpoints, bulk inserts, `LookupMany`-style
  library methods. Bulk also unlocks algorithmic wins (build-in-one-shot vs. incremental
  insert, e.g. O(N) heapify vs. N pushes). If callers can't migrate, use the bulk path
  internally and cache for later single-item calls.
- Accept views/slices instead of forcing copies at function boundaries; let callers pass
  in already-computed values (e.g. `now`) and reusable buffers instead of recomputing or
  reallocating per call.
- Default shared types to thread-compatible (caller-synchronized) so callers that don't
  need locking don't pay for it; if typical use needs synchronization, put it inside the
  type so it can be tuned (e.g. sharded) without touching callers.

## Algorithms and data layout

- The biggest wins are algorithmic: O(N²) → O(N log N)/O(N), hash lookups instead of
  sorted intersection, one-shot bulk construction instead of per-element insertion,
  hash functions that actually spread keys. Check these when writing new code — they're
  rare to find in stable code but expensive to retrofit.
- Prefer contiguous, flat representations over pointer-chasing one-object-per-element
  structures: arrays/vectors/dataframes of records over maps of heap objects; integer
  indices into an array instead of references; an array indexed by a small-int/enum
  domain instead of a map; a bit vector instead of a set of small ints (set ops become
  bitwise AND/OR).
- Replace nested maps with a single map on a compound key — unless the outer key is
  large and highly repeated, in which case nesting dedupes it; measure.
- Keep hot data compact and together; keep cold fields out of hot structures.

## Reduce allocations and copies

- Pre-size containers when the size is known or estimable; never grow by repeated
  one-element reserves.
- Hoist temporaries out of loops and reuse them (buffers, parsed objects, compiled
  regexes). Caveat: reused objects grow to their largest-ever size — recreate
  periodically in long-lived loops.
- Store references/indices, not copies, in transient structures (sort a vector of
  indices, not the large records); pass slices/views rather than substring/subarray
  copies; move instead of copy where the language supports it.
- Build strings with join/builders/interpolation, never `+=` in a loop.

## Avoid unnecessary work

- **Fast paths for common cases:** a cheap check that handles the 95% case before
  falling into the general code (first-byte filter before full hash, empty/none check
  before expensive aggregation).
- **Precompute** expensive derived properties once (at construction, at module boundary,
  outside the loop). Validate inputs once at the boundary, not repeatedly inside.
- **Hoist** invariant work out of loops — compilers and interpreters usually can't.
- **Defer** expensive computation until the branch that actually needs it; compute stats
  on demand at read time instead of updating on every write.
- **Specialize** hot call sites away from overly general library calls (regex → prefix
  test, printf-style formatting → concatenation, generic deep-copy → field copy).
- **Cache** repeated work keyed by a cheap fingerprint — with an explicit invalidation
  story and a memory bound.
- Order multi-step checks so the cheapest/most-often-conclusive one runs first, even
  when counterintuitive.

## Logging, metrics, and stats on hot paths

- Log statements cost even when the level is disabled (level check, argument
  evaluation, inhibited optimizations). Drop logging from hot inner loops, or evaluate
  the level check once outside the loop.
- Keep only stats that earn their cost; sample (with cheap power-of-two decisions)
  instead of recording every event; reduce sampling rates under load.

## Parallelism and locks

- Parallelize independent items in batches (chunk first so per-item dispatch doesn't
  dominate). Measure: if CPU or memory bandwidth is already saturated, parallelism can
  hurt.
- Amortize lock acquisition — lock once per batch, not per item — provided it doesn't
  lengthen contention.
- Keep critical sections short: never hold a lock across an RPC, DB call, or file I/O;
  compute inputs before locking, act on results after unlocking.
- Shard contended structures (requires no cross-shard invariants) or use a concurrent
  map; don't reuse the same hash bits for shard selection and the inner table.
- Use buffered queues/channels for pipelining; unbuffered only for synchronization.

## Serialization and wire formats

Wire formats (JSON, protobuf) are for boundaries, not in-memory working state — the
source doc measures a 20x slowdown iterating a protobuf list vs. a plain vector of
structs. Generalized:

- If data is never serialized, don't store it in a serialization type; convert once at
  the boundary into native structures.
- Parse only what's needed (subset messages, ignored fields, lazy/deferred parsing);
  keep message shapes flat instead of nesting a message per scalar.
- Avoid copying large blobs — use views/aliasing where the framework supports it; reuse
  parse/serialize buffers across iterations.
- For long-lived in-memory storage of many messages, serialized form can be 5x smaller
  than parsed objects.

## Parafin translations

- **Backend/API (Scala, TS):** the N+1 query/RPC in a request handler is this doc's
  "missing bulk API" — batch it. No I/O inside a lock or a per-element loop when a bulk
  variant exists. Pre-size builders/collections in hot handlers.
- **Data platform (Python/Spark/dbt):** a Python UDF is a per-row API-boundary crossing —
  prefer native Spark/SQL expressions. Filter and project early (partition pruning,
  predicate pushdown); avoid `collect()`; broadcast small join sides; watch shuffle
  size and skew in the Spark UI. Per-row loops over dataframes are the "avoid
  unnecessary work" anti-pattern — vectorize.
- **Python generally:** dict/set membership over list scans; `''.join` over loop
  concatenation; hoist attribute lookups and compiled regexes out of hot loops;
  numpy/pandas vectorization over row iteration.

## Reviewer checklist (blocking vs nit)

When reviewing (or self-reviewing) code on a hot path, scan for:

- **Per-item I/O in a loop** (N+1 queries, per-row RPC/API calls) where a bulk variant
  exists or could. *Blocking.*
- **Superlinear algorithm on unbounded input** (O(N²) scans, repeated sorts, membership
  tests on lists). *Blocking.*
- **I/O or expensive work while holding a lock.** *Blocking.*
- **Python UDF / `collect()` / row iteration** in a production pipeline where native
  Spark/SQL works. *Blocking.*
- **Cache without an invalidation story or memory bound.** *Blocking* — correctness, not
  just speed.
- Allocation/construction inside hot loops (fresh containers, regex compilation, config
  parsing). Nit unless profiled hot.
- Missing pre-size on containers of known size; string `+=` in loops. Nit.
- Logging/metrics in hot inner loops. Nit; blocking if per-record in a pipeline.
- **Speculative complexity in the name of performance** with no estimate or profile —
  push back the other way; the doc's bar is "faster only when it doesn't significantly
  hurt readability."

Further reading lives at [abseil.io/fast](https://abseil.io/fast/) (performance tips of
the week) and the source doc's worked examples.
