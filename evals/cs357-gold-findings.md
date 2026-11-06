# CS 357 gold findings (replay eval set)

Gold findings come from `PrairieLearn/pl-cs357` `reports/` at `0c4c9ea`. Use them to score
`diagnose-assessment-issues` replays (see [`docs/assessment-skill-plan.md`](../docs/assessment-skill-plan.md) §4).
Type numbers refer to the insight types in that document.

Replay setup: a copy of the course **without `reports/`**, and data limited to offerings
up to Spring 2026. Fall 2026 is used only for the post-offering replay (G-Q3-post).

A replay gets credit for a finding when it states the same observation *and* a compatible
cause. Credit for the observation alone is scored separately.

## Quiz 2: floating point, Taylor series

| ID | Type | Finding |
| --- | --- | --- |
| Q2-1 | 1 | 2025–26 Taylor pool: Energy Monitoring scores 16.8–21.0 points above Robot Arm in every semester. |
| Q2-2 | 3 | Cause: Energy Monitoring gives a function stub tested at two inputs. Robot Arm asks for three scalars at one point, with no comparable scaffolding and a different third output. |
| Q2-3 | 1, 4 | 2025–26 FP pool: UFLtoOFL vs UFLtoSubnormal gap ranges 4.4–36.4. 80% of the grader weight is one all-or-nothing enumeration test, and the two questions need different enumeration logic. |
| Q2-4 | 5 | Assignment counts unbalanced (107/315, 332/122); report question-level rates with n, not only the slot mean. |
| Q2-5 | 6 | UFLtoSubnormal unstable (37.8 / 67.1 / 50.7) despite no source change after Feb 2025. |
| Q2-6 | 7 | Stable anchors: Taylor-Coding-Exp-RelError, BeamBending-v2, Taylor-Degree, FindSubnormal, CouponCode-Simpler. |
| Q2-7 | 5 | Fall 2022 ZJUI retake n=5: exclude from design. |

## Quiz 3: Monte Carlo, norms, linear systems

| ID | Type | Finding |
| --- | --- | --- |
| Q3-1 | 2 | GameSales vs Vocaloid: near-equal final scores in F25/S26, but GameSales takes 1.5–3.6 more attempts and 1.5–4.0 more minutes. |
| Q3-2 | 3 | Cause: dense vs sparse records; GameSales asks for both the highest and lowest. |
| Q3-3 | 5 | MC-EstimateWinrate-v3 drops to 56.4% in Fall 2024 quiz3C with no source change. C cohort lower across all slots; A/B/C are separate versions, not a randomized pool. |
| Q3-4 | 5 | Fall 2021 best-2-of-3: self-selected occurrence statistics. |
| Q3-5 | 1 | Norm pool PatternMatching vs Stock: matched in two semesters, 23.3-point gap in Fall 2025; different iteration shapes; unbalanced assignment. |
| Q3-6 | 3, 4 | Prizewheel vs WheelsOfFortune: stable tiers; two equal-credit thresholds vs an 80/20 expectation-and-choice split. |
| Q3-7 | 8 | Current two-slot structure is much harder than the historical aggregate (linsys slot 27–38%). |

## Quiz 4: sparse, eigenvalues / Markov

| ID | Type | Finding |
| --- | --- | --- |
| Q4-1 | 6 | Spring 2026 TwoLargestEig: final scores set to 100% for everyone. The prompt's deflation formula used v₀ᵀv₀ while the reference used an outer product; corrected Apr 2. Exclude its final and full-credit figures. |
| Q4-2 | 2, 3 | COO vs CSR: CSR takes 2.6–4.1 min longer every semester. CSR has to recover rows from `rowptr`, threshold, and build sorted CSR arrays. The grader splits are different. |
| Q4-3 | 1, 3 | Power-and-transpose vs deflation: 19–25-point gap, ~3.5 more attempts. Deflation returns four objects and adds an algorithmic step. |
| Q4-4 | 5 | Fall 2021 `bestQuestions: 1` zone and Fall 2024 A/B versions are not clean pool comparisons. |
| Q4-5 | 7 | Model_Sparse_Compare_COO_CSR is a stable anchor (73–76%, ~12 min, three terms). |

## Quiz 5: nonlinear systems, optimization

| ID | Type | Finding |
| --- | --- | --- |
| Q5-1 | 1, 3 | Temperature vs Terrain: 33.0-point gap, then reversed (11.1), then 16.4. Terrain adds a saddle ("shelf") classification and a third test family. |
| Q5-2 | 5 | Same pool: assignment counts unbalanced, and the majority alternative reversed between terms. |
| Q5-3 | 1 | Secant pair (Critical Temperature vs Launch Angle): same loop, tolerance and grader, yet a persistent 6.0–10.1-point gap. Function shape, scale and initial guesses differ. |
| Q5-4 | 2 | Bisection vs Robot Arm: final scores converge, but Robot Arm takes 1.6–4.6 more minutes and has a lower full-credit rate (layered vector function + Jacobian + Newton). |
| Q5-5 | 4 | GoldenFindMax vs StepSizes: StepSizes has the higher mean but the lower full-credit rate, because it has more independent partial-credit components. |
| Q5-6 | 4 | Fall 2024 fixed questions: 34.5-point gap partly due to a single all-or-nothing test vs 40/30/30 weights. |
| Q5-7 | 5 | Fall 2021: three questions in a 10-point cap; 65/130/273 unattempted. Raw means are misleading; report attempted-only figures with a caveat. |
| Q5-8 | 1, 3 | Fall 2023 steepest-descent pool: 34.4-point gap. Two complete trajectories each graded all-or-nothing, vs one trajectory with 4/4/1 weights. |

## Post-offering: Fall 2026 Quiz 3 linear systems

| ID | Type | Finding |
| --- | --- | --- |
| Q3post-1 | 1 | MenuPrices 50.4% vs SurveyElevations 24.7% (−25.7 points; −26.8 after controlling for the Quiz 1–2 average). |
| Q3post-2 | 5 | Groups were similar on Quiz 1, Quiz 2 and practice behavior, so prior ability doesn't explain the gap. |
| Q3post-3 | 2 | The gap shows up as full credit → no-submission and attempted-zero; partial credit is about equal. First submission 20.3% vs 4.9%. |
| Q3post-4 | 3 | Cause: signed coefficients for directed differences plus a separate benchmark-constraint row. The grader splits are identical. |
| Q3post-5 | 10 | Adjustment of about 0.80–0.84 points on a 3-point question; a bonus, a capped rescale and a regrade affect students differently. |

## Earlier local review: Fall 2026 Quiz 4 (cross-check, not CS 357-authored)

| ID | Type | Finding |
| --- | --- | --- |
| L4-1 | 8 | All three sparse alternatives took 17.2–18.2 min median vs a 5–10 min target; 16.9% unsubmitted. |
| L4-2 | 4 | Matrix-vector product component averaged 28–39% vs ~54–69% for the COO components. |
| L4-3 | 6 | Static grader rule rejects a legitimate 1-D `dot`: a demonstrated false positive. |
| L4-4 | 1, 3 | Cond-ErrorBound v1 76.2% vs v2 91.8%: rearranging a bound vs multiplying by a condition number. |
| L4-5 | 9 | Practice best-2-of-3 lets students skip a required topic; 221/349 practiced both. |
| L4-6 | 10 | Best-submission reconstruction 86.7% vs actual 83.3% (retry schedules). |
