# 0003 — Read ganita rows through one row-address helper, pinned by a test

**Status**: Accepted
**Date**: 2026-11-09

## Context

Through 0.2.1, `src/dist.cyr` read every matrix element through `ganita_mat_get`, on
purpose ("no header-layout assumption"). Every inner loop in amuzesh is a squared
distance or a running mean over a row, so the hot path paid two calls per element.
cyrius does not inline `ganita_mat_get`, because its body declares a `var`. The 0.2.2
measurements, at d = 8 on one host in one session:

| | per `amz_sqdist` |
|---|---|
| `ganita_mat_get` per element (0.2.1) | 102 ns |
| one row address, then `load64` | 37 ns |

The two give bit-identical results; the loads are the same.

ganita documents its matrix layout in its matrix header
(`{ rows: i64, cols: i64, data: f64[rows*cols] }`, row-major), and documents
`ganita_mat_get` as reading `m + 16 + (r*cols + c)*8`. ganita's 1.x surface is frozen,
and the layout has not changed since 1.0. It is not in ganita's API reference, though,
so relying on it is a dependency on something ganita has described but not promised.

## Decision

**amuzesh computes row addresses itself, in exactly one place, `_amz_row(m, r)` in
`src/dist.cyr`, and pins it against `ganita_mat_get` in the unit suite.**

- `_amz_row` is `m + 16 + r * cols(m) * 8`: `ganita_mat_get`'s documented address with
  c = 0. It is `#inline`. Every kernel walks a row from that address.
- `tests/amuzesh.tcyr`'s first group fills a non-square 3×5 matrix through
  `ganita_mat_set` and checks every element read through `_amz_row` against
  `ganita_mat_get`. If ganita ever moves the header or changes the stride, the suite
  fails before anything reads the wrong memory. Mutation testing confirms it: a stride
  taken from `rows` instead of `cols` fails the pin.
- Nothing else in amuzesh may form a matrix address.

## Consequences

- **Positive.** The kernels run 2.6–4.3× faster, together with partial-distance search
  and the hoisted validation (see `docs/benchmarks.md`), with no change to any result.
- **Negative.** amuzesh now depends on ganita's storage layout, not just its API. A
  ganita release that changes the layout breaks amuzesh's build gate. Detection is
  immediate, but the repair is real work.
- **Neutral.** If ganita later exports a row or data accessor, `_amz_row` becomes a call
  to it and this ADR is superseded.

## Alternatives considered

- **Keep `ganita_mat_get`.** Rejected: it is the largest single cost in every kernel,
  and the layout it hides is already documented next to it.
- **Copy rows into amuzesh-owned buffers.** Rejected: it adds a copy per row per pass,
  and an allocation the never-freeing heap cannot give back.
- **Ask ganita for an accessor first.** Worth doing, and noted in the audit. But 0.2.2
  should not wait on a substrate release, and the pin test makes the interim safe.
