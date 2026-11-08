# migrate-course-instance test log

## What success means

A migrated course instance is correct when:

- every assessment sits in the same week of instruction, on the same weekday
  and at the same time, as in the source
- no deadline falls on a holiday or in a break without approval
- nothing tied to the old term's students carries over
- it syncs cleanly

The instructor makes every judgment call in a single review.

## Baseline: what instructors actually do

Real term-to-term copies in two courses, compared with the script's
calendar-only mapping (`evals/migrate/run_replay.sh`, official UIUC registrar
calendars):

| Transition                      | Release exact / within 3 days | Due exact / within 3 days |
| ------------------------------- | ----------------------------- | ------------------------- |
| CS 357 Spring 2026 → Fall 2026  | 93% / 98%                     | 86% / 91%                 |
| CS 357 Fall 2025 → Spring 2026  | 84% / 98%                     | 86% / 99%                 |
| TAM 212 Spring 2026 → Fall 2026 | 42% / 42%                     | 79% / 82%                 |
| TAM 212 Fall 2025 → Spring 2026 | 21% / 42%                     | 78% / 81%                 |

CS 357's own copies follow the rule exactly: same weekday and time, shifted 31
weeks before spring break and 30 after. TAM 212 changes policy every term:
homework windows went from two weeks to one, and discussion sections were
compressed after spring break. A calendar can't predict those changes, which is
why the skill asks "Anything different this term?"

The real copies also contain mistakes that the skill's `scan` catches:

- **TAM 212 Fall 2026:** 7 practice assessments have 2024 or Spring 2026 dates,
  so they are closed all term. Three deadlines or releases fall on Labor Day,
  and one release falls in fall break.
- **TAM 212 Fall 2025:** 39 dates were left over from 2024 and Spring 2025.
- **CS 357 Fall 2026:** the Lecture 25 due date and the Practice Quiz 6 release
  fall in fall break. The instance also uses a question named for Spring 2025
  (`GA-create-your-team-sp25`).

## Round 1: three instructor-style runs (2026-11-07)

Each subagent got a one-line request, the skill, and a git checkout of the
course without `questions/`. The instructor was unreachable, so each agent
wrote its review and then proceeded as if the instructor had accepted every
default.

| Test              | Request                                                                                             | Outcome                                                                                                                                                                                                                                                                                                                                                                                                       |
| ----------------- | --------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| CS 357            | "Set up Spring 2027 from Fall 2026."                                                                | 361 dates moved. Found both fall-break dates, both term-named questions, the CA label overrides, and the unsynced `assessments-not-used/`. Validated the result against the JSON schemas.                                                                                                                                                                                                                     |
| TAM 212 (holdout) | "Can you get Fall 2026 ready? Base it on this spring." Real Fall 2026 removed.                      | 206 dates moved. Fixed the stale practice quizzes that the real Fall 2026 still has broken, sorted the 48 UID rules into staff-like groups and extensions, and flagged that Fall 2026 had already started.                                                                                                                                                                                                    |
| ZJUI (holdout)    | "Please set up our ZJUI Spring 2026 course from last year's ZJUI course." Real Spring 2026 removed. | Read ZJU's image-only PDF calendars and found the split term (weeks 1–2 before Spring Festival). Releases are within 3 days for 50%, and every date is in the right week. The remaining differences are instructor policy changes (homework opens Friday instead of Saturday, late deadline Tuesday instead of Monday). Caught that converting to `publishing` would block ZJUI students from self-enrolling. |

All three migrated instances sync on local PrairieLearn with no errors or
warnings.

### What changed after round 1

- **Break placement.** Dates in a source break used to go to the target break
  with the same ordinal, which sent a fall-break deadline into spring break,
  five weeks before its release. Now a date goes to a break at the same point
  in the term, or else to the next week of instruction.
- **New `strip` command.** It removes legacy UID rules and per-student
  overrides in place and warns when an assessment is left staff-only. `plan`
  ignores dates inside these rules.
- **New `plan` flags:**
  - dates out of order within a rule
  - open windows that shrink by more than half
  - dates already in the past
  - finals dates clamped to a shorter finals period
- **Stale dates are handled per rule.** If any date in a rule is outside the
  source term, the whole rule is left unchanged and flagged.
- **`apply` and `strip` keep CRLF line endings.** `apply` also refuses to run
  if a file's set of dates differs from the plan.
- **New `scan` checks:**
  - UID rules grouped by their set of UIDs, without printing the UIDs
  - questions named for a term
  - institution rules
  - Exam-mode rules without a PrairieTest exam
  - unsynced folders
  - client PDFs
  - deadlines separated from releases
- **Skill text:**
  - the explicit request wins over defaults
  - check whether the target term has already started
  - calendars can be PDFs or split across documents
  - carry institution restrictions into `selfEnrollment`
  - what to do with label overrides, staff-like UID groups, and practice
    assessments whose quiz has no dates
  - compact review tables for large courses

## Known limits

- Different-length terms (semester to summer or quarter) are flagged but not
  compressed automatically.
- Not yet tested on a quarter system, or on a course whose source instance
  uses PrairieLearn's own copy (modern access control from the start). CS 357
  Fall 2026 partly covers the latter.
- The skill is about 2,200 words, longer than the other skills. The decision
  list carries most of the length.
