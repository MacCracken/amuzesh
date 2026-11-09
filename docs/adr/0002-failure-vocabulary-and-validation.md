# 0002 — Validate every public entry point, and fail in ganita's vocabulary

**Status**: Accepted
**Date**: 2026-11-09

## Context

Through 0.2.1 no amuzesh function checked an argument. The 2026-11-09 P(-1) audit
([`../audit/2026-11-09-audit.md`](../audit/2026-11-09-audit.md)) reproduced what that
meant:

- A class or cluster label outside its range was used as a row index into
  `ganita_mat_set`, which is unchecked by design: a label of 2^40 killed the process
  (SIGSEGV), and a label equal to `ncls` silently corrupted the prototype next to it.
- `n = 0` divided by zero in the k-means++ draw (SIGFPE). `k = 0` wrote through the null
  matrix `ganita_mat_new` returns. A `max_iter` near 2^61 wrapped `max_iter * 8` and wrote
  through a null history.
- A single NaN in the data produced a model with NaN inertia and 33% purity, with no
  signal.

amuzesh sits on ganita, which already settled both halves of this question for its own
surface: [ganita ADR 0001](https://github.com/MacCracken/ganita/blob/main/docs/adr/0001-failure-vocabulary.md)
(one failure shape per return kind) and
[ganita ADR 0004](https://github.com/MacCracken/ganita/blob/main/docs/adr/0004-non-finite-input.md)
(functions that judge their input refuse NaN and infinity; functions that carry values
propagate them). A consumer that uses both libraries should not have to learn two
conventions.

## Decision

**Every public amuzesh function validates its arguments before it writes anything, and
reports failure in ganita's vocabulary.**

| The function returns | Failure |
|---|---|
| a pointer (`amz_kmeans_fit`, `amz_proto_fit`) | `0` |
| a status, count or class index (`amz_kmeans_pp_seed`, `amz_kmeans_update`, `amz_proto_predict`, `amz_make_blobs`) | `AMZ_ERR_ALLOC` (−1) or `AMZ_ERR_ARG` (−2) |
| an f64 (`amz_kmeans_assign`, `amz_purity`, `amz_proto_accuracy`) | NaN |

What is checked:

- **Shapes.** A matrix argument is non-null, has at least the rows the call reads, and
  has exactly `d` columns. A `d` that disagrees with the matrix is a caller bug, not a
  request for a column prefix.
- **Ranges.** `1 ≤ k ≤ n` for k-means; `ncls ≥ 1`; every label in `[0, k)` or `[0, ncls)`;
  `0 ≤ rx < rows` for a query.
- **Non-finite input**, by ganita ADR 0004's rule. Fit, seeding, assignment, prototype
  fit, predict and accuracy *judge* their input and refuse a NaN or infinity in it.
  `amz_kmeans_update` only computes means, so it *carries* and propagates them. The test
  is on the exponent bits, so it does not depend on how a target compares a NaN.
- **Sizes.** Every allocation goes through one helper that refuses a word count whose
  byte size would exceed `ALLOC_MAX`, so `count * 8` cannot wrap.
- **`max_iter ≤ AMZ_KMEANS_MAX_ITER` (10,000).** This is a policy limit, like ganita's
  element cap ([ganita ADR 0002](https://github.com/MacCracken/ganita/blob/main/docs/adr/0002-element-cap-is-policy.md)).
  A fit allocates its inertia history up front and the heap never frees
  ([`../architecture/001-the-heap-never-frees.md`](../architecture/001-the-heap-never-frees.md)),
  so the cap bounds one call at 80 KB of history. Lloyd's iteration converges in tens to
  hundreds of passes on real data, and scikit-learn defaults to 300.

What is **not** checked: the length of a raw `i64` label array. It carries no length, so
its length is the caller's `n`. This is the one input amuzesh cannot validate, and the API
reference says so.

The inner kernels (`amz_sqdist`, `amz_copy_row`, and the private `_amz_*` functions) stay
unchecked, exactly like `ganita_mat_get`. Each public function validates once and then
runs them. The model accessors are null-safe, so a refused fit (model 0) reads as a
failure, not a crash.

## Consequences

- **Positive.** Every crash and silent corruption the audit reproduced is now a refusal,
  and the fuzz harness checks the whole contract on 10,000 randomized rounds. A consumer
  that checks one result shape per return kind is safe, and that shape is the one ganita
  uses.
- **Negative.** Each judging call pays an O(n·d) finiteness pass. Measured, this is far
  less than the call's own O(n·k·d) and is included in the 0.2.2 benchmark rows. A call
  that "worked" on bad input in 0.2.1 now returns 0, −2 or NaN. That input never had a
  meaningful answer.
- **Neutral.** `src/check.cyr` is a new file, so a consumer adds one include
  (after `src/dist.cyr`).

## Alternatives considered

- **Document preconditions and stay unchecked** (the 0.2.1 position, and ganita's for
  `mat_get`/`mat_set` only). Rejected: amuzesh's charter is the model you can account
  for, and its inputs are training data and labels, exactly what arrives from outside.
  The checks cost one pass at each entry point, not one per inner-loop step.
- **A `Result` value form.** cyrius has one, but neither substrate library uses it on
  this surface, and a second convention is exactly what this ADR avoids.
- **Clamp bad input** (clip labels, replace NaN). Rejected: it hides a caller bug and
  produces an answer about data the caller did not pass.
- **No `max_iter` cap, only the allocation check.** The allocation check alone refuses
  only counts past 2 GiB. Every larger budget below that is accepted and costs its full
  history whether or not the fit needs it.
