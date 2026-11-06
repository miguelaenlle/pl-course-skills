# `diagnose-assessment-issues` test log

November 5, 2026. Each run was a fresh subagent working in a copy of the course
repository, with prior analyses removed (`reports/`, `output/`) and no git
history. All runs used read-only production data except one, which used exported
statistics only. I spot-checked numbers in every run against the saved results,
and checked source claims in the question files.

## Rounds

| Round | Run | Prompt style | Data | What it found that we knew | Report length |
| --- | --- | --- | --- | --- | --- |
| 1 | CS 357 Quiz 5 | scripted context | DB | Terrain saddle case and contradictory prompt; secant pair gap | ~2,500 words |
| 1 | CS 357 Quiz 4 (Sp26) | scripted context | DB | Blanket credit on one alternative only; deflation cause; COO/CSR assigned by day | ~2,000 |
| 1 | TAM 212 Quiz 4 | scripted context | DB | No gold list; spot-checked figure bug and 3-of-5 pool | ~2,200 |
| 2 | CS 357 Quiz 3 | instructor prompt + follow-up | DB | SurveyElevations gap and cause; Treasure gap | ~1,300 |
| 2 | CS 357 Quiz 2 | instructor prompt + follow-up | exports only | RobotArm vs EnergyMonitoring; all-or-nothing list; non-random assignment from counts | ~1,100 |
| 2 | TAM 212 Quiz 3 | instructor prompt + pushback | DB | No gold list; spot-checked | ~1,300 |
| 3 | CS 357 Quiz 6 | instructor prompt | DB | No gold list; spot-checked | ~1,100 |
| 3 | TAM 212 Quiz 2 | instructor prompt | DB | No gold list; spot-checked generator cause | ~1,000 |

Things the runs found that weren't in any earlier analysis:

- an October 25 bump that also gave non-submitters 30%
- a grader changed after the exam
- a sign-convention trap
- generators that produce zero-answer variants
- figure bugs
- grader inconsistency on written questions

## What changed in the skill

- **After round 1:**
  - split the report into a short `report.md` and a `details.md`
  - check for non-random assignment
  - handle manual-grading quirks and grader spread
  - report effect in points
  - allow edits beyond question files
  - fix the starting query
- **After round 2:**
  - check whether the current definition has run
  - treat intentional differences as possibly unfair draws, not defects
  - add a "Predicted" confidence label
  - check for weaker cohorts using the questions that didn't change
  - detect partial score bumps
  - detect question edits without history
  - hand off when the instructor asks for edits
  - fix the course lookup and output noise
- **After round 3:**
  - how many past offerings to use
  - what to do when students get unlimited attempts
  - a recipe for draw effects
  - "already fixed" findings
  - saved but ungraded submissions

## Follow-up behavior (round 2)

- **Correction ("we already gave it; the difference is intentional"):** it asked
  for the specific missing data and reframed the finding as comparable
  difficulty rather than sameness.
- **Pushback ("maybe the class is weaker"):** it checked the questions that
  didn't change, kept its claim, and reframed the time finding as course-wide.
- **Request to make the edits:** it stayed read-only, gave ready-to-paste
  content and the PrairieLearn steps, and offered to re-check afterwards.

## Known limits

- **Two courses only.** Both are STEM with heavy numeric and code questions. We
  haven't tested a course built mostly from manually graded, essay, or
  multiple-choice-only assessments.
- **Reports still run 1,000–1,300 words,** against an 800-word target.
- **Gold findings exist only for CS 357,** and the tester (me) knew them.
- **The course-agent environment isn't tested:** it has no database, and file
  writes may behave differently there. Only one run tested the exports-only
  path.
