# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

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
