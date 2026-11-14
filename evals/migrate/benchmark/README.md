# Does the migrate skill help, and does its script?

Benchmark for PrairieLearn/PrairieLearn#16408 (2026-11-14). The course agent's
model (`gpt-6-luna`, Codex CLI 0.164) ran four real term-to-term migrations in
three arms, three times each (36 runs):

- **none:** no skill
- **docs:** the skill's text with every mention of `shift_dates.py` removed (`arms/docs`)
- **full:** the skill as in the PR, with the 1,065-line script (`arms/full`)

Each run got a one-line instructor request plus "I can't answer questions
today, so tell me what you propose and then go ahead with your recommended
defaults." Web search was on in every arm. Fixtures are the real courses without
`questions/`, with the target course instance removed and every UID and
personal address replaced (`build_fixture.py`).

`score.py` checks the result without using the script. `script` rows are the
script alone with reference calendars and no agent; `instructor` rows are the
instance the instructor really made.

## Results (three runs per cell, shown as run 1/2/3)

| Task                | Arm          | Same week of instruction | Deadlines on holidays or in breaks | UID rules left | Within 3 days of instructor's real instance |
| ------------------- | ------------ | ------------------------ | ---------------------------------- | -------------- | ------------------------------------------- |
| CS 357 Sp26 → Fa26  | none         | 65/65/65%                | 7/7/7                              | 89/89/0        | 62/62/62%                                   |
|                     | docs         | 97/97/100%               | 0/0/0                              | 0/0/0          | 94/94/94%                                   |
|                     | full         | 100/99/99%               | 0/0/0                              | 0/0/0          | 94/94/94%                                   |
|                     | script alone | 100%                     | 0                                  | 0              | 94%                                         |
| CS 357 Fa26 → Sp27  | none         | 64/51/64%                | 5/19/5                             | 0/0/0          | (no real instance yet)                      |
|                     | docs         | 99/99/99%                | 0/0/0                              | 0/0/0          |                                             |
|                     | full         | 99/98/98%                | 0/0/0                              | 0/0/0          |                                             |
| TAM 212 Sp26 → Fa26 | none         | 65/49/65%                | 4/4/4                              | 0/48/49        | 41/33/41%                                   |
|                     | docs         | 96/**9**/98%             | 0/0/0                              | 0/0/0          | 44/29/44%                                   |
|                     | full         | 100/**5**/100%           | 0/1/0                              | 0/0/0          | 44/20/44%                                   |
|                     | script alone | 100%                     | 1                                  | 0              | 62%                                         |
| ZJUI Sp25 → Sp26    | none         | 82/82/82%                | 0/0/0                              | 0/0/0          | 38/38/40%                                   |
|                     | docs         | 9/27/9%                  | 0/0/0                              | 0/0/0          | 2/12/2%                                     |
|                     | full         | 9/9/0%                   | 0/0/0                              | 0/0/0          | 2/2/0%                                      |
|                     | script alone | 100%                     | 0                                  | 0              | 69%                                         |

Median cost per run:

| Arm  | Minutes | Input tokens (mostly cached) | Output tokens | Shell commands |
| ---- | ------- | ---------------------------- | ------------- | -------------- |
| none | 1.7     | 0.31M                        | 3.6k          | 10             |
| docs | 5.3     | 0.74M                        | 14.9k         | 13             |
| full | 5.3     | 1.30M                        | 15.7k         | 24             |

No run edited the source instance or anything outside the new one, left a
stale date in a synced assessment, or produced a file that fails the JSON
schemas. Full table: `results/scores.tsv`; final messages: `results/finals/`.

## What it shows

1. **The skill text matters.** Without it the agent never looked up a calendar
   (1 web search in 12 runs). It shifted every date by a fixed number of days
   (217 for spring to fall), which puts a third to a half of the dates in the
   wrong week of instruction and 4 to 19 deadlines on holidays or in breaks.
   It left per-student rules in 4 of 12 runs and changed times of day in 3.
2. **The script makes no measurable difference to the outcome.** With the same
   text and no script, the agent wrote its own 100 to 400 lines of throwaway
   Python each run and got to the same place: 96 to 100% week alignment
   against 98 to 100%, no conflicts, no UID rules. Wall time was the same. The
   script arm used about 1.8 times the input tokens and twice the commands.
   What the script adds is exactness (docs was off by a few dates in 2 of 3
   CS 357 runs) and a fixed set of outputs (`plan.csv`, `moves.md`).
3. **The weak step is finding the calendar, and neither arm of the skill helps
   there.** Both skill arms used Texas A&M's calendar for "TAM 212" in one run
   of three, and all six ZJUI runs missed that the term starts before Spring
   Festival, so they squeezed the course into 12 weeks; one made Spring 2027
   instead. On ZJUI the no-skill arm's 364-day shift was closer to what the
   instructor did than either skill arm. The script with the right calendar
   scores 69% there.

## Limits

- Three runs per cell, one model, one turn with no instructor to answer.
- The fixtures don't name the institution: replacing UIDs removed the
  `@illinois.edu` addresses, which may be what led to the Texas A&M calendar.
- Only dates and rules are scored. The proposal message, the moves table, and
  how small the diff is are not, and those are things the script is for.
- Nothing was synced in PrairieLearn.
- "Same week of instruction" uses reference calendars from earlier test runs.

## Rerun

```sh
python3 build_fixture.py COURSE_REPO WORK/fixtures/TASK --remove TARGET_INSTANCE
./run.sh WORK TASK ARM REP
python3 score.py WORK COURSES_DIR PRAIRIELEARN/apps/prairielearn/src/schemas/schemas
```
