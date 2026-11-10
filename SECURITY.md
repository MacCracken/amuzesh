# Security policy

## Reporting

Report a vulnerability privately to the maintainer through GitHub's *Report a
vulnerability* (security advisories) on
[MacCracken/amuzesh](https://github.com/MacCracken/amuzesh), not in a public issue.
Include a reproduction: the call, its arguments, and what happened.

## Supported versions

amuzesh is 0.x. Only the latest release receives fixes.

## Threat model

amuzesh is a library of numeric model code: k-means, k-means++ and a nearest-centroid
classifier. It does no I/O, opens no files or sockets, starts no processes, and
parses nothing. Its inputs are the matrices, label arrays and integers a caller passes.
Those inputs may come from untrusted data (a training set, a label file), so amuzesh
treats them as untrusted.

**What amuzesh guarantees** (since 0.2.2,
[ADR 0002](docs/adr/0002-failure-vocabulary-and-validation.md)): every public function
validates its arguments before it writes anything:
- null matrices, shapes, and every count and index range;
- every label against its range;
- every allocation size against overflow;
- NaN and ±∞ in the data, for functions that judge it.

Bad input is refused (0, −1 / −2, or NaN), never turned into an out-of-bounds read or
write, a division by zero, or a silently wrong model. A fuzz harness checks this contract
on every CI run (`tests/amuzesh.fcyr`, 10,000 randomized rounds, x86_64 and aarch64).

**What amuzesh cannot check**:

- **The length of a raw label array.** It carries none, so amuzesh reads the `n` entries
  the caller says it has. A shorter array is the caller's out-of-bounds read.
- **The unchecked kernels.** `amz_sqdist`, `amz_copy_row` and every `_amz_*` function
  index without checks, by design, like `ganita_mat_get`. Use the validating entry points
  with untrusted input.
- **A matrix pointer that is not a ganita matrix.** amuzesh reads its header.
- **Memory exhaustion by volume.** Each call's allocation is bounded, but the heap never
  frees, so an unbounded number of calls grows the process without bound
  ([architecture 001](docs/architecture/001-the-heap-never-frees.md)).
- **Concurrency.** Fitting reseeds tyche's single global PRNG stream. Nothing here is
  safe to call from more than one thread at a time.

**Not a security boundary**: model output. A clustering or a classification is a
statistical answer about the data it was given, and data chosen by an adversary steers
it. Sandboxing belongs to the platform (kavach), not to this library.

## Audits

[`docs/audit/`](docs/audit/). Latest: [2026-11-09, 0.3.0](docs/audit/2026-11-09-v0.3.0-audit.md); the full sweep: [2026-11-09, 0.2.2](docs/audit/2026-11-09-audit.md).
