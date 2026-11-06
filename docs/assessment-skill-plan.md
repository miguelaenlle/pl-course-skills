# Assessment-improvement skills: current state and plan

November 5, 2026. Sources read:

- `PrairieLearn/pl-cs357` at `0c4c9ea` (read-only sparse clone; nothing pushed): `reports/` and `.agents/skills/`
- `improve-assessment` skill (copied unchanged into `skills/`)
- Codex test run, Nov 3: `cs357-quiz5-review/report.md` + `source-review.md`
- Earlier local review in the disposable course: `pl-cs357-agent-local/reports/quiz4-fall2026-review/`

## TL;DR

- **CS 357's real asset is the reports, not the skills.** Its two skills cover Code Studio notebooks. The quiz work happens through ad-hoc agent sessions that leave a per-quiz report in `reports/`. Each report works as an evidence base, a design brief, a prototype log and a validation record in one document.
- **The value of those reports is a cause found in the question source for every outcome difference.** The statistics are a short, fixed set of seven metrics. The insight comes from reading the question and its grader to explain *why* two alternatives behaved differently. That is the semantic, context-aware part to generalize.
- **Our skill is mostly process and safety rules.** It has almost no guidance on *what to look for*. Its main evidence source is "the previous quiz", while CS 357 uses *prior offerings of the same quiz*. Its 300–500-word report squeezes out the per-pool evidence that makes CS 357's reports useful.
- **Plan:** split it into three skills (`diagnose-assessment-issues`, `prototype-questions`, `assemble-assessment`). They share a structured per-assessment design log and reference files: an insight checklist, a confounder checklist, query templates and data-access options. Evaluate by replaying CS 357 Quiz 2–5 against a gold list of findings (see [`evals/cs357-gold-findings.md`](../evals/cs357-gold-findings.md)), then test on a second course.

---

## 1. What CS 357 is actually using

### Artifacts

| Artifact | Examples | Size | Role |
| --- | --- | --- | --- |
| Per-quiz design log | `reports/quiz{1..5}-coding-question-analysis/README.md` + `query.sql` + `coding-question-statistics.csv` | 750–3,700 words; 40–50 CSV rows | Historical evidence (Fall 2021–Spring 2026) → instructor brief → prototype → matched variants → practice pool → "what to re-check after this term" |
| Validation scripts | `validate_monte_carlo.py`, `validate_inspection_arm.py`, `validate_penalty_*.py` | — | Run reference solutions and plausible mistakes in the grader Docker image; check partial-credit independence and generated-parameter ranges |
| Post-administration comparison | `reports/quiz3-fall2026-linsys-comparison/` (+ PDF) | ~1,000 words, OLS, 2 figures | Instructor asked whether one alternative was harder and what adjustment that would justify. Answered with an instructor-specified model. |
| Skills | `.agents/skills/{create,review}-cs357-code-studio` | ~1,000 words each | Not about assessments: converting MPs into live Jupyter labs |

Commit history shows the loop running continuously this term. The professor commits a report and its questions together ("start dev quiz 3", "added linsys question quiz 3", "sparse quiz4 questions"). TAs review through PRs (for example PrairieLearn/pl-cs357#168 and PrairieLearn/pl-cs357#170, which simplified the treasure-key question). Reports are updated in place as the design moves forward.

### The loop, as the reports show it

1. **Evidence stage.** One SQL query (course-scoped, coding questions only, `include_in_statistics AND used_for_grade`) produces one row per *question occurrence × semester*. The metrics are final %, first-submission %, best %, full-credit %, attempts, and median duration. Quiz 3 and Quiz 5 then **stop on purpose**: "Design should begin only after the instructor supplies the course context."
2. **Instructor brief.** It is recorded verbatim in the report: points per slot, minutes per question, target mean (for example 50–60%), library policy, which construct should carry the difficulty, and links to what was taught (a pre-lecture video, Code Studio 2, Homework 7).
3. **One prototype.** It is built and validated, and its grading split and the reason for it are written down.
4. **Review, then variants.** Variants are matched on explicitly listed dimensions (for Quiz 4: "same interface pattern, amount of scaffolding, two nonzeros per column, direct COO accumulation, and grading split").
5. **Practice pool** is redesigned so actual-quiz questions are excluded.
6. **"Updating after Fall 2026"** says what to compare next time. That closes the loop into the next term's evidence stage.

### What kinds of insight the agent finds

This is the core of what we need to generalize. Across the six CS 357 reports plus our two local reviews, the findings fall into ten recurring types:

| # | Insight type | How often | Representative example |
| --- | --- | --- | --- |
| 1 | **Alternatives in one slot are not equivalent** | Every report | Quiz 2 Taylor pool: 16.8–21.0-point gap in *every* semester 2025–26. Quiz 5 optimization: 33.0-point gap, then reversed. "A shared module label or story structure has not been enough." |
| 2 | **Similar scores hide different workload** | Q3, Q4, Q5, local Q4 | Quiz 3 GameSales vs Vocaloid: nearly equal final scores but 1.5–3.6 more attempts and 1.5–4.0 more minutes. Quiz 4 COO vs CSR: 2.6–4.1 min longer every semester. |
| 3 | **The cause is found in the question source** | Nearly every finding | Deflation adds a fourth output and an extra algorithmic step. Terrain adds a saddle case ("shelf") that Temperature lacks. Survey Elevations needs signed coefficients plus a benchmark row. Dense vs sparse records. |
| 4 | **Grading granularity drives the numbers** | Q2, Q3, Q5, local Q4 | 80% of the weight on one all-or-nothing enumeration test. A single test makes the final mean equal the full-credit rate. More partial-credit components raise the mean but lower full credit (StepSizes vs GoldenFindMax). Fall 2024's 34.5-point gap is "grader granularity as well as task difficulty". |
| 5 | **Assessment structure distorts the data** | Q2–Q5 | Best-2-of-3 zones cause self-selection. Separate A/B/C versions are confounded with cohort. Retakes with n=5–6. Unattempted zeros. Assignment counts unbalanced and reversing (107 vs 315). Zero-use duplicate assessment records. |
| 6 | **Bugs and historical edits** | Q4, local Q4 | Spring 2026 TwoLargestEig scores were set to 100% for everyone. Git history shows the prompt said v₀ᵀv₀ while the reference used an outer product; it was fixed April 2. Separately, the local grader rejects a legitimate 1-D `dot`, a demonstrated false positive. Most reports also check "source unchanged since X" so outcome shifts aren't blamed on edits. |
| 7 | **Stable anchors** | Q1–Q4 | Questions with the same performance tier across cohorts (for example `Model_Sparse_Compare_COO_CSR`: 73–76%, ~12 min, three terms) are used to calibrate workload for new questions. |
| 8 | **Time budget vs reality** | Q2, Q4, local Q4 | Target 5–10 min per sparse task; submitters' actual median was 17.2–18.2 min. Median exam duration 46.1 of 50 min. 16.9% of sparse questions unsubmitted. |
| 9 | **Alignment with teaching and practice** | Q1, Q3, Q4, Q5, local Q4 | Practice's best-2-of-3 format lets students skip a required topic (221/349 practiced both). Avoid duplicating Homework 10. The new pool should look different from practice. The quiz should build on the pre-lecture video and Code Studio. |
| 10 | **Policy effects** (retries, adjustments) | Linsys comparison, local Q4 | Replacing final scores with best scores raises the mean from 83.3% to 86.7% (the effect of `[3,1]`-style retry schedules). The post-hoc gap of −25.7 points supports an adjustment of about 0.80–0.84 points, with policy options listed. |

Two meta-patterns:

- **The statistics stay simple and fixed; the explanations are specific to each question.** No report uses item-response theory or discrimination indices. Every report uses the same seven columns. The differentiator is types 3–4: reading `question.html`, `server.py`, and the tests to name the structural difference behind a number.
- **The comparison dimensions come from the domain.** For CS 357 coding questions they converged on: output count, scaffolding (function stub vs snippet), number of algorithms, data representation, loop or enumeration burden, stopping criteria, hidden-case categories, grader weights, partial-credit opportunities, and debugging burden. A physics or statistics course would need a different list, such as number of steps, given vs derived quantities, unit conversions, or distractor quality. **The skill should teach the agent to derive these dimensions, not hand it CS 357's list.**

### What the CS 357 reports do *not* do

- They cover **only coding (externally graded) questions**. Non-coding slots are ignored. Our local Quiz 4 review found the clearest non-coding problem (Cond-ErrorBound v1 at 76.2% vs v2 at 91.8%).
- They use **aggregates only**. Student errors are inferred from the source, never observed. The one time per-test-component pass rates were used (local Q4: the matrix-vector product component at 28–39% vs ~60% for coordinates), they pinpointed *which step* failed. This is the most promising unused signal, and it can be gathered without exporting any student identifiers.
- The documents **accumulate stale content**. "The unassigned prototype…" sits a few sections above "now the alternatives in the slot". Whether a question is a draft, reviewed or assigned has to be inferred.
- **Numbers sit inside paragraphs** ("finished at 73.5–83.1%, required 4.86–5.95 attempts, and had 7.5–9.3-minute medians"). The evidence is accurate but slow to scan.
- **Boilerplate repeats** in every report: Files, Scope and Metric definitions.
- The historical reports have **no bottom-line section**. The linsys comparison does ("Bottom line"), and it is by far the easiest to act on.

---

## 2. Current state of our skill

`improve-assessment` (1,043 words) covers all three stages in one file:

- **Overview / goals:** three stages; "one pass" means a finished report, not automatic implementation; ask only when blocked.
- **Setup (~25% of the text):** hardcoded `sysconf` path, `pnpm alma rds us-prod --access readonly`, awslogin, "local Codex", disposable course, and a note that the container has no DB.
- **Procedure:** one paragraph per stage. Stage 1: "Compare available scores, completion, attempts, time, and question alternatives…"
- **Report:** 300–500 words with Recommendation / Main findings (≤5) / Proposed changes / Checks and limits / Your input.

Separately there is `review-question` (230 words): checks the prompt ↔ params ↔ correct answers in one question.

### How it performed (Codex Quiz 5 run, Nov 3)

What went well:

- It found the CS 357 prototypes that already exist (InspectionArm, PenaltyClosestPoint) and recommended reviewing them instead of rebuilding.
- It surfaced cross-cutting design signals from Quiz 4: coding workload, retry-schedule effects and practice gaps.
- It checked IDs, counts and point totals, and ran 756 secant reference cases.
- It kept chat short and asked one decision at the end.

What fell short:

- **Wrong primary evidence.** It analyzed *Quiz 4 → Quiz 5* (different topics). The CS 357 Quiz 5 history (39 occurrences over five years) was "copied… not refreshed". CS 357's method starts from prior offerings of the same assessment.
- **Not similar in format to CS 357.** There are no per-pool semester tables and no "what to re-check" section. It is a memo, not a design log, and the next cycle can't build on it.
- **Too compressed to read.** "Across 349 closed, included records…" and "five-point conditioning pair averaged 76.2% versus 91.8% (173/176 assignments)". The 300–500-word limit pushed density up, and the actual content moved into a 12 KB `source-review.md`.
- **The useful diagnosis is buried.** The finding "Terrain adds a saddle case" is in there, but not as a clear observation → cause → action.

### Where the skill is lacking

1. **No guidance on what to look for.** Nothing like the ten insight types or the "explain every gap from the source" rule. The agent has to rediscover the method each run.
2. **The evidence source is wrong.** "Use the previous quiz and earlier versions of the target quiz when relevant" should be reversed: earlier offerings of the target come first, and adjacent assessments are only for cross-cutting signals (time, retry policy, practice).
3. **No confounder checklist.** Best-N zones, separate versions, small n, blanket credit, unbalanced assignment and duplicate records are all things CS 357 learned the hard way.
4. **No data-model knowledge.** No reusable query; each run re-derives `include_in_statistics`, `used_for_grade`, `first_submission_score`, and the duration caveats.
5. **Tied to one machine.** Paths and Alma commands are hardcoded, and so is "local Codex". In the course-agent container the DB isn't available at all, so stage 1 has no data source in the actual product.
6. **Stages 2–3 are thin.** CS 357's validation practice is missing: Docker-graded reference solutions plus mistakes, component independence by injecting correct reference callables, calibrating hidden cases, and checking parameter ranges for degenerate cases.
7. **No persistent state between stages or terms.** The report lives "outside the course repository", so the next cycle has no memory. CS 357 commits the log into the repo, and that is what makes the loop work.
8. **One skill, three triggers.** "Improve Quiz 6", "build three variants of this question" and "set up the practice quiz" are different jobs with different done criteria.

---

## 3. How to improve it

### 3.1 Split into three skills

The CS 357 professor's own skills are a good structural model: two narrow skills, each with "Do not use for X; use Y". Each loads a course-specific spec file first, writes an internal design brief, then follows a numbered verification checklist and a fixed handoff.

```
skills/
  diagnose-assessment-issues/SKILL.md     # evidence → report → questions for instructor
  prototype-questions/SKILL.md        # brief → one prototype → validate → review → matched variants
  assemble-assessment/SKILL.md        # slots, points, practice, time budget, local test, "measure next"
  _shared/                            # referenced, not triggered
    design-log-template.md
    insight-lenses.md                 # the ten insight types as prompts
    confounders.md
    data-access.md                    # DB read-only / PL CSV exports / future agent tool
    queries/occurrence-stats.sql      # parameterized CS 357 query
    queries/component-pass-rates.sql
```

| | `diagnose-assessment-issues` | `prototype-questions` | `assemble-assessment` |
| --- | --- | --- | --- |
| **Trigger** | "How did Quiz 4 go?", "Improve Quiz 6", "Was variant B harder?" | "Draft a question for slot 2", "Make two variants of X", "Review this question" (absorbs `review-question`) | "Put Quiz 6 together", "Update the practice quiz" |
| **Modes** | *Before an offering*: history of the same assessment across terms. *After an offering*: alternatives within this term, plus an optional instructor-specified model, as in the linsys comparison. | Single prototype; variant expansion; review only | — |
| **Core guidance** | Insight lenses; "every outcome gap gets a source-based cause or is labeled unexplained"; derive comparison dimensions from the questions; confounder checklist; per-component pass rates when available | Capture the brief (points, minutes, target mean, policy, which construct carries the difficulty, what was taught); match variants on derived dimensions and record them in a table; validation matrix | Practice covers every required construct; actual-quiz QIDs excluded from practice; total time from anchors; retry policies made explicit; local PL render and grade |
| **Stops at** | Report + "questions for the instructor" (the CS 357 design gate) | A previewable, validated prototype or variant set + comparability table | Assembled assessment + "measure next term" list |
| **Writes to design log** | Evidence, Findings | Brief, Questions (status: draft → reviewed) | Assembly, Practice, Measure next |

Notes:

- **Course-specific knowledge goes in the course repo, not the skill.** Each skill first looks for a course-level design guide (CS 357 has `additionalContent/AgentInstructios:…md` for Code Studios). If none exists, the first investigation drafts one from the instructor's answers: point conventions, quiz length, library policy, partial-credit conventions and practice format. That keeps the skills generic and lets them get better per course.
- **Keep the autonomy rules** from the current skill ("ask only when blocked", "silence is not acceptance", "analysis-only stays analysis-only"). They're good.
- **Move environment details** (Alma, sysconf, disposable course) into `data-access.md`, presented as one of several options.

### 3.2 One living design log per assessment

Replace the "report outside the repo" with `reports/<assessment>/design-log.md` in the course repo, matching where CS 357 already puts them. Its structure prevents the stale-content problem:

```markdown
# Quiz 5 design log
Status: evidence ✓ · brief ✓ · prototypes 2/2 reviewed · assembled ✗

## Current slots            ← always current; replaces scattered "now assigned" prose
| Slot | Pts | Alternatives (QID) | Status | Target min / mean |

## Bottom line              ← ≤5 lines, rewritten each stage
## Findings                 ← finding cards (below), newest stage first
## Brief                    ← instructor's words, dated
## Decisions                ← dated one-liners: "11-03 keep 42 pts; no retry change"
## Measure next offering    ← feeds next diagnose run
## Evidence                 ← links: query.sql, stats.csv, per-pool tables, validation scripts
```

The large per-pool semester tables move into `evidence/pools.md`, which is linked and not inlined. Metric definitions live once in `_shared/` and are not repeated in every report.

### 3.3 A cleaner findings format

The semantic core is a **finding card**: what we saw → why, from the source → how sure → what to do. That makes the context-aware part explicit without forcing a fixed statistical template:

```markdown
### Terrain and Temperature are not interchangeable (optimization slot)
**Saw:** Terrain 35.9% vs Temperature 52.3% (Spring 2026, n=150/158); ordering reversed in Fall 2025.
**Why (source):** Terrain's tests include a saddle case labeled "shelf"; Temperature has only min/max.
  Same interface and weights otherwise. → `questions/15-Optimization/OptimizationND-Newton-Terrain/tests/test.py:47`
**Confidence:** Observed gap; cause is likely (only structural difference found); not proven.
**Do:** Match hidden-case categories across alternatives, or drop the saddle case.
```

Rules for the skill:

- Every finding has a **Why (source)** line pointing to a file, or it says "unexplained: needs X".
- Confidence has three levels: *observed* (a number) / *likely* (source supports it) / *speculative*.
- Numbers go in tables or the "Saw" line, never chained inside paragraphs.
- "What worked" findings are allowed. Stable anchors and well-matched pools are useful to keep.
- Length is set by the number of findings: 3–7 cards plus the bottom line. No word cap; the bottom line is the skim layer.

### 3.4 Insight lenses, not a stats template

`insight-lenses.md` turns the ten types above into prompts the agent works through, and **adapts them to the question types in the assessment**:

- **Externally graded code:** per-test pass rates; output count; scaffolding; algorithm count; hidden-case categories; grader weights.
- **Numeric / symbolic input:** tolerance and units; how many derived quantities; whether generated parameters can produce degenerate or edge cases (CS 357 Quiz 2: "inspect generated parameter distributions if outcomes differ").
- **Multiple choice / checkbox:** distractor selection rates; options that are correct only for some parameters.
- **Manually graded:** which rubric items are used; grader agreement; time to grade.
- **All types:** pool equivalence; assignment balance; workload vs points; confounders; teaching and practice alignment; retry policy; source history.

PrairieLearn tables that support this (watch the large-payload columns): `instance_questions` (score, first/best, attempts, duration), `submissions.partial_scores`, test results in `submissions.feedback` (aggregated only, never exported per student), `rubric_items` / `rubric_grading_items`, and `variants.params` to bucket outcomes by generated parameter.

### 3.5 Data access for the real product

Today stage 1 only works on Miguel's laptop with Alma. In order of preference, `data-access.md` should support:

1. **A course-agent tool or API that returns aggregate statistics** (needs building in PrairieLearn). Without it, the course agent can't run the core of this skill. This is the largest product gap the exercise exposed.
2. **CSV exports instructors download** from the assessment's Statistics/Downloads pages and drop into the conversation.
3. Read-only DB (staff-internal testing only).
4. No data: a source-only review, clearly labeled.

### 3.6 Fold in CS 357's validation practice (stages 2–3)

Move into `prototype-questions`:

- reference solution plus 5–10 plausible mistakes, run in the grader image
- component independence: inject correct reference callables so a student who gets part 1 wrong can still earn part 2
- checks of parameter ranges against degenerate cases
- calibrating hidden cases so a known shortcut earns exactly the intended credit (the penalty variants' "90% without gradient")

Save the matrix as `validate_<qid>.py` next to the design log, as CS 357 does.

---

## 4. Evaluation plan

**Step 1: format and recall parity with CS 357 (replay).** For each of Quiz 2–5, run `diagnose-assessment-issues` against prior-offering data only (≤ Spring 2026), with no access to the existing report. Score it against the gold findings in [`evals/cs357-gold-findings.md`](../evals/cs357-gold-findings.md):

| Metric | Target |
| --- | --- |
| Recall of gold findings (by type 1–10) | ≥ 70% overall; ≥ 90% for type 1 (pool mismatch) |
| Every gap has a correct source-based cause | Manual check of each "Why" line |
| Confounders flagged (best-N, versions, small n, blanket credit) | All present ones |
| False or unsupported claims | 0 |
| Skim test: bottom line answers "what should I change?" in < 1 min | Pass/fail by a human reader |
| Interruptions before the report | ≤ 1 question |

The existing reports have to be hidden during the replay: copy the course without `reports/`.

**Step 2: post-offering mode.** Replay the linsys comparison: given Fall 2026 Quiz 3, does it independently find the MenuPrices / SurveyElevations gap, rule out prior-score differences, and point to the signed-coefficient + benchmark-row modeling step?

**Step 3: generality.** Run on a second course with a different question mix. `pl-tam212` is local and has ~10 years of course instances. Check that the lenses adapt to non-coding questions, and that the agent derives its own comparison dimensions instead of copying CS 357's list.

**Step 4: stages 2–3.** Replay Quiz 4: given the Fall 2026 brief, does `prototype-questions` produce one sparse prototype with a validation matrix and a comparability table, and stop for review?

---

## 5. Suggested order of work

1. Write `_shared/` (lenses, confounders, query templates, design-log template), since all three skills depend on it.
2. `diagnose-assessment-issues` + replay eval on Quiz 2–5 (step 1). Iterate until recall is acceptable.
3. `prototype-questions` (fold in `review-question`), then `assemble-assessment`.
4. Second-course test.
5. Product follow-up: aggregate-statistics tool for the course agent (§3.5).

## Open questions

- **Where does the design log live?** Committing it in the course repo matches CS 357 and gives the loop memory, but it adds files to instructors' repos.
- **Scope:** coding questions only (as CS 357 does) or all questions by default? Recommendation: all questions, since the clearest local finding was non-coding.
- **Data access in the product:** is an aggregate-stats tool for course agents on the roadmap, or should v1 rely on CSV exports?
