# Sources

Every algorithm, formula and constant amuzesh implements, and where it comes from.

## Algorithms

| What | Where in amuzesh | Source |
|---|---|---|
| k-means, Lloyd's iteration (assign ↔ update) | `src/kmeans.cyr` `amz_kmeans_fit` | S. P. Lloyd, "Least squares quantization in PCM", *IEEE Trans. Inf. Theory* 28(2):129–137, 1982 (Bell Labs memo, 1957). |
| k-means++ seeding (D² weighting) | `src/kmeans.cyr` `_amz_pp_seed` | D. Arthur, S. Vassilvitskii, "k-means++: The Advantages of Careful Seeding", *Proc. 18th ACM-SIAM SODA*, 2007, pp. 1027–1035. |
| Categorical draw by inverse CDF over a running sum | `_amz_pp_seed` | L. Devroye, *Non-Uniform Random Variate Generation*, Springer, 1986, §III.2 (the inversion method for discrete distributions). |
| Running (online) mean | `src/dist.cyr` `_amz_label_means` | B. P. Welford, "Note on a Method for Calculating Corrected Sums of Squares and Products", *Technometrics* 4(3):419–420, 1962. |
| Partial-distance search (stop a squared-distance sum once it cannot win) | `src/dist.cyr` `_amz_sqdist_lt` | C.-D. Bei, R. M. Gray, "An Improvement of the Minimum Distortion Encoding Algorithm for Vector Quantization", *IEEE Trans. Commun.* 33(10):1132–1133, 1985. |
| Nearest-centroid (Rocchio) classifier | `src/proto.cyr` | J. J. Rocchio, "Relevance Feedback in Information Retrieval", in G. Salton (ed.), *The SMART Retrieval System*, Prentice-Hall, 1971, pp. 313–323. Its equivalence to LDA under equal isotropic covariance: T. Hastie, R. Tibshirani, J. Friedman, *The Elements of Statistical Learning*, 2nd ed., Springer, 2009, §4.3. |
| Cluster purity | `src/kmeans.cyr` `amz_purity` | C. D. Manning, P. Raghavan, H. Schütze, *Introduction to Information Retrieval*, Cambridge University Press, 2008, §16.3. |

## Numerics

| What | Where | Source |
|---|---|---|
| IEEE-754 binary64 encoding: exponent all ones means NaN or ±∞; quiet NaN `0x7FF8000000000000` | `src/check.cyr` | IEEE Std 754-2019, §3.4. |
| Non-finite input: refuse where a function judges, propagate where it carries | `src/check.cyr`, ADR 0002 | ganita ADR 0004 (2026-10-03). |
| Failure vocabulary: pointer 0, status −1 / −2, f64 NaN | `src/check.cyr`, ADR 0002 | ganita ADR 0001 (2026-09-07). |

## Constants

| Constant | Value | Why |
|---|---|---|
| `AMZ_KMEANS_MAX_ITER` | 10,000 | Policy cap (ADR 0002): bounds a fit's up-front history at 80 KB. |
| `amz_inertia_monotone` slack | relative 1e-9 | Far above the rounding of an n·d-term f64 sum at the sizes amuzesh is tested on (≈ n·d·2⁻⁵³), far below any real rise. |
| Blob centers `(c+1)·10 + axis`, unit variance | `amz_make_blobs` | Fixture choice: centers 10·√d apart, ≈ 10σ per axis, so the clusters separate cleanly. |
