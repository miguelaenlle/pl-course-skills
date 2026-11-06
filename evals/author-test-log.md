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

## Third test: CS 357 Quiz 3, Fall 2026

Done on November 6 to give the deck a second CS 357 case study. The request
used the diagnosis numbers: in course instance Fall 2026, assessment `quiz3`,
question 10's alternatives `Linsys-SurveyElevations` (10.2, 24.7%, n=160) and
`Linsys-MenuPrices` (10.1, 50.4%, n=201) weren't comparable. The 24.7% is
before a staff score adjustment on October 25.

The agent:

- added a fully worked A and b example to both alternatives, so their
  scaffolding stays matched
- made both graders name the incorrect rows of A
- left `server.py`, the grading weights and the assessment unchanged

Checks:

- **Grading in PrairieLearn (Docker):** reference solutions scored 100% on
  both. Typical mistakes kept their earlier partial credit (for example,
  benchmark row first 20%, signs swapped about 33%), now with row-level
  feedback.
- **My review:** I checked the diff, the worked example's arithmetic (lake 240,
  hill 252, cabin 247), and the before, after, and graded screenshots.

Gaps it found in the skill:

- no harness for running an external grader directly
- an exception in student code zeroes every test in the Python autograder
- no guidance on choosing matched scaffolding vs. helping only the weaker
  alternative
- looking at several variants tells you little for single-variant code
  questions
- feedback renders in a non-wrapping block

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
