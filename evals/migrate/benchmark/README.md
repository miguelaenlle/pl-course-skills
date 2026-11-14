# Does the migrate skill help, and does its script?

Benchmark for PrairieLearn/PrairieLearn#16408 (2026-11-14). The course agent's
model (`gpt-6-luna`, Codex CLI 0.164) ran four real term-to-term migrations in
three arms, three times each (36 runs, plus 12 reruns of the script arm):

- **none:** no skill
- **docs:** the skill's text with every mention of `shift_dates.py` removed (`arms/docs`)
- **full:** the skill as in the PR, with the 1,065-line script (`arms/full`)

Each run got a one-line instructor request plus "I can't answer questions
today, so tell me what you propose and then go ahead with your recommended
defaults." Web search was on in every arm. Fixtures are the real courses without
`questions/`, with the target course instance removed and every UID and
personal address replaced (`build_fixture.py`).

`score.py` checks the result without using the script. `script alone` rows are
the script with reference calendars and no agent.

## Results (three runs per cell, shown as run 1/2/3)

| Task                | Arm          | Same week of instruction | Deadlines on holidays or in breaks | UID rules left | Within 3 days of instructor's real instance |
| ------------------- | ------------ | ------------------------ | ---------------------------------- | -------------- | ------------------------------------------- |
| CS 357 Sp26 → Fa26  | none         | 65/65/65%                | 7/7/7                              | 89/89/0        | 62/62/62%                                   |
|                     | docs         | 97/97/100%               | 0/0/0                              | 0/0/0          | 94/94/94%                                   |
|                     | full         | 100/100/100%             | 0/0/0                              | 0/0/0          | 94/94/94%                                   |
|                     | script alone | 100%                     | 0                                  | 0              | 94%                                         |
| CS 357 Fa26 → Sp27  | none         | 64/51/64%                | 5/19/5                             | 0/0/0          | (no real instance yet)                      |
|                     | docs         | 99/99/99%                | 0/0/0                              | 0/0/0          |                                             |
|                     | full         | 98/98/98%                | 0/0/0                              | 0/0/0          |                                             |
| TAM 212 Sp26 → Fa26 | none         | 65/49/65%                | 4/4/4                              | 0/48/49        | 41/33/41%                                   |
|                     | docs         | 96/**9**/98%             | 0/0/0                              | 0/0/0          | 44/29/44%                                   |
|                     | full         | 100/**5**/**5**%         | 0/1/1                              | 0/0/0          | 44/20/20%                                   |
|                     | script alone | 100%                     | 1                                  | 0              | 62%                                         |
| ZJUI Sp25 → Sp26    | none         | 82/82/82%                | 0/0/0                              | 0/0/0          | 38/38/40%                                   |
|                     | docs         | 9/27/9%                  | 0/0/0                              | 0/0/0          | 2/12/2%                                     |
|                     | full         | 18/✗/9%                  | 0/✗/0                              | 0/✗/0          | 7/✗/2%                                      |
|                     | script alone | 100%                     | 0                                  | 0              | 69%                                         |

✗: this run wrote the ZJUI copy over the existing UIUC `Spring2026` course
instance (37 files changed, 13 assessments deleted) instead of making a new one.

Apart from the ✗ run, no run edited anything outside the new instance, and no
run produced a file that fails the JSON schemas. One run left stale dates in
synced assessments (no-skill TAM 212 run 2, 12 dates).

## End-to-end time and what the agent ran

| Arm  | Minutes: median (range) | Input tokens (mostly cached) | Output tokens | Shell commands | Own Python snippets: count, lines |
| ---- | ----------------------- | ---------------------------- | ------------- | -------------- | --------------------------------- |
| none | 1.7 (0.7 to 2.9)        | 0.31M                        | 3.6k          | 10             | 4, 57                             |
| docs | 5.3 (2.1 to 10.1)       | 0.74M                        | 14.9k         | 14             | 9, 170                            |
| full | 6.4 (3.6 to 12.0)       | 1.40M                        | 18.3k         | 19             | 8, 93                             |

Median minutes by task (none / docs / full):

- CS 357 Sp26 → Fa26: 1.7 / 2.6 / 6.3
- CS 357 Fa26 → Sp27: 1.2 / 4.2 / 4.9
- TAM 212 Sp26 → Fa26: 1.6 / 6.0 / 8.1
- ZJUI Sp25 → Sp26: 1.8 / 7.2 / 8.8

The agent writes its own code in every arm. Each snippet is an inline
`python3 - <<EOF` run once; none was saved as a file. Without the script it
writes about 170 lines per run to scan dates, map them, rewrite the files and
check the result. With the script it still writes about 90 lines per run to
inspect the course, edit `plan.csv`, and make the changes the script doesn't
(the new UUID, `publishing`, stale practice quizzes), and it reads parts of the
script's source in most runs. Every script-arm run did call the script.

The `full` rows are the reruns. In the first 12 script runs `python3` resolved
to macOS's Python 3.9, which the script doesn't support (the image has 3.11),
so every run lost steps to that error. Those runs are kept as `full-py39` in
`results/`. Their outcomes were about the same and their median time was 5.3
minutes, so fixing the interpreter did not make the script arm faster.

Full table: `results/scores.tsv`; final messages: `results/finals/`.

## What it shows

1. **The skill text matters.** Without it the agent never looked up a calendar
   (1 web search in 12 runs). It shifted every date by a fixed number of days
   (217 for spring to fall), which puts a third to a half of the dates in the
   wrong week of instruction and 4 to 19 deadlines on holidays or in breaks.
   It left per-student rules in 4 of 12 runs and changed times of day in 3.
2. **The script doesn't improve the outcome and doesn't save time.** With the
   same text and no script, the agent got to the same place: 96 to 100% week
   alignment against 98 to 100%, no conflicts, no UID rules. The script arm
   took about a minute longer per run and used about 1.9 times the input
   tokens. What the script adds is exactness (docs was off by a few dates in 2
   of 3 runs of the first CS 357 task) and a fixed set of outputs (`plan.csv`,
   `moves.md`).
3. **The weak step is finding the calendar, and neither arm of the skill helps
   there.** Texas A&M's calendar was used for "TAM 212" in 1 of 3 text-only
   runs and 3 of 6 script runs. Every skill run on ZJUI missed that the term
   starts before Spring Festival and squeezed the course into 12 weeks; one
   made Spring 2027 instead and one overwrote another course instance. On ZJUI
   the no-skill arm's 364-day shift was closer to what the instructor did than
   either skill arm. The script with the right calendar scores 69% there.

## Limits

- Three runs per cell, one model, one turn with no instructor to answer.
- The fixtures don't name the institution: replacing UIDs removed the
  `@illinois.edu` addresses, which may be what led to the Texas A&M calendar.
- Only dates and rules are scored. The proposal message, the moves table, and
  how small the diff is are not, and those are things the script is for.
- Nothing was synced in PrairieLearn.
- "Same week of instruction" uses reference calendars from earlier test runs.
- Snippet counts cover inline Python only, not shell one-liners.

## Rerun

```sh
python3 build_fixture.py COURSE_REPO WORK/fixtures/TASK --remove TARGET_INSTANCE
PYTHON=/path/to/python3.10+ ./run.sh WORK TASK ARM REP
python3 score.py WORK COURSES_DIR PRAIRIELEARN/apps/prairielearn/src/schemas/schemas
```
