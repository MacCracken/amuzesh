# Benchmarks

`tests/amuzesh.bcyr`, recorded with `scripts/bench-history.sh` (median of 3 runs, run as
CI runs it: `CYRIUS_DCE=1 cyrius bench tests/amuzesh.bcyr`). The raw rows are in
[`../bench-history.csv`](../bench-history.csv).

**Fixture**, the same for every row: `amz_make_blobs(128, 8, 8, seed 7)`, i.e. n = 1,024
points, d = 8, k = 8 well-separated clusters. `proto_predict` and `sqdist` are per call;
every other row is one call over the whole fixture.

Compare rows only when they were recorded in the same session on the same host. This
laptop-class host moves about ±10% between runs, and occasionally 2× under contention.
The median of three absorbs the first, not the second.

## 0.2.1 → 0.2.2 (the P(-1) sweep), 2026-11-09, one session

| Row | 0.2.1 | 0.2.2 | Speed-up |
|---|---:|---:|---:|
| `sqdist` | 100 ns | 38 ns | 2.6× |
| `kmeans_assign` | 813 µs | 209 µs | 3.9× |
| `kmeans_update` | 137 µs | 46 µs | 3.0× |
| `kmeans_pp_seed` | 855 µs | 203 µs | 4.2× |
| `kmeans_fit` | 3.83 ms | 0.89 ms | 4.3× |
| `proto_fit` | 138 µs | 62 µs | 2.2× |
| `proto_predict` | 801 ns | 295 ns | 2.7× |
| `purity` | 12.8 µs | 11.6 µs | 1.1× |

The 0.2.2 rows **include** the new argument validation (an O(n·d) finiteness pass at
each judging entry point). Where the time went:

- **Direct row access** ([ADR 0003](adr/0003-direct-row-access.md)): one row address,
  then `load64`, instead of two non-inlined `ganita_mat_get` calls per element. That is
  102 → 37 ns per distance on its own, bit-identical.
- **Partial-distance search** in assignment, the k-means++ fold and prediction: a
  candidate's sum stops once it can no longer win. Every decision and the inertia are
  bit-identical. Against full sums in the same session: `kmeans_assign` −27%,
  `kmeans_pp_seed` −25%, `kmeans_fit` −28% at d = 8; −32% / −39% (assign / fit) at
  d = 32; still a small gain at d = 2.
- **k-means++**: the walk stops at its pick, and the total is folded into the
  minimum-distance pass. The last center needs no fold.
- **The fit** allocates once and swaps two label buffers instead of copying one each
  pass.
- **`kmeans_update` / `proto_fit`** pay for the running mean (one division per row, three
  operations per coordinate instead of one) and are still 2–3× faster than 0.2.1.
- **`purity`** is O(n + k + ncls) instead of O(k·n). At this fixture's k = 8 that is a
  wash. It is the large-k case that changed. Same session, n = 1,024, ncls = 8:

  | k | 0.2.1 algorithm | 0.2.2 |
  |---:|---:|---:|
  | 8 | 15.3 µs | 11.5 µs |
  | 64 | 105.7 µs | 11.7 µs |
  | 512 | 796.7 µs | 14.1 µs |

## Not measured here

- The compiler's f64 code generation sets the floor: each f64 builtin is a short
  push/pop sequence through memory, so an inner loop of sub / mul / add is about a dozen
  instructions per operation. tyche's 2026-11-04 audit measured the same thing.
- CI runs the benchmarks but does not gate on them; runner timings are too noisy.
