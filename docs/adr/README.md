# Architecture Decision Records

Decisions about amuzesh — what we chose, the context, and the consequences we accept. Use these when a future reader would reasonably ask *"why did we do it this way?"*

## Conventions

- **Filename**: `NNNN-kebab-case-title.md`, zero-padded to four digits. Never renumber.
- **One decision per ADR.** If a decision supersedes a prior one, add a new ADR and set the old one's status to `Superseded by NNNN`.
- **Status lifecycle**: `Proposed` → `Accepted` → (optionally) `Superseded` or `Deprecated`.
- Use [`template.md`](template.md) as the starting point.

## ADR vs. architecture note vs. guide

| Kind | Lives in | Answers |
|---|---|---|
| ADR | `docs/adr/` | *Why did we choose X over Y?* |
| Architecture note | `docs/architecture/` | *What non-obvious constraint is true about the code?* |
| Guide | `docs/guides/` | *How do I do X?* |

## Index

| ADR | Title | Status |
|---|---|---|
| [0001](0001-amuzesh-scope-and-substrate.md) | amuzesh scope and substrate | Accepted |
| [0002](0002-failure-vocabulary-and-validation.md) | Validate every public entry point, and fail in ganita's vocabulary | Accepted |
| [0003](0003-direct-row-access.md) | Read ganita rows through one row-address helper, pinned by a test | Accepted |
| [0004](0004-empty-class-has-no-prototype.md) | A class with no training rows has no prototype | Accepted |
