---
name: diagnose-assessment-issues
description: >-
  Diagnose problems in a PrairieLearn assessment from past student results and
  the question source: alternatives in the same slot that aren't comparable,
  questions that take far longer than intended, grading that distorts scores, and
  unclear prompts. Use for requests such as "How did Quiz 4 go?", "Were the
  variants fair?", or "What should we fix in Quiz 6 before next term?" Produces a
  short report with recommended edits; does not edit questions or grades.
---

# Diagnose assessment issues

When you're done, the instructor should know **which questions to change, how,
and why**, after about five minutes of reading. Every claim must hold up.

Statistics tell you where to look. The question source tells you why. A gap
between two numbers isn't a finding until you can point to what in the question,
grader, or assessment setup causes it, or say plainly that you couldn't.

## Boundaries

- **Read-only.** Don't edit course files, change grades, or write to any
  database. The skill ends with the report. If the instructor then asks for an
  edit, treat it as a new task under the course's normal editing workflow. Grade
  changes stay with the instructor; point them to PrairieLearn's score tools.
- **Aggregate data only.** Never save or show student names, UIDs, emails, or
  per-student rows. To understand mistakes, count patterns across many
  submissions instead of reading individual ones. Refer to graders as G1, G2,
  and so on.
- **Ask only when blocked.** If you can't tell which course or assessment is
  meant, ask one question and recommend an answer. Otherwise make reasonable
  choices and state them in the report.

[references/data.md](references/data.md) covers data access, PrairieLearn
tables, starting queries, and known data quirks.

## Use PrairieLearn's terms

Use the terms instructors see in PrairieLearn and its documentation, and don't
invent labels:

- [Concepts](https://docs.prairielearn.com/concepts/): course, course instance,
  assessment, question, variant.
- [Assessment configuration](https://docs.prairielearn.com/assessment/configuration/):
  zones, question alternatives, `numberChoose`, `bestQuestions`, points lists,
  assessment instances.
- [Manual grading](https://docs.prairielearn.com/manualGrading/): rubrics and
  rubric items.

The docs call each entry in a zone's question list a *slot*. A slot with
alternatives gives each student one (or `numberChoose`) of them. Refer to a
question by its QID and by the number shown on the assessment's
**Questions** page, for example "question 6.2 (`OhareTrackComputeR`)".
Alternatives share the first number. Name course instances as PrairieLearn shows
them. When you must anonymize graders, say so once and call them "grader A",
"grader B", and so on.

## 1. Establish scope

1. Identify the course and assessment. Look for a course design guide or earlier
   reports, and use any goals you find, such as intended time or difficulty.
2. Choose the offerings:
   - **The current definition.** Fixes apply here. Check whether it has already
     been given; missing data doesn't mean it hasn't run. If you can't tell, ask
     or state your assumption.
   - **Past offerings of the same assessment.** Focus on the most recent ones
     with the same questions, and use older ones to check whether a pattern is
     stable. Confirm they match by comparing questions, not just names. If
     several course instances match a term, such as another campus, use the one
     with data and say so.
   - **Other assessments in the same course,** for comparison only. They show
     whether a pattern is specific to this assessment, for example whether every
     quiz got longer.
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
offerings separate; pool them only when their definitions are identical. When
students get many attempts at full value, first-submission scores and attempt
counts mean little; use per-part results on the best submission instead.

Then add the evidence that a given candidate needs:

- **Per part:** test results, per-input credit, rubric items, or option choices
  show which step students lose points on.
- **By generated parameters:** shows whether some random instances are harder.
- **Common wrong answers:** for example, answers that are off by a sign, use the
  wrong formula, or match a worked example.
- **Time pressure:** the share of students finishing near the time limit.
  Medians hide this when most students run to the end.
- **Effect on students:** points out of the assessment total that students who
  drew an alternative lost or gained, compared with the average of the other
  alternatives for that question.

## 3. Find candidates, then rule out other explanations

Candidates worth explaining:

- **Alternatives in one slot that differ** on score, full credit, time, attempts,
  or non-submission, especially when the gap repeats across offerings.
- **Similar scores that hide a workload difference.**
- **Questions far from the intended time or difficulty.** With no stated target,
  compare against the question the item replaced and other slots worth the same
  points.
- **Shifts between offerings,** for one question or the whole assessment.
- **Grading that differs** between alternatives or between graders.

Before you believe a candidate, rule out explanations that have nothing to do
with the question:

- **Small samples.**
- **Non-random assignment.** For example, a different alternative on different
  exam days. Check assignment by date. Without dates, compare each
  alternative's count with an even split.
- **Students choosing** which questions to attempt.
- **Stronger or weaker groups,** across terms or across exam days. Compare
  scores on questions that didn't change.
- **Score changes by staff,** including partial bumps, not only full credit.
- **Question edits between offerings.** Without source history, recompute stored
  answers from old variant parameters with the current code, or compare old
  grader messages with the current grader.
- **Course-wide changes,** such as a new format added to every quiz.
- **Time measurements that include idle time.**

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

Alternatives may differ on purpose, and a question may be hard on purpose. The
standard is **comparable difficulty and workload for everyone who could draw the
slot**, not identical questions. If a difference looks intentional, keep it, and
frame the problem as an unfair draw.

Test each explanation against the evidence from step 2. Does the step you
suspect have the lowest success rate? Do the wrong answers match the predicted
mistake?

Label each finding's confidence:

- **Observed:** the data shows it directly.
- **Likely:** the source and data support a cause, but haven't proven it.
- **Predicted:** found in the source only, with no student data yet.
- **Unexplained:** the gap is real, but no cause was found.

For Predicted and Unexplained findings, name the data that would settle it. Add a
few words when strength varies, for example: "Likely; reversed in one term."

## 5. Recommend edits

Give each finding the smallest change that fixes the problem and keeps what the
instructor intended. It can be:

- a question file
- an assessment setting, for example moving a question to another slot or giving
  everyone the hard question
- a rubric in PrairieLearn
- a process step, such as calibrating graders

Say "No edit needed" or "Already fixed in the current definition" when that's
the honest answer. Don't recommend grade changes yourself. If a past offering
was clearly unequal, state the effect in points and leave the decision to the
instructor.

## Report

Write `report.md` for the instructor, and save the queries, aggregate results,
and charts next to it. Use the folder the instructor names, or the course's
existing location for reports. Otherwise, use a new folder outside the course
repository. If you can't write the report file, return its text, and still save
the other files.

Make the report easy to scan. Use tables and charts for numbers, and write
findings as ideas: what about the question causes the problem, in plain words.
Use measures a reader understands without explanation, such as mean score, share
with full credit, minutes, and points out of the total. If you need anything less
familiar, define it in one sentence where it first appears.

Use these sections, adapting them to the assessment:

```markdown
# <Assessment>: diagnosis
<date> · <course instances analyzed> · <data source>

## Bottom line
<Up to five bullets, most important first: what to change and why.>

## Scope
<A table of the offerings analyzed: course instance, dates, number of students,
and anything that changes how to read them (structure changes, manual grading,
retakes). Then what was included and excluded, in a few bullets.>

## Results at a glance
<A summary table with one row per question in the main offering analyzed:
number, QID, points, number of students, mean score, full credit, no submission,
median minutes. Group alternatives together. Follow it with a chart
(references/plot_questions.py draws one from the starting query's output).>

## Findings
### <The idea, in a sentence: "6.5 needs the chain rule; 6.3 and 6.4 don't">
<A small table or two sentences of evidence, each number with its course
instance and n.>
**Why:** <cause in the source, with file path> (or "Unexplained: …")
**Confidence:** <label>
**Effect:** <points out of the assessment total, and for whom>
**Edit:** <concrete change, "No edit needed", or "Already fixed">

## Checked, no change needed
<One line each: alternatives that are well matched, gaps judged to be noise.>

## Questions for the instructor
<Only decisions you can't make. Omit the section if there are none.>

## Metric definitions
<A short table defining each measure used, and the filters applied (for example,
staff and test instances excluded).>

## Files
<The queries, results, and charts saved with the report, one line each.>
```

The bottom line, summary table, and chart should give the picture in a minute.
Keep each finding short, and order findings by effect on students: how many were
affected and by how much. Most reports have three to six findings. Merge related
minor ones, and move small issues to "Checked, no change needed". Put longer
method notes in an optional `details.md`.

## Before handing off

- Recompute the numbers each finding uses from the saved data.
- Confirm each finding cites a source or is marked Unexplained.
- Confirm the step 3 explanations were ruled out for each finding.
- Confirm no saved file contains student identifiers or per-student rows.
- Reread the bottom line: could the instructor act on it alone?

In chat, give two or three sentences and the report path. Keep the detail in the
report.
