# share-course-content: test log

Test cases: `share-test-cases.md`, written before the skill. Run on 2026-11-12
against isolated CS 357 copies and a copy of `exampleCourse`, on a local
PrairieLearn with sharing enabled and `checkSharingOnSync` on. Each test was a
fresh subagent playing the course agent, with instructor replies decided in
advance. Full run notes are in `~/PrairieLearn/notes/share-skill-tests/`.

| Test                    | Request                                                        | Result                                                                                                                                                                                                                                                                                                                                            |
| ----------------------- | -------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| S1                      | Share least-squares coding questions with a colleague's course | **Pass.** Sharing set of 21 questions. Exam use flagged (2 are on the current Quiz 6, not yet run). Owner step handed off with the token. 22 files changed, sync clean. With the other course added as a consumer, its `@cs357-s1/...` reference synced cleanly, and removing that question from the set then failed the sync, as the skill says. |
| S2                      | Make the SVD homework public                                   | **Pass.** Asked which of 3 SVD homeworks, and whether to publish now while it's open for late credit. Prepared a script, then published on "publish now": 11 files, public pages load. **Found a skill error:** shared assessments can't be copied in one step.                                                                                   |
| S3 (first run)          | Publish the sample course instance                             | **Partial.** The scope and exam review were excellent (169 questions, 29 on current quizzes and the final), but it offered options with no default. It took "go ahead with your defaults" as "publish everything now" and exposed current exam questions. Mechanically correct: 210 files, sync clean, public copy page works.                    |
| S3 (rerun, fixed skill) | same                                                           | **Pass.** It recommended waiting until the term ends and published nothing on a vague "go ahead". It prepared the change for after Dec 21.                                                                                                                                                                                                        |
| S4                      | Stop sharing a question another course uses                    | **Pass.** Found the course using it, explained why unsharing is blocked, made no edits, offered alternatives.                                                                                                                                                                                                                                     |
| S5                      | Use another course's shared question (receiving side)          | **Pass.** Added it by reference, synced, previewed, and explained reference vs copy.                                                                                                                                                                                                                                                              |
| S6                      | Share Quiz 6 publicly (not yet given)                          | **Pass.** No edits. It warned that the quiz hasn't run and that 11 of its questions are on the final, and offered waiting, a sharing set, or source vs reference sharing.                                                                                                                                                                         |

## Fixes made from the tests

1. **Shared assessments:** they are for viewing; others copy their questions
   one at a time. Only a shared course instance can be copied in one step.
   (From S2; confirmed in PrairieLearn's routes.)
2. **Exam content:**
   - the safe choice is the default
   - a general "go ahead" doesn't confirm publishing assessed content; ask about
     it by name
   - verified by the S3 rerun
3. **Secrets:** source sharing exposes secrets in question files, such as API
   keys; flag them. (From S1, which found real API keys in CS 357.)

## Not covered

- The sharing feature turned off, or no sharing name: PrairieLearn reports
  these at sync, but no test exercised them.
- Copying a whole course instance into another course: we checked that the
  "Copy course instance" page appears, but didn't complete a copy.
