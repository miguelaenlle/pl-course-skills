---
name: diagnose-assessment-issues
description: >-
  Diagnose problems in a PrairieLearn assessment from past student results and
  the question source: alternatives in the same slot that aren't comparable,
  questions that take far longer than intended, grading that distorts scores, and
  unclear prompts. Use for requests such as "How did Quiz 4 go?", "Were the
  variants fair?", or "What should we fix in Quiz 6 before next term?" Produces a
  short report with recommended edits; does not edit questions.
---

# Diagnose assessment issues

When you're done, the instructor should know **which questions to change, how,
and why**, after about five minutes of reading. Every claim must hold up.

Statistics tell you where to look. The question source tells you why. A
difference between two numbers isn't a finding until you can point to what in the
question, grader, or assessment setup causes it, or say plainly that you couldn't.

## Boundaries

- **Read-only.** Don't edit course files, change grades, or write to any
  database. Recommend edits; the instructor decides.
- **Aggregate data only.** Never save or show student names, UIDs, emails, or
  per-student rows. To understand mistakes, count patterns across many
  submissions instead of reading individual ones. Refer to graders as G1, G2,
  and so on.
- **Ask only when blocked.** If you can't tell which course or assessment is
  meant, ask one question and recommend an answer. Otherwise make reasonable
  choices and record them in the report.

[references/data.md](references/data.md) covers data access, PrairieLearn
tables, starting queries, and known data quirks.

## 1. Establish scope

1. Identify the course and assessment. Look for a course design guide or earlier
   reports, and use any conventions you find, such as intended time per question
   or target difficulty.
2. Choose the offerings:
   - **The assessment as it's currently defined.** Fixes apply here, so check
     whether its questions changed since the offering being asked about.
   - **Past offerings of the same assessment.** Match by assessment ID or title,
     and confirm they cover the same material by checking question overlap.
   - **Neighboring assessments** only for signals that cut across topics, such as
     total time pressure.
3. Record each offering's structure. These all change how numbers should be read:
   - which questions compete for the same slot
   - points and retry schedules
   - "choose N of M" draws, best-N zones, and optional questions
   - manual or auto grading
   - retakes and separate versions
   - exam length, which may live outside PrairieLearn (for example, in PrairieTest)

## 2. Measure

For each question in each offering, compute:

- number assigned
- mean final score and share with full credit
- mean first-submission score
- mean attempts
- median time
- share with no submission

Show alternatives in the same slot side by side, with their sample sizes. Keep
offerings separate; pool them only when their definitions are identical.

Then add finer-grained evidence where it helps explain a gap:

- **Per part:** test results, per-input credit, rubric items, or option choices
  show which step students lose points on.
- **By generated parameters:** shows whether some random instances are harder.
- **Common wrong answers:** for example, the share of answers that are off by a
  sign, use the wrong formula, or match a worked example.
- **Effect on students:** points out of the assessment total that a student loses
  because of what they drew. For "choose N of M" pools, compare the combinations
  students drew.

## 3. Find candidates, then rule out other explanations

Candidates worth explaining:

- **Alternatives in one slot that differ** on score, full credit, time, attempts,
  or non-submission, especially when the gap repeats across offerings.
- **Similar scores that hide a workload difference.**
- **Questions far from the intended time or difficulty.** With no stated target,
  compare against the question the item replaced and the assessment's total time.
- **Shifts between offerings** for the same question.
- **Grading that differs** between alternatives or between graders.

Before you believe a candidate, rule out explanations that have nothing to do
with the question:

- small samples
- alternatives that weren't assigned at random, for example a different
  question on different exam days
- students choosing which questions to attempt
- different groups of students: retakes, sections, separate versions
- overrides or blanket credit
- question edits between offerings
- time measurements that include idle time

A gap that reverses between offerings, with no explanation, is weak evidence.
Report the pair as unstable rather than calling one variant harder.

## 4. Explain each candidate from the source

Read the alternatives side by side: prompt, generator, grader or tests, starter
code, and rubric. From what *these* questions ask, decide which differences could
change difficulty or workload. Don't apply a fixed checklist; what matters depends
on the subject and question type. Frequent causes:

- more steps or outputs, or an extra method to apply
- less scaffolding, or examples that don't cover what the tests check
- test cases or parameter ranges that only one alternative has
- grading weights, all-or-nothing parts, or rubrics with different rules
- tolerances, units, sign conventions, or answer formats
- wording that is ambiguous, contradicts itself, or uses different terms from
  those taught
- generated parameters that produce harder or degenerate instances

Test the explanation against the finer-grained evidence. Does the step you suspect
have the lowest success rate? Do the wrong answers match the predicted mistake?

Label each finding's confidence:

- **Observed:** the data shows it directly.
- **Likely:** the source and data support a cause, but haven't proven it.
- **Unexplained:** the gap is real, but no cause was found. Say what would settle
  it.

Add a few words to the label when strength varies, for example: "Likely; reversed
in one term."

## 5. Recommend edits

Give each finding the smallest change that addresses its cause. It can be:

- a question file
- an assessment setting
- a rubric in PrairieLearn
- a process step, such as calibrating graders

Say "No edit needed" when that's the honest answer. Don't recommend grade changes
yourself. If a past offering was clearly unequal, state the effect in points and
leave the decision to the instructor.

## Report

Write `report.md` for the instructor. Put per-offering tables, method notes, and
smaller checks in `details.md` next to it. Save queries and aggregate results
alongside both. Use the folder the instructor names, or the course's existing
location for reports. Otherwise, use a new folder outside the course repository.
If you can't write files, return the report text instead.

```markdown
# <Assessment>: diagnosis
<date> · <offerings analyzed> · <data source>

## Bottom line
<Up to five bullets, most important first: what to change and why.>

## Findings
### <Short claim, naming the slot and questions>
<One small table or two sentences of numbers, each with its offering and n.>
**Why:** <cause, with file path> (or "Unexplained: …")
**Confidence:** <label>
**Effect:** <points out of the assessment total, and for whom>
**Edit:** <concrete change, or "No edit needed">

## Checked, no change needed
<One line each: pools that are well matched, gaps judged to be noise.>

## Questions for the instructor
<Only decisions you can't make. Omit the section if there are none.>
```

Keep `report.md` to about 800 words. Order findings by effect on students: how
many were affected and by how much. Most reports have three to six findings.
Write in plain language, without statistics jargon. Scope, exclusions, and data
caveats go at the top of `details.md`, with a one-line pointer in the report.

## Before handing off

- Recompute the numbers each finding uses from the saved data.
- Confirm each finding cites a source or is marked Unexplained.
- Confirm the step 3 explanations were ruled out for each finding.
- Confirm no saved file contains student identifiers or per-student rows.
- Reread the bottom line: could the instructor act on it alone?

In chat, give two or three sentences and the report path. Keep the detail in the
report.
