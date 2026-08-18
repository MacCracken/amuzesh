# amuzesh — Current State

> Refreshed every release. CLAUDE.md is preferences/process/procedures
> (durable); this file is **state** (volatile).

## Version

**0.1.0** — scaffolded 2026-06-27 via `cyrius init`. No releases yet.

## Toolchain

- **Cyrius pin**: `6.5.27` (in `cyrius.cyml [package].cyrius`)

**Pin bumped to `6.5.27` 2026-08-17** (ecosystem-wide ML/AI-arc realign, ahead of the arc reopening). `cyrius lib sync --full` re-vendored the whole version-matched stdlib snapshot; suite re-verified green at the new pin.

## Source

Initial scaffold only.

## Tests

- `tests/amuzesh.tcyr` — primary suite (smoke + math; passes on `cyrius test`)
- `tests/amuzesh.bcyr` — benchmark stub (no-op)
- `tests/amuzesh.fcyr` — fuzz stub

## Dependencies

Direct (declared in `cyrius.cyml`):

- stdlib — string, fmt, alloc, io, vec, str, syscalls, assert

## Consumers

_None yet._

## Next

See [`roadmap.md`](roadmap.md).
