# amuzesh — Roadmap

> The sequencing from 0.3.x to the 1.0.0 freeze, and the backlog after it. Current
> state lives in [`state.md`](state.md); what already shipped lives in
> [`CHANGELOG.md`](../../CHANGELOG.md) (0.1.0 M0 → 0.2.2 P(-1) sweep → 0.3.0 the
> consumable `dist/amuzesh.cyr` bundle).

amuzesh grows by pull, not push ([ADR 0001](../adr/0001-amuzesh-scope-and-substrate.md)).
The road to 1.0.0 therefore freezes the surface that exists, k-means(++) and the
nearest-centroid classifier, once a real consumer runs on it. New model classes wait in
the [v1 backlog](#v1-backlog) for a consumer that needs them.

## v1.0 criteria

- [ ] Public API frozen: [`docs/api.md`](../api.md) marked frozen, the 1.x rules below in force (1.0.0)
- [x] Every exported symbol documented and tested: [`docs/api.md`](../api.md), 123 assertions with bit-exact known answers (0.2.2)
- [x] Test coverage adequate for the surface area: 10,000-round fuzz harness, 14/14 mutants killed, aarch64 CI leg (0.2.2)
- [x] Benchmarks captured in [`docs/benchmarks.md`](../benchmarks.md) (0.2.2)
- [ ] At least one downstream consumer green (0.4.x)
- [x] CHANGELOG complete from v0.1.0 onward
- [x] Security audit pass: [`docs/audit/2026-11-09-audit.md`](../audit/2026-11-09-audit.md) (0.2.2). Re-run before the freeze (0.5.x).

## Rules for every release

- **Known answers are a contract.** The suite pins exact bit patterns for the blobs,
  seeds, assignments and fits. A change that moves any of them is a numerical change: it
  gets its own minor and a CHANGELOG entry saying which outputs move and by how much.
  Optimizations that keep the bits can ride any patch.
- **New public functions follow [ADR 0002](../adr/0002-failure-vocabulary-and-validation.md)**:
  validate once at the entry point, fail in the 0 / −1 / −2 / NaN vocabulary, and keep inner
  loops on the unchecked `src/dist.cyr` kernels. Every new function gets refusal tests and
  a fuzz case.
- **P(-1) before each minor cut** (first-party standards): fmt, lint and vet clean, the
  benchmarks re-stamped with `scripts/bench-history.sh`, and findings filed in `docs/audit/`.
- **Toolchain and dependency realigns ride patches**, by the procedure in [`state.md`](state.md).

## 0.3.x — patches

Toolchain and dependency realigns as they come, by the release rules above. The bundle is
regenerated with each one (its header carries the version).

## 0.4.x — First consumer green

**Gate:** a consumer pulls. The lane plan names the likely first movers: phylax / aegis
(auditable threat-feature models), and ifran-side classification over external
embeddings (the 2026-06-25 product mining). None depends on amuzesh yet. The integration
path exists since 0.3.0: `[deps.amuzesh] modules = ["dist/amuzesh.cyr"]` next to ganita and
tyche ([`docs/api.md`](../api.md)).

- Integrate with that consumer on a tagged amuzesh release, its suite green in its own CI.
- Add the additive API its real use surfaces, judged against what it actually needs.
  Known candidates, each from the 0.2.2 audit or the mined demand:
  - **Caller-owned scratch variants** of `amz_kmeans_pp_seed`, `amz_kmeans_update` and
    `amz_purity`, so a loop (model selection over k, restarts) does not grow the
    never-freeing heap ([architecture 001](../architecture/001-the-heap-never-frees.md)).
  - **A signal for fewer distinct points than k.** Today the extra centers silently repeat
    a point.
  - **Cosine or normalized distance** for embedding inputs.
- Record the consumer in `state.md`.

**Done when:** the v1.0 consumer criterion is met.

## 0.5.x — Freeze candidate

**Gate:** 0.4.x green. This is the last chance to change the surface for free.

- **API review.** Settle what 1.0 freezes:
  - whether `amz_make_blobs` is public API or a test fixture;
  - whether the unchecked kernels `amz_sqdist` / `amz_copy_row` stay public or become
    `_amz_` private;
  - whether the 9-slot model layout is part of the contract or reachable only through the
    accessors;
  - the `AMZ_*` constants, including the `AMZ_KMEANS_MAX_ITER` policy cap;
  - whether the `amz_make_blobs` fixture stays in `dist/amuzesh.cyr` (it ships there since
    0.3.0) or moves to a `[lib.fixtures]` profile.
- **Pre-freeze P(-1) sweep**: the full audit again, including mutation testing and both
  architectures. The standards require one before the v1.0 freeze.
- **`docs/api.md` marked frozen** and the 1.x rules written into it.

## 1.0.0 — Freeze

No behavior change from the last 0.5.x. The documented surface becomes load-bearing:
1.x minors only add, and a change to a frozen symbol's signature or meaning waits for 2.0.

## v1 backlog

Unscheduled, after 1.0.0. Each item waits for a consumer that needs it and lands as an
additive 1.x minor unless marked otherwise. Per the family's extraction rule, a mechanism
moves out into its own library only when a *second* consumer needs it.

### Model classes (the lane, from [`classical-shallow-ml.md`](https://github.com/MacCracken/agnosticos/blob/main/docs/development/planning/classical-shallow-ml.md))

Ordered by how much genuinely new code each adds over the substrate. Each gets the
honest verification for its kind: a finite-difference gate where there is a gradient, and
convergence or coverage where there is not.

| Mechanism | New content | Substrate | Verification | Pull |
|---|---|---|---|---|
| Linear / ridge regression | thin | ganita least-squares / pseudo-inverse | analytic solutions, residual | any regression consumer |
| PCA | thin | ganita eigen / SVD | reconstruction error, orthogonality | dimensionality reduction ahead of k-means |
| Logistic regression (IRLS) / softmax | modest | ganita solves; hisab GD | FD-gated gradient, convergence | the GLM classification floor |
| Naive Bayes | modest | abaco statistics | analytic likelihoods, held-out accuracy | small-data classification |
| Kalman / HMM filters | modest | ganita | RMSE against the Kalman-optimal baseline; Viterbi against brute force | noisy state streams (research-watch) |
| Gradient-boosted trees | substantial | — | FD-gated leaf fits; split-path auditability | phylax / aegis auditable model (research-watch) |

**On-agnos gate:** amuzesh is f64 throughout, and agnos ring-3 enables no FP until the
kernel FP / SIMD arc (agnos 1.53.x). Running any of these on agnos waits on that arc.
Host and QEMU validation are unaffected.

### Engineering

- **A per-model RNG stream.** Fitting reseeds tyche's single global stream, a side effect
  on the caller, and nothing is thread-safe. This needs tyche's per-stream handles (tyche's
  roadmap; gate: the SMP arc).
- **A ganita row or data accessor** would retire [ADR 0003](../adr/0003-direct-row-access.md)'s
  dependency on ganita's storage layout. That is an upstream change; `_amz_row` becomes a
  call to it.
- **k-means restarts**: the best inertia over several seeds, since k-means++ is randomized.
- **Relocating empty clusters** to far points, as an alternative to 0.1.0's retention of
  the previous centroid.
- **Model persistence** (save / load). This adds parsing of untrusted input, so it changes
  the threat model in [`SECURITY.md`](../../SECURITY.md) and needs its own security pass.
- **Overflow-robust distances** for coordinate gaps above ~1.3e154, where squared
  distances saturate to +∞. Only if a consumer has such data.

## Out of scope

- **Anything gradient-based or neural**: attn11 / tarka / tentib / prajna.
- **GPU.** amuzesh is CPU f64; mabda is a later accelerator concern.
- **Reimplementing the substrate**: linear algebra (ganita), optimization (hisab), the
  PRNG (tyche) and statistics (abaco) are consumed, not rebuilt.
