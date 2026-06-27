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

## M0 (v0.1.0)

- **k-means** — Lloyd iteration (assign / centroid-update / inertia), empty-cluster retention.
- **k-means++** — D²-weighted seeding (an inverse-CDF walk over `rng_uniform`, since tyche has no
  weighted sampler).
- **nearest-centroid prototype classifier** — per-class mean + classify-by-nearest (Rocchio /
  nearest-mean; equivalent to LDA under equal isotropic covariance).

Demo (`src/main.cyr`) on three separable 2-D Gaussian blobs: k-means++ converges in 2 iterations
with a non-increasing inertia trace, **cluster purity 100%**, **prototype accuracy 100%**. The unit
suite (`tests/amuzesh.tcyr`) is **23/23 green**.

## Build

```sh
cyrius deps                                 # resolve ganita / tyche / stdlib
cyrius build src/main.cyr build/amuzesh     # compile the demo
./build/amuzesh
cyrius test                                 # run the unit suite (tests/amuzesh.tcyr)
```

## Roadmap

M0 (k-means + prototype classifier) is the floor. Further classical mechanisms — logistic
regression (IRLS), GLM / ridge / PCA (thin over ganita), gradient-boosted trees (the *auditable*
phylax/aegis form), Kalman / HMM filters, naive Bayes — are mapped in the AGNOS planning doc
`classical-shallow-ml.md` and land per the emergent-extraction discipline (a mechanism becomes a
shipped lib when a second consumer needs it).

## License

GPL-3.0-only
