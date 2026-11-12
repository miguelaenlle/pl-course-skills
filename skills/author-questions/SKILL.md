---
name: author-questions
description: >-
  Create or edit PrairieLearn questions and the assessment settings that use
  them, then verify the result by rendering and grading it in PrairieLearn. Use
  for requests such as "Fix the prompt in question 6.2", "Make these two
  alternatives comparable", "Add a variant like this one", "Write a new
  least-squares coding question for Quiz 6", or carrying out edits recommended
  by diagnose-assessment-issues.
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
  affect only new variants, and grading edits apply to new submissions. A
  question is shared by every assessment that lists it, in every course
  instance, so an edit changes all of them. If any of those assessments is open
  or already given, say what the edit means for students who've already started.
  If you can't tell whether an exam is running, say so, and advise waiting to
  sync until it ends.
- **Treat names students see as part of the question.** Function names, variable
  names, answer labels, and test names appear in prompts, starter code, and
  feedback. Change them only when the task needs it, and say so.
- **Ask only when blocked, except for new designs.** Choose sensible defaults for
  fixes and routine decisions, and list them in your handoff. A new question or
  a new alternative is a design decision: propose it first (step 1).

[references/docs.md](references/docs.md) maps tasks to PrairieLearn
documentation pages. Read the relevant page before using an element attribute or
`server.py` feature you haven't confirmed in the docs.

## 1. New questions: agree on the design first

Skip this step for edits to an existing question.

1. **Find starting points.** Search the course for questions on the same topic
   (QIDs, titles, tags, and the assessments that use them). Show the best three
   to five in a table: QID, what students do, method required or banned, grading
   split, past results if available, and what you would change. Recommend one.
2. **Propose before building.** Write a short spec and wait for a yes:
   - the story, in one or two sentences
   - the math or model students work with
   - what students submit, and how each part is graded
   - which methods are allowed or banned, and how the prompt states that
   - the difficulty you expect, compared with the starting point
   - for alternatives, a side-by-side table (below)

   If the instructor gave a target, such as a mean of 35–55%, say whether the
   design can plausibly hit it. A target is a goal, not a prediction.
   Before promising one, run the methods students are likely to use on the
   starting point's generator, for example a library solver against the method
   being taught. Check which answers each method gets right and wrong, and how
   well conditioned the reference method is. Allowed functions can quietly make
   a "hard" question easy, or a reference answer fragile.

   For past results, check which assessments each candidate ran on. Results
   from finals, homework, or practice may not be in the data you have.
3. **Build one, then match it.** When the instructor wants several
   alternatives, build and review the first before writing the others.
4. **Check the other slots.** Compare the new question with the rest of the
   assessment. If a student would solve it the same way as another slot's
   question, say so before building.

### Designing alternatives for one slot

Students who draw different alternatives should face the same difficulty and
workload, and the alternatives should not be clones. Unless the instructor says
otherwise:

- **Change the surface a lot:** story, context, units, and variable names.
- **Change the math a little, and the same way in every alternative.** Give
  each alternative the same kind of twist, such as one transformed model term
  each, not an extra step in one of them.
- **Keep tests, outputs, partial credit, and feedback identical** or nearly so.
  Output names may follow the story (`predicted_profits`, `predicted_energy`).
  Everything else in the tests should match.
- **Before building, count the work.** List each alternative's steps,
  operations, and special cases side by side, and confirm the counts match.
  When one alternative's twist is less familiar to students (1/v against x²),
  say so, and add it to what to measure next term.

## 2. Understand the question before editing

- Read the whole question: `info.json`, `question.html`, `server.py`, and any
  tests, starter code, and files it uses.
- Find every assessment that lists it (search `infoAssessment.json` files for the
  QID), its alternatives, and its points. To tell which one the instructor means
  and whether it's open, check the course instance's dates and the assessment's
  access rules. Exams run through PrairieTest may not show their dates in the
  course files.
- Open it in PrairieLearn and look at a few variants as students would see them.
- Look at two or three similar questions in the same course, and follow their
  conventions for wording, elements, tolerances, partial credit, and file layout.
- If the edit comes from a diagnosis, reread the finding. Know what evidence the
  edit should change.

## 3. Make the change

- **Make the smallest change that does the job.** Prefer a sentence, a parameter
  range, a test case, or a grading weight over a rewrite.
- **Edit alternatives as a set.** When making alternatives comparable, list what
  each one asks students to do: steps, outputs, scaffolding, test cases, grading
  weights. Then change only the differences that affect difficulty or workload.
  Keep intended differences. Apply a fix or wording change to every alternative
  that has the same problem, without being asked, and say which ones you
  changed.
- **Write prompts that say what, not how.** Check that:
  - every symbol and variable is defined, with units ("P(p) is the daily profit
    in dollars at price p")
  - every requested output says what it holds ("predictions: the predicted
    profit at each price in test_prices")
  - the prompt doesn't hint at the intended method or model choice, unless the
    instructor wants scaffolding (ask once)
  - restrictions are stated without naming the intended method
  - headings and phrasing follow the course's existing questions (for example,
    a "Note" section rather than a new heading)
- **Make the graded answer unique.** If more than one answer is correct, such as
  coefficients for a rank-deficient fit, pick one approach and show the
  instructor the exact wording:
  - grade a quantity that is unique, such as predictions or residuals
  - grade how well the answer fits, by comparing A·c with the reference
  - state a conditional rule that picks one answer ("If more than one set
    achieves this minimum, report the one with the smallest 2-norm"), which
    doesn't reveal why answers can differ
- **New questions start from the closest existing question.** Copy its folder,
  give the copy a new QID and a new UUID, then edit. Never reuse a UUID, and
  never rename a question folder that assessments already list.
- **Use first-party elements** and set `correct_answers` whenever possible.
  Element grading, feedback, and the built-in tests then work without extra code.
- **Assessment changes** (moving a question, changing alternatives or points)
  go in `infoAssessment.json`. Keep totals and alternatives consistent, and note
  what changes for students.

## 4. Verify in PrairieLearn

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
     the question is randomized. Long runs can take several minutes; wait for the
     job page to finish.
   - Submit the correct answer in the preview and confirm full credit. The
     staff-only **Show/Hide answer** panel shows each variant's correct answer.
   - Submit two or three plausible mistakes (sign error, wrong formula,
     incomplete answer) and confirm the score and feedback are what you
     intended. For randomized questions, repeat this on several variants;
     scripting the browser makes that quick.
   - For externally graded code, see below.
   **Externally graded code questions** need a different routine. They have no
   built-in test buttons, and their randomness often lives in the test files
   rather than in `server.py`, so new variants and the sampler show nothing new.
   Instead:
   - Run the grader's own generator and reference solution many times outside
     PrairieLearn, and confirm every case is valid and behaves as intended.
   - In the preview, submit the reference solution and two or three common wrong
     solutions. Confirm each score and feedback message. Submit each more than
     once, because the tests can draw new cases on every run.
   - If the question bans functions, submit a solution that uses a banned
     function and confirm it is rejected or gets no credit, and one that uses
     the intended method and gets full credit. In common external graders, a
     banned call raises an exception that stops all tests. A local test script
     that keeps going would overstate partial credit, so confirm the score in
     the real grader. The reference answer runs in the same process as the
     setup code, so it can't call a function the setup bans.
   - To submit code from a script, use the page's editor:
     `ace.edit(document.querySelector('.ace_editor')).setValue(code)`. Then
     click `button[name=__action][value=grade]` and read the score from
     `[id^=submission-]`.
   - If grading in the preview stays stuck, wait for the grader image to
     download, then resubmit. You can also run the grader image directly with
     Docker.
5. **Compare alternatives, and the other slots.** Put the alternatives side by
   side in a table: what each asks for, its inputs or outputs, and its grading
   weights. Confirm they match where they should. Then compare with the other
   slots in the assessment, and flag any question a student would solve the
   same way as another.
6. **Check the assessment** if you changed it: it loads, the questions and
   alternatives are right, and the point total is as intended.

If a check can't run, for example because no PrairieLearn server is available or
Docker is missing, say exactly which checks didn't run. Don't describe the
change as verified.

## Handoff

Tell the instructor, briefly:

- what changed and why, file by file
- where the work is: branch, worktree path, and whether it is committed
- how to preview it: links, or the exact commands to run PrairieLearn on this
  checkout locally, and the PrairieLearn or grader image version used
- what you verified, with screenshots of the rendered question, and what you
  couldn't verify
- anything students who already started will see differently
- the target for each new question, such as a mean of 35–55%, and what to
  measure next time the assessment runs, so the effect can be checked

Don't paste whole files. Point to the changed files, and let the diff show the
details.
