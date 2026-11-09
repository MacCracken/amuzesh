# Getting started with amuzesh

## Build

```sh
cyrius deps                              # resolve dependencies
cyrius build src/main.cyr build/amuzesh    # compile
cyrius test                              # run [build].test + tests/*.tcyr
```

## Layout

- `src/main.cyr` — entry point. Top-level `var r = main(); syscall(SYS_EXIT, r);`.
- `src/test.cyr` — top-level test entry referenced by `cyrius.cyml [build].test`. Add unit cases here or in `tests/amuzesh.tcyr`.
- `tests/amuzesh.tcyr` — primary test suite (`cyrius test` auto-discovers).
- `tests/amuzesh.bcyr` — benchmarks (`CYRIUS_DCE=1 cyrius bench tests/amuzesh.bcyr`; `scripts/bench-history.sh` records a median-of-3 stamp).
- `tests/amuzesh.fcyr` — fuzz harness (`cyrius fuzz`).
- `src/dist.cyr`, `src/check.cyr`, `src/kmeans.cyr`, `src/proto.cyr`, `src/data.cyr` — the library, included in that order after `lib/ganita.cyr` and `lib/tyche.cyr` (see [`../api.md`](../api.md)).

## Adding a feature

1. Edit `src/main.cyr` (or add a new module and `include` it).
2. Validate every argument of a new public function in `src/check.cyr`'s vocabulary ([ADR 0002](../adr/0002-failure-vocabulary-and-validation.md)), and keep inner loops on the unchecked `src/dist.cyr` kernels.
3. Add a test case to `tests/amuzesh.tcyr`, including its refusals, and a fuzz case to `tests/amuzesh.fcyr`.
4. Run `cyrius test`, then fmt / lint / vet (CI gates all three).
5. Bump `VERSION` and add a CHANGELOG entry before tagging.

See [`../adr/template.md`](../adr/template.md) when a non-trivial design choice deserves an ADR.
