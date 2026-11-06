# `author-questions` test log

November 6, 2026. Each test agent worked in its own clone of a course
repository, with a git baseline commit so its changes could be reviewed as a
diff. A local PrairieLearn server loaded both clones, with Docker and the Python
grader image available. I reviewed every diff and checked the rendered questions
myself in the browser.

Both tasks came from findings made by `diagnose-assessment-issues`.

| Task | Question type | Result |
| --- | --- | --- |
| TAM 212: about half the variants of `particleVelonTriCurveSpeed` have answer 0; fix it without changing what the question asks | Numeric, randomized `server.py` | One-function change to `generate()`, keeping only points where the slope isn't zero. The sampler went from 50% zero answers to none in 500 seeds. Built-in tests passed 300 of 300. Correct answers got full credit and plausible mistakes got none. I confirmed the renders. |
| CS 357: make Terrain and Temperature comparable, keeping the saddle-point case; fix Terrain's contradictory wording | Externally graded Python code | Added a saddle case and a third test to Temperature, fixed its reference solution, and fixed both prompts. Graded in PrairieLearn with Docker, the two alternatives now score identically: reference 15/15, two-way classifier 13.33/15, wrong value 10/15. I confirmed the renders and reviewed the diff. |

## What changed in the skill after testing

- Editing a question changes it everywhere it's used, across every course
  instance.
- How to tell which assessment is meant and whether it's open, and what to say
  when that can't be determined (exams run through PrairieTest).
- Names students see (function names, answer labels, test names) are part of
  the question.
- When fixing one alternative, check whether the others have the same problem.
- Grading checks on several variants, using the staff answer panel.
- A separate verification routine for externally graded code questions.
- The sampler's zero check now uses a tolerance relative to the values' scale.

## Known limits

- Only two tasks, both edits to existing questions. Creating a new question or
  pool from scratch hasn't been tested.
- No manually graded or workspace questions yet.
- Tested on a local development server, not in the course agent.
- The Playwright browser was shared between the two parallel agents, so they
  interfered with each other's tabs. Separate browser contexts would avoid that
  in future test rounds.
