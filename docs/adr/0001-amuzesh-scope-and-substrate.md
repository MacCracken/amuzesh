# 0001 — amuzesh scope and substrate

**Status**: Accepted
**Date**: 2026-06-27

## Context

The AGNOS sovereign-ML family had, by mid-2026, four references — attn11 (transformer / SFT),
tarka (RL / reasoning), tentib (integer-native / ternary), prajna (meta-learning) — all on the
shared `rosnet`/`tyche`/`akshara` f64 substrate, and all **deep-learning**: a neural net trained
by gradient descent, every hand-derived backward finite-difference-gated. The 2026-06-25
ifran/secureyeoman product-mining (`agnosticos/docs/development/planning/ml-product-mining.md`)
surfaced one genuinely orthogonal gap: classical / shallow ML (clustering, GLMs, trees, filters).
The user named the lane **amuzesh** (Persian *learning*) and mapped it in
`agnosticos/docs/development/planning/classical-shallow-ml.md`, then authorized scaffolding the
first cut (M0 = k-means + nearest-centroid prototype classifier).

The forces: (1) the sovereignty argument here is *trust and smallness*, not capability — on tabular
telemetry a gradient-boosted tree or a Kalman filter beats a deep net with an auditable,
integer-friendly decision path; (2) the genuinely-new content is small (assignment, split search,
filter recurrences) and stands on already-shipped numeric libs; (3) the family's universal
finite-difference verifier does **not** apply, because most of these methods have no gradient.

## Decision

amuzesh is the **classical / shallow-ML reference** of the AGNOS family — the first non-deep-learning
sibling. It is built **on the substrate** (ganita for matrix storage/access, tyche for the PRNG); it
reimplements no linear algebra and no PRNG, spending its novelty budget only on model-specific logic.

It carries **no finite-difference gradient gate**. Each mechanism is verified the honest way for its
kind: **convergence** (monotone inertia, fixed-point labels) and **coverage** (cluster purity) for
k-means; exact **analytic means** and held-out **accuracy** for the prototype classifier; FD-gates
only where a real gradient exists (logistic-IRLS, GBDT leaves) in later milestones.

**In scope (the lane):** k-means(++), prototype/nearest-centroid, logistic regression (IRLS), GLM /
ridge / PCA (thin over ganita), gradient-boosted trees (the auditable phylax/aegis form), Kalman /
HMM filters, naive Bayes. **M0 ships:** k-means + k-means++ + the prototype classifier.

**Out of scope:** anything gradient-based / neural (that is attn11 / tarka / tentib / prajna); GPU
(CPU f64 only — mabda is a later accelerator concern); reimplementing the substrate.

## Consequences

- **Positive** — fills the one orthogonal gap in the ML axis-map; gives phylax/aegis a path to an
  *auditable* model (a defensible split path, not an unexplainable logit); tiny, integer-friendly,
  aligned with the metal-up discipline; near-zero new numeric code (stands on ganita/tyche).
- **Negative** — a second verification discipline to maintain (convergence/coverage/accuracy
  alongside the family's FD-gate); the lane is genuine but *unhurried* (mined demand is weak), so it
  must resist over-building ahead of real consumers.
- **Neutral** — later mechanisms (GBDT, Kalman) are research-watch; each becomes a shipped library
  only when a **second** consumer needs it (the emergent-extraction trigger), so the repo grows by
  pull, not push.

## Alternatives considered

- **Fold classical ML into an existing sibling** — rejected: it is orthogonal to all four (they are
  all deep-learning axes); there is no natural home, and forcing it into one would muddy that
  sibling's charter.
- **A new numeric library instead of a reference** — rejected for M0: ganita/hisab/abaco already
  supply the numerics; amuzesh's value is the *model logic*, so it is a reference binary (with a
  consumable surface) like its siblings, not a from-scratch math lib.
- **Inherit the finite-difference gate as the universal verifier** — rejected: most classical methods
  have no gradient; a convergence/coverage/accuracy regime is the honest test, and pretending
  otherwise would be verification theater.
- **Scaffold the whole lane now** — rejected: the emergent-extraction discipline (a mechanism becomes
  a lib when a second consumer needs it) applies; M0 ships the smallest genuinely-new core and the
  rest waits for pull.
