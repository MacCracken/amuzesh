# amuzesh — Current State

> Refreshed every release. CLAUDE.md is preferences/process/procedures
> (durable); this file is **state** (volatile).

## Version

**0.2.2** — 2026-11-09: the P(-1) audit / hardening / optimization sweep ([`../audit/2026-11-09-audit.md`](../audit/2026-11-09-audit.md)). M0 shipped in 0.1.0 (2026-06-27).

## Toolchain

- **Cyrius pin**: `6.7.18` (in `cyrius.cyml [package].cyrius`)

**Pin bumped to `6.7.18` 2026-11-09** (from `6.7.9`, 0.2.1; unchanged at 0.2.2). `cyrius lib sync --full` re-vendored the whole 6.7.18 snapshot; `lib/` byte-matches it (113 files) and builds with no shadow warning. Suite re-verified green at the new pin.

Bump procedure: set the pin, then `cyrius lib sync --full` (from 6.7.12 `cyrius deps` exits 1 until it runs). Delete `cyrius.lock` and run `cyrius deps`; the lock keeps a superseded commit pin fail-closed otherwise. Commit the pin, `lib/` and `cyrius.lock` together.

## Source

M0, the classical / shallow-ML floor. Public surface: [`../api.md`](../api.md).

- `src/dist.cyr` — row access (ADR 0003), squared distance + partial-distance search, running means (unchecked kernels)
- `src/check.cyr` — argument validation and the failure vocabulary (ADR 0002)
- `src/kmeans.cyr` — k-means++ seeding, Lloyd iteration, the fit and its model, inertia monotonicity, cluster purity
- `src/proto.cyr` — nearest-centroid prototype classifier (empty class = NaN prototype, ADR 0004)
- `src/data.cyr` — separable Gaussian blob fixtures
- `src/main.cyr` — M0 demo / gate (PASS; CI runs it on x86_64 and aarch64)

## Tests

- `tests/amuzesh.tcyr` — primary suite, **123/123** (bit-exact known answers, the refusal contract, a regression per audit finding); x86_64 and aarch64
- `tests/amuzesh.fcyr` — fuzz harness, 10,000 randomized rounds against the whole public surface, 0 violations
- `tests/amuzesh.bcyr` — 8 benchmark rows; history in `bench-history.csv` (`scripts/bench-history.sh`), table in [`../benchmarks.md`](../benchmarks.md)
- Reference coverage 21/23 functions (the two unreferenced are the demo's own); mutation testing 14/14 killed (2026-11-09)

## Benchmarks (0.2.2, n = 1,024, d = 8, k = 8)

`kmeans_fit` 0.89 ms (0.2.1: 3.83 ms) · `kmeans_assign` 209 µs · `kmeans_pp_seed` 203 µs · `kmeans_update` 46 µs · `proto_fit` 62 µs · `proto_predict` 295 ns · `sqdist` 38 ns · `purity` 11.6 µs

## Dependencies

Direct (declared in `cyrius.cyml`):

- stdlib — string, fmt, alloc, io, vec, str, syscalls, assert, bench, math
- [ganita](https://github.com/MacCracken/ganita) `1.2.15` — matrix storage (latest tag; the version 6.7.18 bundles)
- [tyche](https://github.com/MacCracken/tyche) `1.2.2` — deterministic PRNG (latest tag)

## Consumers

_None yet._

## Next

**0.3.x**: the consumable `dist/amuzesh.cyr` bundle (no gate). Then the first consumer
(0.4.x, gated on a pull), the freeze candidate (0.5.x) and 1.0.0. Of the v1.0 criteria,
only the consumer and the freeze remain. See [`roadmap.md`](roadmap.md).
