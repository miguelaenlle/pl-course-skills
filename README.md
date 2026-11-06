# PrairieLearn course skills

Agent skills for PrairieLearn course staff, developed for PrairieLearn course agents.
Each skill is a folder containing a `SKILL.md` with `name` and `description`
frontmatter, usable by Claude Code and Codex.

## Skills

- [`diagnose-assessment-issues`](skills/diagnose-assessment-issues/SKILL.md):
  find alternatives that aren't comparable, questions that miss their time or
  difficulty targets, and grading problems, explain each from the question
  source, and recommend edits. Read-only.
- [`improve-assessment`](skills/improve-assessment/SKILL.md): investigate past
  results, prototype question changes with instructor feedback, then finalize an
  assessment locally. Copied unchanged from the course-agent worktree
  (`apps/course-agent/skills/improve-assessment`) as the starting point.

## Docs

- [`docs/assessment-skill-plan.md`](docs/assessment-skill-plan.md): what CS 357's
  agent-written reports contain, where `improve-assessment` falls short, and the
  proposed split into smaller skills.
- [`evals/cs357-gold-findings.md`](evals/cs357-gold-findings.md): findings from the
  CS 357 reports, used to score replays of `diagnose-assessment-issues`.
- [`evals/diagnose-test-log.md`](evals/diagnose-test-log.md): test rounds, what
  changed after each, and known limits.
