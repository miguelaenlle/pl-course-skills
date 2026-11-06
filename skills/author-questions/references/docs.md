# PrairieLearn documentation for question authoring

The documentation is published at <https://docs.prairielearn.com/>. The same
pages are in the PrairieLearn repository under `docs/` (for example,
`docs/question/server.md`), so read the local copy when the repository is
available. Read the page for whatever you're about to change; don't rely on
memory for element attributes or `server.py` behavior.

| Task | Page |
| --- | --- |
| How courses, questions, variants, and assessments fit together | [Concepts](https://docs.prairielearn.com/concepts/) |
| Question folder layout, `info.json`, partial credit | [Questions](https://docs.prairielearn.com/question/overview/) |
| `info.json` fields | [infoQuestion schema](https://docs.prairielearn.com/schemas/infoQuestion/) |
| `question.html`: panels, Mustache, Markdown, LaTeX | [question.html](https://docs.prairielearn.com/question/template/) |
| `server.py`: `generate`, `prepare`, `parse`, `grade`, `test`, feedback, files | [server.py](https://docs.prairielearn.com/question/server/) |
| Choosing and configuring input elements | [Elements](https://docs.prairielearn.com/elements/), then the element's own page, such as [pl-number-input](https://docs.prairielearn.com/elements/pl-number-input/) |
| Python version and available libraries | [Runtime](https://docs.prairielearn.com/question/runtime/) |
| Accessibility of prompts, figures, and inputs | [Accessibility](https://docs.prairielearn.com/question/accessibility/) |
| `clientFilesQuestion`, `serverFilesCourse`, and similar folders | [Client and server files](https://docs.prairielearn.com/clientServerFiles/) |
| Code questions graded in containers | [External grading](https://docs.prairielearn.com/externalGrading/) and [Python autograder](https://docs.prairielearn.com/python-grader/) |
| Manually graded questions and rubrics | [Manual grading](https://docs.prairielearn.com/manualGrading/) |
| Zones, alternatives, points lists, `numberChoose`, `bestQuestions` | [Assessment configuration](https://docs.prairielearn.com/assessment/configuration/) |
| `infoAssessment.json` fields | [infoAssessment schema](https://docs.prairielearn.com/schemas/infoAssessment/) |
| Changing scores after students have taken an assessment | [Regrading](https://docs.prairielearn.com/assessment/regrading/) |
| UUIDs for new questions and assessments | [UUIDs](https://docs.prairielearn.com/uuid/) |
| Workspace (IDE, Jupyter) questions | [Workspaces](https://docs.prairielearn.com/workspaces/) |

## Facts that often matter

- **Built-in question tests.** A question's **Settings** tab has test buttons.
  They run `test()` (or each element's built-in test) with correct, incorrect,
  and invalid submissions, and report any crash or mismatch. This works without
  writing `test()` whenever `correct_answers` is set and the question uses
  first-party elements.
- **Existing variants keep their parameters.** Students who already opened a
  question keep their generated variant after an edit; changes to `generate()`
  affect new variants only. Grading changes apply to new submissions.
- **The UUID is the question's identity.** Never change a question's `uuid`, and
  never reuse one. A copied question needs a new UUID.
- **Assessments refer to questions by QID,** the folder path under `questions/`.
  Renaming or moving a question folder breaks every assessment that lists it.
