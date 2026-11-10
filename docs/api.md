# amuzesh API

The public surface as of 0.3.0. amuzesh is 0.x: this surface is not frozen.

## Including amuzesh

The library is one bundle, `dist/amuzesh.cyr` (since 0.3.0), built by `cyrius distlib`
from `src/dist.cyr`, `src/check.cyr`, `src/kmeans.cyr`, `src/proto.cyr` and
`src/data.cyr`. amuzesh builds on ganita (matrices) and tyche (the PRNG), which a consumer
declares itself, as with rosnet's tyche dependency:

```toml
# a consumer's cyrius.cyml
[deps.ganita]
git = "https://github.com/MacCracken/ganita"
tag = "1.2.15"
modules = ["dist/ganita.cyr"]

[deps.tyche]
git = "https://github.com/MacCracken/tyche"
tag = "1.2.2"
modules = ["dist/tyche.cyr"]

[deps.amuzesh]
git = "https://github.com/MacCracken/amuzesh"
tag = "0.3.0"
modules = ["dist/amuzesh.cyr"]
```

`cyrius deps` resolves the three into `lib/` and the build prepends them, in any order.
Without the build tool, include them in dependency order:

```cyrius
include "lib/ganita.cyr"     # matrix storage
include "lib/tyche.cyr"      # PRNG (k-means++, blobs)
include "dist/amuzesh.cyr"   # amuzesh; its # Requires block includes lib/alloc.cyr
```

The bundle's stdlib needs are listed in `dist/amuzesh.deps` (the allocator). Everything
else it calls comes from ganita and tyche. CI proves both forms: the raw include builds
with `--no-deps`, and the whole suite and fuzz harness pass against the bundle
(`scripts/consumer-check.sh`).

## Conventions

- **Values.** Every f64 is an IEEE-754 bit pattern in an i64. Matrices are ganita
  matrices (`ganita_mat_new(rows, cols)`), row-major, one data row per row. Label arrays
  are raw `i64` arrays of length `n`.
- **Failure** ([ADR 0002](adr/0002-failure-vocabulary-and-validation.md)): a pointer
  result is `0`, a status / count / class result is `AMZ_ERR_ALLOC` (−1) or `AMZ_ERR_ARG`
  (−2), an f64 result is NaN (`AMZ_NAN`). Test with `== 0`, `< 0`, or a NaN check.
- **Shapes.** A matrix argument must be non-null, have at least the rows the call reads,
  and have exactly `d` columns.
- **Non-finite input.** Functions that judge their input (fit, seeding, assignment,
  prototype fit, predict, accuracy) refuse a NaN or ±∞ in the rows they read.
  `amz_kmeans_update` carries values and propagates them.
- **The one unchecked input**: a raw label array's length. amuzesh reads `n` entries.
  Passing a shorter array is the caller's out-of-bounds read.
- **Memory.** The heap never frees
  ([architecture 001](architecture/001-the-heap-never-frees.md)). Results and per-call
  scratch stay allocated for the life of the process.
- **RNG.** `amz_kmeans_fit` and `amz_make_blobs` reseed tyche's single global stream
  with their `seed`. Nothing here is thread-safe.

## k-means

### `amz_kmeans_fit(X, n, d, k, max_iter, seed) -> model | 0`

k-means++ seeding (Arthur & Vassilvitskii 2007), then Lloyd's iteration (assign ↔
update) until the labels repeat (a fixed point) or `max_iter` assignments have run.

- Requires `1 ≤ k ≤ n`, `1 ≤ max_iter ≤ AMZ_KMEANS_MAX_ITER` (10,000), and the first `n`
  rows of `X` (n×d) finite.
- The model is always self-consistent: its labels are the nearest-centroid labels of its
  centroids, and its inertia is theirs, bit for bit. If the budget runs out first, the
  final update is skipped to keep it that way, and `amz_model_converged` returns 0.
- Allocates everything up front: about `(2·k·d + 2·n + max_iter + k + 11)·8` bytes. A
  fit's memory does not grow with its pass count.
- Deterministic: the same arguments give the same bits, on x86_64 and aarch64.

### Model accessors

All are null-safe. On model 0 they return 0 (pointers), `AMZ_ERR_ARG` (counts) or NaN
(inertia).

| Accessor | Returns |
|---|---|
| `amz_model_k(m)`, `amz_model_d(m)`, `amz_model_n(m)` | the fit's k, d, n |
| `amz_model_centroids(m)` | the k×d centroid matrix |
| `amz_model_labels(m)` | the n final labels, each in `[0, k)` |
| `amz_model_inertia(m)` | Σ squared distance of each row to its centroid (f64) |
| `amz_model_iters(m)` | assignments run, `1..max_iter` |
| `amz_model_history(m)` | per-assignment inertia (f64 array; first `iters` set) |
| `amz_model_converged(m)` | 1 at a fixed point, 0 if `max_iter` ran out |

### `amz_inertia_monotone(history, iters) -> 1 | 0 | AMZ_ERR_ARG`

1 if the history never rises by more than a relative 1e-9 between consecutive entries
(Lloyd's invariant, with room for rounding). The slack is relative, so the verdict does
not depend on the data's scale.

### `amz_kmeans_pp_seed(X, n, d, k, out_cents) -> 0 | AMZ_ERR_ARG | AMZ_ERR_ALLOC`

Writes k D²-weighted initial centers (data rows) into `out_cents` (at least k×d). The
caller seeds the RNG. Requires `1 ≤ k ≤ n` and `X` finite. With fewer than k distinct
points, the remaining centers repeat a point.

### `amz_kmeans_assign(X, n, d, cents, k, out_labels) -> inertia | NaN`

Labels each row with its nearest centroid (ties to the lowest index) into
`out_labels[0..n)` and returns the inertia. Refuses non-finite `X` or `cents`.

### `amz_kmeans_update(X, n, d, labels, k, out_cents) -> empty count | AMZ_ERR_ARG | AMZ_ERR_ALLOC`

Sets each centroid to the mean of its rows (Welford's running mean: the mean of
identical rows is exactly that row). An empty cluster keeps its previous centroid.
Every label must be in `[0, k)`. Non-finite values propagate.

### `amz_purity(labels, y, n, k, ncls) -> fraction | NaN`

(1/n) Σ over clusters of the cluster's largest true-class count. Permutation-invariant
in the cluster numbering. `labels` in `[0, k)`, `y` in `[0, ncls)`. O(n + k + ncls).

## Nearest-centroid classifier

### `amz_proto_fit(X, n, d, y, ncls) -> ncls×d prototype matrix | 0`

Row c is the mean of the rows with `y == c`. A class with no rows has a **NaN** row and
is never predicted ([ADR 0004](adr/0004-empty-class-has-no-prototype.md)). Requires
`ncls ≥ 1`, every `y` in `[0, ncls)`, and `X` finite.

### `amz_proto_predict(protos, ncls, d, Xq, rx) -> class | AMZ_ERR_ARG`

The class with the nearest prototype to row `rx` of `Xq` (ties to the lowest index),
skipping classes with no prototype. Refuses `rx` out of range, a non-finite query, or a
prototype set where no class has a prototype.

### `amz_proto_accuracy(protos, ncls, d, X, n, y) -> fraction | NaN`

The fraction of rows predicted as their label.

## Fixtures

### `amz_make_blobs(n_per, d, k, seed, out_X, out_y) -> k·n_per | AMZ_ERR_ARG`

k Gaussian blobs of `n_per` points in d dimensions. Blob c is centered at
`(c+1)·10 + axis` on each axis, with unit-variance noise. Writes the first `k·n_per`
rows of `out_X` and the labels into `out_y`.

## Unchecked kernels (`src/dist.cyr`)

`amz_sqdist(A, ra, B, rb, d)` and `amz_copy_row(src, rs, dst, rd, d)` do no checking, like
`ganita_mat_get`. The rows must be in range and `d ≤` both matrices' columns. Everything
named `_amz_*` is private and assumes a validated call.

## Constants (`src/check.cyr`)

| Name | Value |
|---|---|
| `AMZ_ERR_ALLOC` | −1 |
| `AMZ_ERR_ARG` | −2 |
| `AMZ_NAN` | `0x7FF8000000000000` |
| `AMZ_KMEANS_MAX_ITER` | 10,000 |
