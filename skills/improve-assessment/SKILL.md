---
name: improve-assessment
description: >-
  Improve a PrairieLearn quiz or assessment locally using past results and course
  materials. Use for requests such as "improve Quiz 6": investigate and report,
  develop small drafts with instructor feedback, then finalize and test locally.
---

# Improve assessment

## Overview

Work through three stages: investigate and propose, develop drafts with feedback,
then finalize for delivery. A request such as “improve Quiz 6” starts with a concise,
checked report and proposed changes, before editing the quiz. “One pass” means
completing that report independently, not implementing all recommendations at once.

Complete the requested stage using the available evidence and your judgment. Ask
only when genuinely blocked; make routine decisions and record useful assumptions
instead of turning them into questions. Present a concrete result at each handoff.
Move to drafting or finalization when the instructor requests that stage or agrees
to the direction; do not ask again when that scope is already authorized. An
analysis-only request stays analysis-only.

This workflow runs with local Codex. Edit only a disposable course copy in a
separate PrairieLearn worktree. Keep outputs local and outside the original course
repository. Never push, publish, sync to production, or change student grades.

## Goals

- Test what students were taught and practiced.
- Fit the available time and intended difficulty.
- Give students comparable work when they receive different questions.
- Make instructions, grading, partial credit, and feedback clear and correct.
- Use results to improve the next assessment.

## Setup

Reuse the available local environment and confirm the editable course copy has no
production push destination. Find missing paths from the workspace before asking.

Try an existing authorized read-only database connection. Otherwise, run the
following from `sysconf` (on this machine,
`/Users/miguel/PrairieLearn/repos/sysconf`):

```sh
pnpm alma rds us-prod --access readonly
```

For saved queries, Alma also accepts psql options after `--`, for example
`pnpm alma rds us-prod --access readonly -- -v ON_ERROR_STOP=1 -f /absolute/path/query.sql`.
If login setup is needed, initiate `pnpm alma awslogin`. Tell the instructor when
they need to complete browser authentication or choose their account; leave those
steps to them. Resume after authentication and verify the connection is read-only.
Never request credentials in chat or switch to write access. If access is denied,
explain the specific obstacle and continue with available reports and course files;
request an aggregate export only when necessary. Do not repeatedly retry failed access.

The PrairieLearn course-agent container has no database connection merely because
Alma works on the host. Do not copy credentials into it.

## Procedure

### 1. Find the context and evidence

Locate the target quiz, semester, learning goals, time limit, points, allowed
resources, and relevant practice. Read existing questions, grading rules, reports,
and instructor feedback. Use the previous quiz and earlier versions of the target
quiz when relevant; do not assume successive quizzes teach the same topics.

Resolve context from the files and conversation. If ambiguity prevents identifying
the right course or assessment, ask one focused question with a recommended choice.
Otherwise proceed. Preserve existing goals and policies unless the instructor
requests a change.

Compare available scores, completion, attempts, time, and question alternatives.
Use authorized read-only queries scoped to the relevant course and assessments.
Save aggregate results and reproducible queries, excluding student identifiers
and individual submissions. Check the semester, assessment, counts, missing data,
and calculations before using a finding. Explain what each number measures;
different scores alone do not prove unfairness. Label estimates and uncertain
explanations. Without results, proceed with a clearly labeled review of the course
materials and question behavior.

Finish this stage by saving the report described below. Recommend specific changes
and explain their expected benefit. Link it in a brief chat response; do not edit
questions merely to complete the investigation.

### 2. Develop small drafts with instructor feedback

Turn the selected improvements into simple mockups or limited local question edits
that the instructor can easily evaluate. Choose a useful representative example
and complete it, including basic correctness checks, before presenting it. Explain
what changed, why, and how to preview it. Keep drafts separate from the assembled
assessment until they are ready.

Use instructor feedback to revise the drafts. Complete each revision without
asking about routine implementation choices. Preserve sound questions and keep
alternatives comparable in reasoning, effort, and points. Do not expand a draft
across the whole assessment before the instructor has accepted its direction.
If feedback is needed to choose the direction, present the completed draft and
your recommendation rather than a questionnaire. Silence is not acceptance.

### 3. Finalize and prepare for delivery

Once the direction is accepted and finalization is requested, finish the remaining
questions and assemble the local assessment. Check topic coverage, total workload,
question selection, and points. Prepare appropriate practice materials if included
in the agreed scope. Do not add another approval gate for routine completion work.

Check rendering and grading in local PrairieLearn. Exercise correct answers,
plausible mistakes, incomplete responses, and varied generated inputs, including
partial credit where relevant. Check question selection and total points. Fix
failures and distinguish completed checks from checks that remain unavailable.

Update the report with actual changes, verification results, remaining delivery
checks, and what to measure after students take the quiz. Provide the report and
local preview links in a brief handoff. Production release is the instructor's
separate publication process.

## Report

Save one Markdown report in a persistent local task folder outside the course
repository. Update it throughout the work. Aim for 300–500 words; use less when
possible. Link supporting queries and detailed results rather than embedding them.

- **Recommendation:** Lead with what to change and why.
- **Main findings:** Up to five consequential findings, with supporting numbers
  and links. Include what worked when it matters to the recommendation.
- **Proposed changes:** Give a short, prioritized list of concrete improvements.
- **Checks and limits:** Explain what was verified and what remains uncertain.
  In later stages, update this with actual edits and test results.
- **Your input:** Include only unresolved decisions that need the instructor.

Use plain language and short bullets or a small table. Explain practical effects:
“This question took twice as long for the same points.” Avoid unexplained terms
such as “cohort,” “discrimination,” or “workload calibration.” Verify that the report
matches the saved evidence and actual edits. Keep detailed analysis out of chat.
