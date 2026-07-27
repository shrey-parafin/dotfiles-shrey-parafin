---
name: performance-engineering
description: Diagnose, design, implement, and review evidence-based performance improvements across Parafin codebases. Use when investigating latency, throughput, central processing unit usage, memory, allocation, database or network round trips, slow tests or builds, scalability, contention, hot paths, profiling, load tests, benchmarks, regressions, or performance-sensitive application programming interfaces; when optimizing code or queries; or when reviewing a change for performance risk.
---

# Performance Engineering

Improve performance by finding and removing the dominant cost, then proving the
result under a representative workload. Apply the principles across languages
and repositories; treat language-specific techniques as examples, not rules.

## Core rules

1. **Define the outcome.** Name the metric, workload, and acceptable tradeoffs
   before optimizing.
2. **Estimate before instrumenting.** Use order-of-magnitude reasoning to identify
   likely dominant costs and choose useful measurements.
3. **Measure before and after.** Do not claim an improvement from intuition, code
   size, or benchmark results gathered under different conditions.
4. **Remove work before making work faster.** Prefer structural improvements,
   bulk operations, and better algorithms over low-level tuning.
5. **Protect simplicity and correctness.** Choose the faster option by default
   when readability stays comparable. Require evidence for added complexity.
6. **Optimize the real bottleneck.** Re-profile after each material change;
   yesterday's hotspot may not be today's.

## Workflow

### 1. Frame the performance question

Inspect repository guidance, existing observability, benchmark tooling, and the
relevant execution path. Record:

- Target metric: latency, throughput, resource use, memory, cost, startup time,
  build time, or another explicit measure.
- Representative workload: input sizes and distributions, concurrency, cache
  state, environment, and expected production volume.
- Constraint: service-level objective, capacity target, regression threshold, or
  comparison to a known baseline.
- Non-negotiables: correctness, auditability, compatibility, reliability, and
  maintainability.

Distinguish setup or test-only code from per-request, per-record, shared-library,
or otherwise frequently executed code. Shared code deserves efficient defaults
because downstream callers may not be able to repair its costs.

When the user asks only for diagnosis or review, stop after presenting evidence,
ranked hypotheses, and a measurement plan. Change code only when asked to
optimize or fix it.

### 2. Build a cost model

Trace the end-to-end path and estimate the multiplicative terms:

```text
total cost ≈ requests × items/request × operations/item × cost/operation
```

Count expensive boundaries explicitly: database queries, network round trips,
serialization, disk input/output, allocations, copies, lock acquisitions,
scanned bytes, shuffled data, and repeated computations. Separate resource cost
from wall-clock latency because concurrent work can overlap.

Use the estimate to rank hypotheses. Label unmeasured claims as hypotheses.

### 3. Establish a baseline

Prefer production-shaped evidence, using the least expensive tool that can
resolve the question:

1. Existing service metrics, traces, query plans, and production profiles.
2. An integration or load benchmark that preserves important boundaries.
3. A focused microbenchmark for an in-process hot routine.

Use optimized or production-equivalent builds. Keep hardware, dependencies,
configuration, data, warmup, concurrency, and cache state consistent. Capture
multiple samples and relevant percentiles, not one favorable run.

If the profile is flat, inspect loops high in call stacks, allocation profiles,
boundary crossings, overly general abstractions, and cumulative small costs.

### 4. Choose the highest-leverage intervention

Apply this order unless evidence supports another:

1. **Eliminate work:** batch calls, avoid repeated queries, defer or skip work,
   precompute stable values, cache safely, sample expensive telemetry, or add a
   common-case fast path.
2. **Improve the algorithm or access pattern:** reduce asymptotic complexity,
   make one pass instead of many, use bulk construction, or move filtering and
   aggregation to the appropriate layer.
3. **Reduce movement and representation cost:** copy less, allocate less, reuse
   buffers, reserve known capacity, choose compact contiguous representations,
   and avoid unnecessary serialization.
4. **Reduce hot-loop overhead:** hoist invariants, simplify general operations,
   reduce logging or metrics cost, and separate hot and cold paths.
5. **Improve concurrency:** parallelize coarse independent work, shorten critical
   sections, amortize synchronization, or shard contended state.
6. **Tune low-level execution:** change inlining, layout, vectorization, or other
   machine-level details only after profiling justifies it.

Read [references/technique-catalog.md](references/technique-catalog.md) when
selecting or reviewing concrete techniques.

### 5. Implement the smallest supported change

- Preserve public interfaces when an implementation-level improvement suffices.
- Keep uncommon and error paths correct when adding a fast path.
- Bound caches and define ownership, invalidation, and lifecycle behavior.
- Avoid moving validation away from trust boundaries merely to save work.
- Do not parallelize work without checking scheduling overhead, downstream
  capacity, memory bandwidth, ordering, retries, and failure semantics.
- Add comments only where a non-obvious invariant or tradeoff must survive.

Prefer one attributable optimization per change when practical. Multiple small
changes are acceptable when the benchmark can isolate or justify the bundle.

### 6. Verify the result

Run correctness tests first, then repeat the baseline measurement under the same
conditions. Check:

- The target metric improved by more than expected noise.
- Tail behavior, resource use, and cost did not regress.
- Representative small, typical, large, cold, warm, and concurrent cases behave
  as expected.
- The improvement holds outside a synthetic microbenchmark when end-to-end
  performance matters.
- Failure paths, cancellation, retries, ordering, and observability remain valid.

Add a durable regression guard when stable and economical: a benchmark, load
test, query-plan assertion, complexity test, allocation limit, or monitored
production metric.

### 7. Report evidence

Summarize:

- Workload and environment.
- Baseline result and profile evidence.
- Dominant cost and why the change addresses it.
- Before/after results with sample count and variability.
- Correctness checks and tradeoffs.
- Remaining bottleneck and whether further optimization is worthwhile.

Do not report a percentage improvement without the raw before/after values and
measurement conditions.

## Review checklist

- [ ] Is this path frequent or expensive enough to matter?
- [ ] Are scale and complexity acceptable at expected and worst-case inputs?
- [ ] Are calls, queries, scans, allocations, copies, and locks multiplied inside
      loops?
- [ ] Can a bulk interface or one-pass algorithm remove repeated overhead?
- [ ] Does the representation match ownership, access pattern, and typical size?
- [ ] Is observability useful enough to justify its hot-path cost?
- [ ] Does concurrency reduce latency without increasing contention or overload?
- [ ] Is the benchmark representative, repeatable, and compared consistently?
- [ ] Does added complexity have measured value and a regression guard?

## Related Parafin skills

- Use `infrastructure:observability-guide` to add or assess service observability.
- Use `data-platform:pf-databricks-debug-spark-ui` for distributed Spark
  execution details.
- Use `dev-workflow:bug-prevention-framework` to assess load-related failure
  modes and mitigation.
