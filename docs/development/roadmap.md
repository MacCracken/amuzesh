# amuzesh — Roadmap

> Milestone plan through v1.0. State lives in [`state.md`](state.md);
> this file is the sequencing — what ships, in what order, against
> what dependency gates.

## v1.0 criteria

_Define before tagging v0.1.0:_

- [ ] Public API frozen — every exported symbol documented and tested
- [ ] Test coverage adequate for the surface area
- [ ] Benchmarks captured in `docs/benchmarks.md`
- [ ] At least one downstream consumer green
- [ ] CHANGELOG complete from v0.1.0 onward
- [ ] Security audit pass (`docs/audit/YYYY-MM-DD-audit.md`)

## Milestones

### M0 — k-means + k-means++ + nearest-centroid prototype classifier (v0.1.0) — ✅ shipped 2026-06-27

- `cyrius init` scaffold, doc-tree per [first-party-documentation.md](https://github.com/MacCracken/agnosticos/blob/main/docs/development/applications/first-party-documentation.md)
- k-means (Lloyd) with k-means++ seeding, the nearest-centroid classifier, cluster purity; the M0 demo gate
- **P(-1) sweep — ✅ 0.2.2, 2026-11-09** ([audit](../audit/2026-11-09-audit.md)): validated public surface (ADR 0002), the empty-class and budget-exhaustion repairs, the running mean, 2.2–4.3× faster kernels, fuzz + mutation-tested suite

### M1 — _Title_ (v0.2.0)

_Replace this with the first real milestone. Specify the user-visible change, the dep gates, and the acceptance criteria._

### M2 — _Title_ (v0.3.0)

_…_

## Out of scope (for v1.0)

_Capture what's deliberately NOT in scope for v1.0. The list keeps future contributors from adding to v1.0 by accident._

- _e.g. Windows support, GUI front-end, etc._
