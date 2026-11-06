---
name: author-questions
description: >-
  Create or edit PrairieLearn questions and the assessment settings that use
  them, then verify the result by rendering and grading it in PrairieLearn. Use
  for requests such as "Fix the prompt in question 6.2", "Make these two
  alternatives comparable", "Add a variant like this one", or carrying out edits
  recommended by diagnose-assessment-issues.
---

# Author questions

When you're done, the instructor should be able to preview the change and trust
it. Specifically, the question:

- renders cleanly in every variant
- gives full credit to correct answers
- gives the intended credit to plausible mistakes
- still matches its alternatives

A change isn't done until you've seen it work in PrairieLearn. Reading the code
and believing it's right isn't enough.

## Boundaries

- **Edit only what the task needs,** in the course checkout you were given.
  Don't push, publish, sync to production, or change grades.
- **Keep the instructor's intent.** Change what was asked, and say so before
  changing anything else, such as difficulty, topic, or what a question asks for.
- **Questions that students have already seen need care.** Edits to `generate()`
  affect only new variants, and grading edits apply to new submissions. If a
  question is in an assessment that's open or already given, say what the edit
  means for students who've already started.
- **Ask only when blocked.** Choose sensible defaults for routine decisions and
  list them in your handoff.

[references/docs.md](references/docs.md) maps tasks to PrairieLearn
documentation pages. Read the relevant page before using an element attribute or
`server.py` feature you haven't confirmed in the docs.

## 1. Understand the question before editing

- Read the whole question: `info.json`, `question.html`, `server.py`, and any
  tests, starter code, and files it uses.
- Find every assessment that lists it (search `infoAssessment.json` files for the
  QID), its alternatives, and its points.
- Open it in PrairieLearn and look at a few variants as students would see them.
- Look at two or three similar questions in the same course, and follow their
  conventions for wording, elements, tolerances, partial credit, and file layout.
- If the edit comes from a diagnosis, reread the finding. Know what evidence the
  edit should change.

## 2. Make the change

- **Make the smallest change that does the job.** Prefer a sentence, a parameter
  range, a test case, or a grading weight over a rewrite.
- **Edit alternatives as a set.** When making alternatives comparable, list what
  each one asks students to do: steps, outputs, scaffolding, test cases, grading
  weights. Then change only the differences that affect difficulty or workload.
  Keep intended differences.
- **New questions start from the closest existing question.** Copy its folder,
  give the copy a new QID and a new UUID, then edit. Never reuse a UUID, and
  never rename a question folder that assessments already list.
- **Use first-party elements** and set `correct_answers` whenever possible.
  Element grading, feedback, and the built-in tests then work without extra code.
- **Assessment changes** (moving a question, changing alternatives or points)
  go in `infoAssessment.json`. Keep totals and alternatives consistent, and note
  what changes for students.

## 3. Verify in PrairieLearn

Use a running PrairieLearn that loads this course checkout, such as the course
agent's preview or a local development server. Then:

1. **Sync.** Load the course from disk and confirm the question and assessment
   have no sync errors or warnings.
2. **Check generated variants in bulk.** For questions with `server.py`, run
   [references/sample_variants.py](references/sample_variants.py) to generate
   hundreds of variants. Look for errors, values outside the intended range,
   answers that are zero or undefined, and cases that are far more common than
   intended.
3. **Look at it.** Open the question preview, take a screenshot, and look at it
   yourself. Do this for at least three variants (use **New variant**), and
   check:
   - math and figures render
   - no unfilled `{{ }}` or raw markup
   - inputs are labeled
   - the wording matches what is graded
4. **Grade it.**
   - Run the built-in tests from the question's **Settings** tab, many times if
     the question is randomized.
   - Submit the correct answer in the preview and confirm full credit.
   - Submit two or three plausible mistakes (sign error, wrong formula,
     incomplete answer) and confirm the score and feedback are what you
     intended.
   - For externally graded code, submit a reference solution and common wrong
     solutions; this needs Docker.
5. **Compare alternatives.** When you changed one of several alternatives, put
   them side by side in a table: what each asks for, its inputs or outputs, and
   its grading weights. Confirm they now match where they should.
6. **Check the assessment** if you changed it: it loads, the questions and
   alternatives are right, and the point total is as intended.

If a check can't run, for example because no PrairieLearn server is available or
Docker is missing, say exactly which checks didn't run. Don't describe the
change as verified.

## Handoff

Tell the instructor, briefly:

- what changed and why, file by file
- how to preview it, with links when available
- what you verified, with screenshots of the rendered question, and what you
  couldn't verify
- anything students who already started will see differently
- what to measure next time the assessment runs, so the effect can be checked

Don't paste whole files. Point to the changed files, and let the diff show the
details.
