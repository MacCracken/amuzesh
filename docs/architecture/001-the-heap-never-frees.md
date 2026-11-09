# 001 — The heap never frees, so every allocation a call makes is permanent

**True as of**: 0.2.2 (cyrius 6.7.18)

cyrius's `lib/alloc.cyr` is a bump allocator. `alloc(size)` moves a pointer forward;
there is no `free`. The only reclamation is `alloc_reset()`, which invalidates every
pointer the process holds, including the stdlib's own. amuzesh never calls it. Two more
facts about `alloc` matter here: it returns 0 for `size <= 0` or `size > ALLOC_MAX`
(2 GiB), and its memory is not guaranteed zeroed.

## What this means for amuzesh

- **Every allocation is a permanent cost to the caller's process.** A function that
  allocates scratch on each call grows the heap by that much on every call, forever.
  0.2.1's `amz_kmeans_update` allocated a k×d sum matrix and a counts array each time it
  ran, so a fit grew by 592 B per Lloyd pass at k = 8, d = 8.
- **`amz_kmeans_fit` allocates everything once, before its loop**: the centroids, two
  label buffers (`cur` and `prev`, swapped each pass; `prev` doubles as the seeding
  scratch), the inertia history (`max_iter` words), the running means, the counts and
  the 9-slot model. The total does not depend on how many passes run. The unit suite pins
  the exact byte count for a multi-pass fit.
- **The history is sized by the budget, not the outcome**, because the pass count is not
  known up front and a grown buffer could not release the old one. That is why
  `max_iter` is capped ([ADR 0002](../adr/0002-failure-vocabulary-and-validation.md)).
- **The standalone kernels still allocate per call.** `amz_kmeans_pp_seed` (n words),
  `amz_kmeans_update` (k·d + k words) and `amz_purity` (k + n + 2·ncls words) are public
  entry points with no scratch parameter. A loop calling them grows the heap. Inside a
  fit, the private kernels reuse the fit's buffers instead.
- **Allocation can fail**, and every amuzesh allocation is checked: 0 from a constructor,
  `AMZ_ERR_ALLOC` from a status function, NaN from an f64 function.
- **Never assume fresh memory is zero.** Every buffer amuzesh reads is filled first:
  `_amz_fill_words`, or `ganita_mat_new`, whose zero fill is part of its contract.

## For benchmarks and fuzzing

`tests/amuzesh.bcyr` and `tests/amuzesh.fcyr` size their iteration counts so the whole
run stays in tens of MB. The fuzz harness's 10,000 rounds take about 33 MB.
