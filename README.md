# amuzesh

**amuzesh** (Persian آموزش — *learning / education / training*) is the AGNOS ML family's
first **classical / shallow-machine-learning** reference, written in
[Cyrius](https://github.com/MacCracken/cyrius). It is the **first non-deep-learning sibling**
alongside attn11 (transformer), tarka (RL/reasoning), tentib (ternary), and prajna (meta-learning):
where those prove *gradient-based* learning is expressible assembly-up in an everything-is-i64
systems language, amuzesh proves the model whose cost and behavior you can fully account for is
often **not** a neural net — k-means, prototype classifiers, GLMs, trees, filters.

It is built **on the substrate**, not from scratch: matrix storage / access from
[ganita](https://github.com/MacCracken/ganita), the PRNG from
[tyche](https://github.com/MacCracken/tyche). The novelty budget is spent only on the model logic.

> **No finite-difference gradient gate.** Unlike the deep-learning siblings, amuzesh's methods are
> not gradient-based, so correctness is proven the honest way for each: **convergence** (monotone
> inertia + fixed-point labels), **coverage** (cluster purity), exact **analytic means**, and
> held-out **accuracy** on separable sets.

## M0 (v0.1.0; hardened at 0.2.2)

- **k-means** — Lloyd iteration (assign / centroid-update / inertia), empty-cluster retention,
  and a model that always agrees with itself and says whether it converged.
- **k-means++** — D²-weighted seeding (an inverse-CDF walk over `rng_uniform`, since tyche has no
  weighted sampler).
- **nearest-centroid prototype classifier** — per-class mean + classify-by-nearest (Rocchio /
  nearest-mean; equivalent to LDA under equal isotropic covariance). A class with no training
  rows has no prototype and is never predicted.

Demo (`src/main.cyr`) on three separable 2-D Gaussian blobs: k-means++ converges in 2 iterations
with a non-increasing inertia trace, **cluster purity 100%**, **prototype accuracy 100%**. The unit
suite (`tests/amuzesh.tcyr`) is **123/123 green** on x86_64 and aarch64. It pins exact bit
patterns, the refusal contract and a regression per audit finding. A 10,000-round fuzz harness
(`tests/amuzesh.fcyr`) checks the whole public surface against hostile input.

**Contract.** Every public function validates its input (shapes, ranges, labels, NaN / ±∞) and
fails the way ganita does: `0` for a pointer, `-1` / `-2` for a status, NaN for an f64
([ADR 0002](docs/adr/0002-failure-vocabulary-and-validation.md)). The API reference is
[`docs/api.md`](docs/api.md), and the threat model is [`SECURITY.md`](SECURITY.md).

## Build

```sh
cyrius deps                                 # resolve ganita / tyche / stdlib
cyrius build src/main.cyr build/amuzesh     # compile the demo
./build/amuzesh
cyrius test                                 # run the unit suite (tests/amuzesh.tcyr)
CYRIUS_DCE=1 cyrius bench tests/amuzesh.bcyr  # benchmarks (scripts/bench-history.sh records them)
```

A consumer includes `lib/ganita.cyr`, `lib/tyche.cyr`, then `src/dist.cyr`, `src/check.cyr`,
`src/kmeans.cyr`, `src/proto.cyr` (and `src/data.cyr` for the fixtures), in that order.

## Documentation

- [`docs/api.md`](docs/api.md) — the public surface and its contract
- [`docs/adr/`](docs/adr/) — decisions; [`docs/architecture/`](docs/architecture/) — constraints
- [`docs/benchmarks.md`](docs/benchmarks.md) · [`docs/sources.md`](docs/sources.md) — performance, citations
- [`docs/audit/`](docs/audit/) — audit reports (latest: 2026-11-09, the P(-1) sweep)

## Roadmap

[`docs/development/roadmap.md`](docs/development/roadmap.md): **0.3.x** a consumable
`dist/amuzesh.cyr` bundle, **0.4.x** the first downstream consumer green, **0.5.x** the
API review and the pre-freeze audit, **1.0.0** the freeze. Further classical mechanisms —
linear / ridge, PCA, logistic regression (IRLS), naive Bayes, Kalman / HMM filters,
gradient-boosted trees (the *auditable* phylax/aegis form) — are in its v1 backlog, mapped
in the AGNOS planning doc `classical-shallow-ml.md`. Each lands when a consumer pulls it,
and becomes a shipped lib only when a second consumer needs it.

## License

GPL-3.0-only
