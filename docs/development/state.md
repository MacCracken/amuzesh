# amuzesh — Current State

> Refreshed every release. CLAUDE.md is preferences/process/procedures
> (durable); this file is **state** (volatile).

## Version

**0.2.1** — 2026-11-09 (6.7.18 bump; deps at their latest tags). M0 shipped in 0.1.0 (2026-06-27).

## Toolchain

- **Cyrius pin**: `6.7.18` (in `cyrius.cyml [package].cyrius`)

**Pin bumped to `6.7.18` 2026-11-09** (from `6.7.9`, 0.2.0). `cyrius lib sync --full` re-vendored the whole 6.7.18 snapshot; `lib/` byte-matches it (113 files) and builds with no shadow warning. Suite re-verified green at the new pin.

Bump procedure: set the pin, then `cyrius lib sync --full` (from 6.7.12 `cyrius deps` exits 1 until it runs). Delete `cyrius.lock` and run `cyrius deps`; the lock keeps a superseded commit pin fail-closed otherwise. Commit the pin, `lib/` and `cyrius.lock` together.

## Source

M0, the classical / shallow-ML floor:

- `src/kmeans.cyr` — Lloyd k-means + k-means++ seeding
- `src/proto.cyr` — nearest-centroid prototype classifier
- `src/dist.cyr` — squared-euclidean distance / row copy over ganita
- `src/data.cyr` — separable Gaussian blob fixtures + cluster purity
- `src/main.cyr` — M0 demo / gate

## Tests

- `tests/amuzesh.tcyr` — primary suite, **23/23** (passes on `cyrius test`)
- `tests/amuzesh.bcyr` — benchmark stub (no-op)
- `tests/amuzesh.fcyr` — fuzz stub

## Dependencies

Direct (declared in `cyrius.cyml`):

- stdlib — string, fmt, alloc, io, vec, str, syscalls, assert, bench, math
- [ganita](https://github.com/MacCracken/ganita) `1.2.15` — matrix storage (latest tag; the version 6.7.18 bundles)
- [tyche](https://github.com/MacCracken/tyche) `1.2.2` — deterministic PRNG (latest tag)

## Consumers

_None yet._

## Next

See [`roadmap.md`](roadmap.md).
