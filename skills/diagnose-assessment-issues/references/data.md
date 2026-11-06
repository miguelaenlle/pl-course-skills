# Data for assessment diagnosis

## Getting results

Use the first option that's available, and say which one you used.

1. **An aggregate-statistics tool from the environment,** if the course agent
   provides one.
2. **Read-only database access.**
   - Confirm the session is read-only first:
     `SELECT current_setting('transaction_read_only')` should return `on`.
   - PrairieLearn staff connect from the `sysconf` repository with
     `pnpm -s alma rds us-prod --access readonly`. Pass psql options after `--`.
   - Write results straight to a file with psql's `-o`, for example
     `-- -X -q --csv -v ON_ERROR_STOP=1 -f /abs/query.sql -o /abs/result.csv`.
     This keeps connection log lines, which can include a staff email, out of
     saved results. Use one query per file with `-o`, and send stderr to
     `/dev/null` rather than into the results folder.
   - Run long queries with a generous timeout.
   - If sign-in is needed, start it and let the instructor complete the browser
     step. Never ask for credentials or write access.
3. **Files the instructor exports** from the assessment's **Statistics** and
   **Downloads** pages. Per-student files contain identifiers: aggregate them
   right away and save only the aggregates. If the files can't answer a question
   (per part, per version, per day), ask for the specific export that would.
4. **No results.** Review the question source only, and say so at the top of the
   report.

If access fails, explain the obstacle once and continue with what you have.

## Finding the course

Match the course instance by the `uuid` in `infoCourseInstance.json`, then take
its `course_id`. Don't match `infoCourse.json`'s UUID against `courses`; the two
don't line up.

```sql
SELECT course_id, short_name FROM course_instances WHERE uuid = '<uuid>';
```

The assessment's total points may be empty in the database (`assessments.max_points`).
In that case, add up each slot's maximum points.

## Tables

Definitions are in `database/tables/*.pg` in the PrairieLearn repository. Filter
soft-deleted rows (`deleted_at IS NULL`).

| Table | Use |
| --- | --- |
| `zones`, `alternative_groups`, `assessment_questions`, `questions` | Structure. PrairieLearn numbers questions as `alternative_groups.number`, plus `.assessment_questions.number_in_alternative_group` when there are alternatives (for example `6` or `6.2`). The starting query builds this label; use it in the report. These numbers line up across offerings when the structure is unchanged, while database IDs don't. |
| `assessment_instances` | One per student per assessment. Use `include_in_statistics` to drop staff and test instances. `date` gives the start time, which you need for checking assignment by day. |
| `instance_questions` | One per assigned question: `score_perc`, `first_submission_score`, `max_submission_score`, `number_attempts`, `duration`, `used_for_grade`. |
| `variants`, `submissions` | `submissions` links to `variants`, which link to `instance_questions`. `submissions` holds `score`, `partial_scores` (per input), `feedback` (external-grader results in `feedback->'results'->'tests'`, each with `name`, `points`, `max_points`, `message`), and `submitted_answer`. `variants` holds `params` and `true_answer`. |
| `rubric_items`, `rubric_grading_items`, `rubric_gradings` | Manual grading. The path is `submissions.manual_rubric_grading_id` → `rubric_gradings` → `rubric_grading_items` → `rubric_items` (description, `grader_note`). `instance_questions.last_grader` identifies the grader. |
| `question_score_logs` | Every score change. A row with `grading_job_id IS NULL` is a staff change. Bulk changes show up as many rows within a few minutes. |

## Known quirks

- **Staff score changes.** Check `question_score_logs` for every question, not
  only those at 100%. Partial bumps don't produce perfect scores. Report each
  effect both before and after the change, and say who received it, including
  students who never submitted.
- **Manually graded questions.** `some_submission`, `first_submission_score`,
  and `duration` can be empty even when graded submissions exist. Count
  submissions from `submissions`, and use rubric items in place of
  first-submission scores. Per-question time isn't available for these.
- **Exam length** often isn't in PrairieLearn, for example when PrairieTest runs
  the exam. Don't infer it from when instances closed. Use the 90th percentile of
  total duration as a rough guide, and say it's inferred.
- **Duration** includes idle time and revisits. Use medians, plus the share of
  students finishing near the limit.
- **JSON encodings.** NumPy arrays appear as
  `{"_type": "ndarray", "_value": [...]}`. Externally graded code is in
  `submitted_answer->'_files'`, base64-encoded. For checkbox and
  multiple-choice questions, the correct options are in `variants.true_answer`.
  Older ("v2") questions often grade all-or-nothing.
- **Counting mistakes.** Compare each answer with predicted wrong answers within
  the question's tolerance. Check first that the categories don't overlap with
  the correct answer or with each other. For code, decode and count features
  inside the query, for example
  `convert_from(decode(f->>'contents', 'base64'), 'UTF8') ~ 'np\.outer'`, so the
  code never leaves the database. Never save or print the code itself.
- **Grader messages** can echo student output. Mask numbers and group messages by
  pattern; never save raw messages. Structural details such as array shapes are
  fine to keep. Messages in old feedback that the current grader can't produce
  show that the grader changed.
- **Which submission.** Use the best submission when explaining the recorded
  score. Use the first submission when studying initial mistakes. Exams can store
  saved but ungraded submissions (`score IS NULL`); skip them.
- **Course files contain identifiers too.** Access rules in
  `infoAssessment.json` can list student emails. Don't copy them into outputs.
- **Zero-point questions** and workspace placeholders don't need analysis.

## Starting query: per-question statistics across offerings

```sql
WITH iq AS (
  SELECT
    iq.*,
    EXISTS (
      SELECT 1 FROM variants AS v JOIN submissions AS s ON s.variant_id = v.id
      WHERE v.instance_question_id = iq.id
    ) AS submitted
  FROM instance_questions AS iq
)
SELECT
  ci.short_name AS offering,
  z.number AS zone,
  z.title AS zone_title,
  CASE
    WHEN (SELECT COUNT(*) FROM assessment_questions AS x
          WHERE x.alternative_group_id = ag.id AND x.deleted_at IS NULL) = 1
      THEN ag.number::text
    ELSE ag.number || '.' || aq.number_in_alternative_group
  END AS question_number,
  q.qid,
  aq.max_points,
  COUNT(*) AS n_assigned,
  ROUND(AVG(iq.score_perc)::numeric, 1) AS mean_final_pct,
  ROUND((100 * AVG((iq.score_perc >= 100)::int))::numeric, 1) AS full_credit_pct,
  ROUND((100 * AVG((NOT iq.submitted)::int))::numeric, 1) AS no_submission_pct,
  ROUND((100 * AVG(iq.first_submission_score) FILTER (WHERE iq.submitted))::numeric, 1) AS mean_first_pct,
  ROUND((100 * AVG(iq.max_submission_score) FILTER (WHERE iq.submitted))::numeric, 1) AS mean_best_pct,
  ROUND((AVG(iq.number_attempts) FILTER (WHERE iq.submitted))::numeric, 2) AS mean_attempts,
  ROUND(((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM iq.duration))
    FILTER (WHERE iq.submitted)) / 60)::numeric, 1) AS median_minutes
FROM course_instances AS ci
JOIN assessments AS a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL
JOIN assessment_questions AS aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
JOIN alternative_groups AS ag ON ag.id = aq.alternative_group_id
JOIN zones AS z ON z.id = ag.zone_id
JOIN questions AS q ON q.id = aq.question_id
JOIN iq ON iq.assessment_question_id = aq.id
JOIN assessment_instances AS ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
WHERE ci.course_id = :course_id
  AND ci.deleted_at IS NULL
  AND a.tid = :'assessment_tid'
  AND aq.max_points > 0
  AND COALESCE(iq.used_for_grade, true)
GROUP BY ci.id, ci.short_name, z.number, z.title, ag.id, ag.number, aq.id,
  aq.number_in_alternative_group, q.qid, aq.max_points
ORDER BY ci.id, z.number, ag.number, aq.number_in_alternative_group;
```

Run it with `-v course_id=<id> -v assessment_tid=<tid>`. For manually graded
questions, first-submission scores, attempts, and time may still be empty; see
the quirks above.

## Starting query: external-grader test results

Use this to see which tests students fail on their best submission. Replace the
`IN (...)` list with the `assessment_questions.id` values you're comparing.

```sql
WITH best AS (
  SELECT DISTINCT ON (iq.id) iq.assessment_question_id AS aq_id, s.feedback
  FROM instance_questions AS iq
  JOIN assessment_instances AS ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  JOIN variants AS v ON v.instance_question_id = iq.id
  JOIN submissions AS s ON s.variant_id = v.id AND s.feedback ? 'results'
  WHERE iq.assessment_question_id IN (/* assessment_questions.id values */)
  ORDER BY iq.id, s.score DESC NULLS LAST, s.date DESC
)
SELECT
  aq_id,
  t->>'name' AS test,
  COUNT(*) AS n,
  ROUND((100 * AVG(((t->>'points')::numeric >= (t->>'max_points')::numeric)::int))::numeric, 1) AS passed_pct
FROM best, LATERAL jsonb_array_elements(feedback->'results'->'tests') AS t
GROUP BY aq_id, test
ORDER BY aq_id, test;
```

For other question types, apply the same pattern to `partial_scores` (per input)
or rubric items (per item and per grader). Always group before output; never
print per-student rows.
