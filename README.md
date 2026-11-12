# PrairieLearn course skills

Agent skills for PrairieLearn course staff, developed for PrairieLearn course agents.
Each skill is a folder containing a `SKILL.md` with `name` and `description`
frontmatter, usable by Claude Code and Codex.

## Skills

- [`diagnose-assessment-issues`](skills/diagnose-assessment-issues/SKILL.md):
  find alternatives that aren't comparable, questions that miss their time or
  difficulty targets, and grading problems, explain each from the question
  source, and recommend edits. Read-only.
- [`author-questions`](skills/author-questions/SKILL.md): create or edit
  questions and assessment settings, then verify them in PrairieLearn: bulk
  variant checks, rendered screenshots, and grading with correct and wrong
  answers.
- [`migrate-course-instance`](skills/migrate-course-instance/SKILL.md): set up
  a course instance for a new term. It moves every date onto the new term's
  academic calendar (by week of instruction, skipping breaks), clears UID rules
  and per-student overrides, flags conflicts and leftover dates, and verifies
  the result.
- [`share-course-content`](skills/share-course-content/SKILL.md): share
  questions, assessments, or course instances with specific courses or
  publicly, stop sharing, or use another course's shared questions. It picks
  the mechanism from who the content is for, checks that everything needed is
  shared, and warns before anything irreversible or before publishing exam
  content.
- [`improve-assessment`](skills/improve-assessment/SKILL.md): investigate past
  results, prototype question changes with instructor feedback, then finalize an
  assessment locally. Copied unchanged from the course-agent worktree
  (`apps/course-agent/skills/improve-assessment`) as the starting point.

## Workflow: build the next version of an assessment

How the skills chain when an instructor says "Build a new Quiz 6 from past
quizzes":

1. **Diagnose** (`diagnose-assessment-issues`). The report covers past results
   for every question, grouped by slot so alternatives sit side by side.
2. **Decide.** The instructor sets the goals for the new version: what to keep,
   targets, and allowed methods.
3. **Find starting points and propose** (`author-questions`, step 1). Compare
   existing questions in a table, then write a spec for each new question,
   with a side-by-side table for alternatives. The instructor says yes or
   adjusts.
4. **Build one, review, then match** (`author-questions`, steps 3–4). Build the
   first alternative, verify it in PrairieLearn, show it, then build the
   matched one. Wording fixes go to every alternative.
5. **Hand off** with the branch, how to preview locally, and the targets to
   measure next term.

## Docs

- [`docs/assessment-skill-plan.md`](docs/assessment-skill-plan.md): what CS 357's
  agent-written reports contain, where `improve-assessment` falls short, and the
  proposed split into smaller skills.
- [`evals/cs357-gold-findings.md`](evals/cs357-gold-findings.md): findings from the
  CS 357 reports, used to score replays of `diagnose-assessment-issues`.
- [`evals/diagnose-test-log.md`](evals/diagnose-test-log.md): test rounds, what
  changed after each, and known limits.
- [`evals/author-test-log.md`](evals/author-test-log.md): authoring tests, what
  changed after them, and known limits.
- [`evals/migrate-test-log.md`](evals/migrate-test-log.md): replays of real
  CS 357 and TAM 212 term copies, three instructor-style migration runs, and
  fixes.
- [`evals/share-test-cases.md`](evals/share-test-cases.md) and
  [`evals/share-test-log.md`](evals/share-test-log.md): sharing-skill test
  cases (written before the skill) and their results.
- [`evals/case-studies/`](evals/case-studies/): evidence behind the deck's three
  case studies.
- [`presentations/course-agent-skills/`](presentations/course-agent-skills/):
  source for the "Course agent skills" deck.
