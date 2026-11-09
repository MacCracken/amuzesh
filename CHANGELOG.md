# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [0.2.2] - 2026-11-09

The P(-1) audit, hardening, optimization and repair sweep, recorded in
[`docs/audit/2026-11-09-audit.md`](docs/audit/2026-11-09-audit.md). Every public function
now validates its input and fails the way ganita does. Five correctness defects are
repaired, and the kernels are 2.2–4.3× faster with bit-identical decisions. The blobs,
seeds, assignments, the fit's labels and inertia, and the demo's output are
bit-identical to 0.2.1. Centroids and prototypes move by 1–2 ulp, toward the exact mean.

### Security

- **An out-of-range label no longer writes outside the heap block** (HIGH, CWE-787). Class
  labels in `amz_proto_fit` / `amz_purity` and cluster labels in `amz_kmeans_update` were
  row indices for an unchecked write. A label of 2^40 crashed. A label equal to `ncls`
  silently corrupted the neighbouring prototype. Every label is now checked against its
  range before anything is written.
- **Degenerate arguments are refused instead of crashing:** `n = 0` (was SIGFPE), `k = 0`
  and an unchecked null matrix (SIGSEGV), `k > n`, and a `max_iter` whose history size
  wrapped (SIGSEGV at 2^61). `max_iter` is capped at `AMZ_KMEANS_MAX_ITER` (10,000), and
  every allocation is overflow-checked and null-checked.
- **CI holds less privilege.** `contents: read` by default, `contents: write` only on
  the release job, and `persist-credentials: false` on every checkout, so the token is
  never in `.git/config` when the `curl | sh` installer runs.

### Added

- **`src/check.cyr`**: argument validation and the failure vocabulary
  ([ADR 0002](docs/adr/0002-failure-vocabulary-and-validation.md)). A pointer result is
  `0`, a status is `AMZ_ERR_ALLOC` (−1) or `AMZ_ERR_ARG` (−2), an f64 is NaN. Functions
  that judge their input refuse NaN and ±∞ (ganita ADR 0004's rule). Consumers include
  it after `src/dist.cyr`.
- **`amz_model_converged(m)`**: 1 at a label fixed point, 0 if `max_iter` ran out. The
  model record has 9 slots.
- **`amz_inertia_monotone(history, iters)`**: Lloyd's non-increasing invariant, with a
  relative 1e-9 slack. The demo and the tests use it. It replaces their scale-dependent
  copies, which used an absolute slack of 1.0.
- **A real fuzz harness** (`tests/amuzesh.fcyr`): 10,000 rounds of randomized shapes,
  magnitudes, duplicates, NaN / ±∞, and broken arguments against every public function.
  It decides validity independently of the library and checks invariants on success and
  refusals on failure.
- **Real benchmarks** (`tests/amuzesh.bcyr`, 8 rows), `scripts/bench-history.sh` and
  `bench-history.csv` (the before and after stamps), and `docs/benchmarks.md`.
- **Docs**: `docs/api.md`, `docs/sources.md`, `SECURITY.md`, ADRs 0002–0004, architecture
  note 001 (the heap never frees), and the audit report.
- **CI**: version consistency, fmt `--check`, lint (any warning fails), vet, the M0 gate
  (the demo was built but never run), fuzz, the suite, fuzz and gate on aarch64 under
  qemu, and benchmarks (informational). Also a `.gitattributes` (`lib/** -text`, the
  `cyrius init` template), so a CRLF checkout cannot fail `cyrius deps --verify`.

### Fixed

- **A class with no training rows was predicted**: its zero prototype won queries near
  the origin. Its prototype is now NaN and prediction skips it
  ([ADR 0004](docs/adr/0004-empty-class-has-no-prototype.md)).
- **A fit that ran out of `max_iter` returned labels and inertia for the previous
  centroids** (repro: inertia 528 against 207 for the returned centroids). The final
  update is now skipped, so a model always agrees with itself.
- **The mean of identical rows was not exact** (found by the new fuzz harness). Seven rows
  of 0.1 averaged to 0.09999999999999999, so k-means on duplicated data marched its
  labels for up to k extra passes and its inertia rose from 0. Means are now Welford's
  running mean, which is exact on identical rows and closer to the exact mean in general
  (worst coordinate 1.43 ulp on the fixture, was 2.03).
- **One NaN in the data produced a silently useless model** (NaN inertia, 33% purity). It
  is now refused.
- **Every Lloyd pass leaked its scratch** (592 B per pass at k = d = 8). The fit now
  allocates once.
- **Null model accessors crashed.** They now return 0, −2 or NaN.

### Changed

- **Kernels are 2.2–4.3× faster**, decisions bit-identical. `kmeans_fit` 3.83 → 0.89 ms,
  `kmeans_assign` 813 → 209 µs, `kmeans_pp_seed` 855 → 203 µs, `proto_predict` 801 →
  295 ns (n = 1,024, d = 8, k = 8; median of 3). The speed comes from:
  - direct row access, pinned against `ganita_mat_get` by a test
    ([ADR 0003](docs/adr/0003-direct-row-access.md));
  - partial-distance search in assignment, seeding and prediction;
  - a k-means++ walk that stops at its pick;
  - label buffers swapped instead of copied.
- **`amz_purity` is O(n + k + ncls)**, was O(k·n), and gives bit-identical results:
  57× faster at k = 512.
- Test, bench and fuzz files exit through `SYS_EXIT`, not x86_64's literal `syscall(60)`.
- Suite **123/123** (was 23) on x86_64 and aarch64. It pins exact bit patterns for the
  blobs, seeds, assignment and fit. All 14 audit mutants are killed. Reference coverage is
  21/23 functions (was 15/21). fmt, lint and doc are clean (were 9 warnings and 18
  undocumented functions).

## [0.2.1] - 2026-11-09

### Changed

- **Toolchain `6.7.9` → `6.7.18`** (through 6.7.10–6.7.17), the latest cyrius release. No
  source change. The 6.7.17 refusal of a statement that is only a value builtin
  (`f64_sqrt(x);`) does not reach amuzesh: its only bare call statements are
  `rng_seed(seed);`, a tyche function. `cyrius lib sync --full` re-vendored the 6.7.18 snapshot:
  `lib/` byte-matches it, the same 113 files as 6.7.9, 66 with new content. Nothing was added
  or removed. From 6.7.12, a moved pin makes `cyrius deps` / `cyrius build` exit 1 until that
  sync has run, so the pin, `lib/` and `cyrius.lock` must land in the same commit.
- **`[deps.tyche]` `1.2.0` → `1.2.2`** (latest tag). 1.2.1 only moves tyche to 6.7.18. 1.2.2 is
  tyche's hardening sweep: every state the API can reach gives the same bits as 1.2.1, and a
  hand-written `_rng_state = 0` now steps as state 1 instead of hanging `rng_normal`. amuzesh
  never writes `_rng_state`. `rng_uniform` (the k-means++ draw) is now `#inline`.
- **`[deps.ganita]` held at `1.2.15`** — still ganita's latest tag, and the 6.7.18 snapshot
  bundles the same bytes.
- **`cyrius.lock` regenerated** — 114 files, the two commit pins and the `cyrius 6.7.18`
  trailer; `cyrius deps --verify` is clean. 6.7.18 now names the behavior seen at 0.1.3 and
  0.2.0: it keeps a superseded pin fail-closed (`cyrius.lock keeps tyche@1.2.0's pin … delete
  cyrius.lock to re-pin`). The lock was deleted and regenerated, as before.
- Suite **23/23** and the M0 demo gate pass. The demo output is byte-identical to the 6.7.9
  and 6.6.2 runs. The bench and fuzz stubs pass, `cyrius vet` is clean, and the 6.7.11/12
  lint warnings fire on nothing in `src/`. `tests/amuzesh.tcyr` still has 9 lines over 120
  characters; 6.6.20 and 6.7.9 flag the same 9. The binary grows from 286,560 to 290,160 B.

## [0.2.0] - 2026-11-09

Moves amuzesh onto the cyrius 6.7 series. No source or behavior change.

### Changed

- **Toolchain `6.6.20` → `6.7.9`** (through 6.7.0–6.7.8). No source change. 6.7.0–6.7.9
  reserve `trait`, `const`, `true`, `false`, `do` and `dyn`, make `!` an operator of its own,
  and bind unary `-` / `~` tighter on a constant. amuzesh's source uses none of these; the
  only match is `-D` inside a string literal. `cyrius lib sync --full` re-vendored the
  6.7.9 snapshot: `lib/` byte-matches it, the same 113 files as 6.6.20, 67 with new content.
  Nothing was added or removed. Lint is clean on every `src/` file.
- **`[deps.ganita]` `1.2.14` → `1.2.15`** — the version the 6.7.9 snapshot bundles; the tag's
  `dist/ganita.cyr` is byte-identical to the toolchain's `lib/ganita.cyr`. A toolchain-only
  release: every function, signature and result is 1.2.14's.
- **`[deps.tyche]` `1.1.1` → `1.2.0`** — the tyche release built against 6.7.9. No library or
  API change; tyche's golden dump of the stream is byte-identical to 1.1.1's.
- **`cyrius.lock` regenerated** — 114 files, the two commit pins, and the `cyrius 6.7.9`
  trailer. `cyrius deps --verify` is clean. As at 6.6.20, `cyrius deps` kept the superseded
  `ganita 1.2.14` / `tyche 1.1.1` pins next to the new ones, so the lock was rebuilt from
  scratch.
- Suite **23/23** and the M0 demo gate pass. The demo output is byte-identical to the 6.6.20
  and 6.6.2 runs. The bench and fuzz stubs pass. The binary stays at 286,560 B. Nothing here
  uses `cyrius tests`, which 6.7.6 deprecated and 6.7.12 removes; CI already runs bare
  `cyrius test`.

## [0.1.3] - 2026-11-09

### Changed

- **Toolchain `6.6.2` → `6.6.20`.** No source change. `cyrius lib sync --full` re-vendored
  the whole 6.6.20 snapshot: `lib/` now byte-matches it (113 files), clearing the 12-module
  `./lib/ shadows version-pinned` warning that the 6.6.2 bump had left in place. New in the
  snapshot: `alloc_cx`, `boxed`, `hashseed`, `poison`, `tls_hostid`. Nothing was dropped, so
  there was nothing to prune.
- **`[deps.ganita]` `1.1.0` → `1.2.14`** — the version the 6.6.20 snapshot bundles; the tag's
  `dist/ganita.cyr` is byte-identical to the toolchain's `lib/ganita.cyr`. No public signature
  changed across 1.2.x. amuzesh calls only `ganita_mat_new` / `_get` / `_set`.
- **`[deps.tyche]` `1.0.1` → `1.1.1`** — the tyche release built against 6.6.20. `rng_seed`,
  `rng_u64` and `rng_uniform` (the k-means++ draw) are bit-identical. 1.1.0's portable-log
  `rng_normal` moves 0.011% of x86_64 draws by 1–3 ulp; it feeds only the blob generator's
  jitter, and the demo output is byte-identical to the 6.6.2 run.
- **`cyrius.lock` regenerated** — 114 files plus the two commit pins, and
  `cyrius deps --verify` is clean. Neither `cyrius deps` nor `cyrius deps --relock` prunes a
  superseded commit pin, so the lock was rebuilt from scratch. Otherwise it would have kept
  the dead `ganita 1.1.0` / `tyche 1.0.1` lines next to the new ones.
- Suite **23/23** and the M0 demo gate pass, both unchanged; the bench and fuzz stubs pass.
  Bare `cyrius test` now reports `2 passed`: it counts the `[build].test` stub
  (`src/test.cyr`) along with `tests/amuzesh.tcyr`. The binary grows from 146,928 to
  286,560 B, almost all of it from ganita 1.2.14's larger bundle (52 KB → 238 KB of source),
  most of which is unreachable here (DCE off).

## [0.1.2] - 2026-09-11

### Changed

- **Toolchain `6.5.27` → `6.6.2`.** No source change; the value form needed none.
  Build, tests, and any bench/fuzz/distlib target the repo ships re-verified at the new pin.


## [0.1.1] - 2026-08-17

### Changed

- **Cyrius pin `6.2.44` -> `6.5.27`** (2026-08-17, ecosystem-wide ML/AI-arc realign ahead of
  the arc reopening). `cyrius lib sync --full` re-vendored the whole version-matched stdlib
  snapshot, clearing the toolchain-drift and `./lib/ shadows version-pinned` warnings.
  Suite **23/23**, identical to the pre-bump baseline. Cleared a 3-module shadow warning (patra / mabda / sankoch).
- **`[deps.tyche]` `0.1.1` -> `1.0.1`** and **`[deps.ganita]` `1.0.1` -> `1.1.0`** — part of the
  ecosystem-wide substrate-freeze propagation. amuzesh builds its D²-weighted k-means++ draw on
  `rng_uniform()`, which is inside tyche's frozen 1.x surface, so this is a tag realign with no
  behavior change. Verified the bumps took rather than merely built — vendored `lib/tyche.cyr`
  now reads `# Version: 1.0.1` and `lib/ganita.cyr` reads `1.1.0`. Suite **23/23**, unchanged.

## [0.1.0] - 2026-06-27

**M0 — the classical/shallow-ML floor: k-means + k-means++ + nearest-centroid prototype
classifier.** amuzesh is the AGNOS ML family's first **non-deep-learning** sibling — built ON the
substrate (ganita matrices, tyche PRNG), the novelty budget spent only on the model logic. No
finite-difference gradient gate (these are not gradient methods); correctness is convergence +
coverage + analytic means + held-out accuracy instead.

### Added
- **k-means (Lloyd)** — `src/kmeans.cyr`. Assignment (argmin squared-euclidean → labels + inertia),
  centroid update (per-cluster mean; an **empty cluster keeps its prior centroid**, no NaN), and the
  `amz_kmeans_fit` driver that iterates assign↔update to a **label fixed point** or `max_iter`.
  Inertia is recorded after each assign, so the history is directly checkable for the Lloyd
  non-increasing invariant. A fitted model is a flat 8-slot record with accessors.
- **k-means++ seeding** — `src/kmeans.cyr` `amz_kmeans_pp_seed`. Arthur & Vassilvitskii (2007)
  D²-weighted seeding via an inverse-CDF walk over `rng_uniform` (tyche has no weighted sampler, so
  this is the one new primitive permitted).
- **Nearest-centroid prototype classifier** — `src/proto.cyr`. Per-class mean prototype + classify
  by nearest prototype (Rocchio / nearest-mean; = LDA under equal isotropic covariance), plus an
  accuracy helper.
- **Distance helper + synthetic fixtures** — `src/dist.cyr` (`amz_sqdist`/`amz_copy_row` over the
  public `ganita_mat_get`, no header-layout assumption); `src/data.cyr` `amz_make_blobs` (separable
  Gaussian blobs); `amz_purity` (permutation-invariant cluster purity).
- **Demo** — `src/main.cyr`: three separable 2-D blobs → k-means++ converges in 2 iterations with a
  monotone inertia trace, **cluster purity 100%**, **prototype accuracy 100%** (M0 gate pass).
- **Unit suite** — `tests/amuzesh.tcyr`, **23/23**: sqdist properties; k-means++ reproducibility +
  distinct-blob spread; analytic assign labels / inertia / centroid means / empty-cluster retention;
  fit monotone-inertia + fixed-point + reproducibility + purity; prototype analytic means / predict /
  2- and 3-class accuracy / determinism.

Built on [ganita](https://github.com/MacCracken/ganita) 1.0.1 + [tyche](https://github.com/MacCracken/tyche)
0.1.1. Toolchain pin: cyrius 6.2.44.
