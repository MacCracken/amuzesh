# 0004 — A class with no training rows has no prototype

**Status**: Accepted
**Date**: 2026-11-09

## Context

`amz_proto_fit` builds one prototype per class, the mean of that class's training rows.
Through 0.2.1 a class with no rows kept the zero vector, with the comment "never
selected on real data". That is false. A zero prototype sits at the origin, and real
features are very often centered or standardized. The audit reproduced it: with class 0
at {5, 7}, class 2 at {−7, −5} and class 1 empty, the query x = 1 was classified as
**class 1**, a class the classifier was never shown.

The mean of an empty set does not exist, so any finite value written there is invented.

## Decision

**An empty class's prototype row is NaN, and prediction never selects a class whose
distance is NaN.**

- `amz_proto_fit` writes NaN into every coordinate of an empty class's row. NaN is
  already amuzesh's f64 "no answer" value
  ([ADR 0002](0002-failure-vocabulary-and-validation.md)).
- Prediction takes the argmin over classes whose squared distance is not NaN, with ties
  to the lowest index. Queries are validated finite, so for prototypes built by
  `amz_proto_fit` a NaN distance means exactly "this class has no prototype". This
  includes the first candidate: an empty class 0 is skipped too.
- If no class has a prototype, `amz_proto_predict` returns `AMZ_ERR_ARG` and
  `amz_proto_accuracy` returns NaN. `amz_proto_fit` cannot produce such a set, because
  it needs n ≥ 1, so this only happens with a hand-built prototype matrix.
- A hand-built prototype row with a NaN anywhere is treated the same way: no prototype.

## Consequences

- **Positive.** The classifier can only answer with classes it was trained on, and the
  fitted matrix shows which classes are empty: test any coordinate for NaN.
- **Negative.** Code that read the old zero rows as a valid point now reads NaN. That
  value never described the data.
- **Neutral.** k-means is unaffected. An empty *cluster* still keeps its previous
  centroid during Lloyd's iteration (a standard choice), because that centroid is a real
  point the algorithm placed.

## Alternatives considered

- **Refuse a fit that has an empty class.** Rejected: declaring more classes than the
  training split contains is normal (rare labels, held-out classes), and the other
  prototypes are still correct.
- **Keep the zero row and skip classes by a separate count array.** Rejected: it
  changes the return type from a ganita matrix to a record. A NaN row keeps the matrix
  self-describing.
- **Place the empty class at +∞.** Rejected: an infinite coordinate makes the distance
  ∞ − ∞ = NaN for an infinite query, and NaN is the honest value anyway.
