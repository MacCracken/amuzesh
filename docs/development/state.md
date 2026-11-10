# amuzesh — Current State

> Refreshed every release. CLAUDE.md is preferences/process/procedures
> (durable); this file is **state** (volatile).

## Version

**0.3.0** — 2026-11-09: a consumable library, `dist/amuzesh.cyr` ([`../audit/2026-11-09-v0.3.0-audit.md`](../audit/2026-11-09-v0.3.0-audit.md)). 0.2.2 was the P(-1) sweep ([`../audit/2026-11-09-audit.md`](../audit/2026-11-09-audit.md)); M0 shipped in 0.1.0 (2026-06-27).

## Toolchain

- **Cyrius pin**: `6.7.18` (in `cyrius.cyml [package].cyrius`)

**Pin bumped to `6.7.18` 2026-11-09** (from `6.7.9`, 0.2.1; unchanged since). `cyrius lib sync --full` re-vendored the whole 6.7.18 snapshot; `lib/` byte-matches it (113 files) and builds with no shadow warning. Suite re-verified green at the new pin.

Bump procedure: set the pin, then `cyrius lib sync --full` (from 6.7.12 `cyrius deps` exits 1 until it runs). Delete `cyrius.lock` and run `cyrius deps`; the lock keeps a superseded commit pin fail-closed otherwise. Commit the pin, `lib/` and `cyrius.lock` together.

## Source

M0, the classical / shallow-ML floor. Public surface: [`../api.md`](../api.md).

- `src/dist.cyr` — row access (ADR 0003), squared distance + partial-distance search, running means (unchecked kernels)
- `src/check.cyr` — argument validation and the failure vocabulary (ADR 0002)
- `src/kmeans.cyr` — k-means++ seeding, Lloyd iteration, the fit and its model, inertia monotonicity, cluster purity
- `src/proto.cyr` — nearest-centroid prototype classifier (empty class = NaN prototype, ADR 0004)
- `src/data.cyr` — separable Gaussian blob fixtures
- `src/main.cyr` — M0 demo / gate (PASS; CI runs it on x86_64 and aarch64)

## Distribution

- `dist/amuzesh.cyr` — the bundle consumers import (`[lib] modules`, `cyrius distlib`); `# Requires` `lib/alloc.cyr`. Consumers also declare ganita and tyche.
- `dist/amuzesh.deps` — stdlib sidecar: `alloc`
- CI: `cyrius distlib --check` (bundle current) and `scripts/consumer-check.sh` (raw include `--no-deps`, suite + fuzz against the bundle). Releases ship the bundle and sidecar as assets.

## Tests

- `tests/amuzesh.tcyr` — primary suite, **123/123** (bit-exact known answers, the refusal contract, a regression per audit finding); x86_64 and aarch64; also passes against the bundle
- `tests/amuzesh_raw_include.tcyr` — the bundle from a raw include, **5/5** (CI also builds it `--no-deps`)
- `tests/amuzesh.fcyr` — fuzz harness, 10,000 randomized rounds against the whole public surface, 0 violations
- `tests/amuzesh.bcyr` — 8 benchmark rows; history in `bench-history.csv` (`scripts/bench-history.sh`), table in [`../benchmarks.md`](../benchmarks.md)
- Reference coverage 21/23 functions (the two unreferenced are the demo's own); mutation testing 14/14 killed (2026-11-09)

## Benchmarks (0.3.0, n = 1,024, d = 8, k = 8)

`kmeans_fit` 0.87 ms (0.2.1: 3.83 ms) · `kmeans_assign` 204 µs · `kmeans_pp_seed` 198 µs · `kmeans_update` 44 µs · `proto_fit` 60 µs · `proto_predict` 291 ns · `sqdist` 36 ns · `purity` 11.3 µs. Unchanged from 0.2.2 within noise.

## Dependencies

Direct (declared in `cyrius.cyml`):

- stdlib — string, fmt, alloc, io, vec, str, syscalls, assert, bench, math
- [ganita](https://github.com/MacCracken/ganita) `1.2.15` — matrix storage (latest tag; the version 6.7.18 bundles)
- [tyche](https://github.com/MacCracken/tyche) `1.2.2` — deterministic PRNG (latest tag)

## Consumers

_None yet._

## Next

**0.4.x**: the first downstream consumer green, gated on a consumer pulling (none depends
on amuzesh yet). Then the freeze candidate (0.5.x) and 1.0.0. Of the v1.0 criteria, only
the consumer and the freeze remain. See [`roadmap.md`](roadmap.md).
