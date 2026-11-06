# Data for assessment diagnosis

## Getting results

Use the first option that's available, and say which one you used.

1. **An aggregate-statistics tool from the environment,** if the course agent
   provides one.
2. **Read-only database access.**
   - Confirm the session is read-only first:
     `SELECT current_setting('transaction_read_only')` should return `on`.
   - PrairieLearn staff connect from the `sysconf` repository with
     `pnpm -s alma rds us-prod --access readonly`. Pass psql options after `--`,
     for example `-- -X -q -A -F ',' -v ON_ERROR_STOP=1 -f /abs/path/query.sql`.
   - The command prints connection log lines before the query output, and they
     can include a staff email. Strip them before saving results.
   - Run long queries with a generous timeout.
   - If sign-in is needed, start it and let the instructor complete the browser
     step. Never ask for credentials or write access.
3. **Files the instructor exports** from the assessment's **Statistics** and
   **Downloads** pages. Per-student files contain identifiers: aggregate them
   immediately and save only the aggregates.
4. **No results.** Review the question source only, and say so at the top of the
   report.

If access fails, explain the obstacle once and continue with what you have.

## Tables

Definitions are in `database/tables/*.pg` in the PrairieLearn repository. Filter
soft-deleted rows (`deleted_at IS NULL`).

| Table | Use |
| --- | --- |
| `zones`, `alternative_groups`, `assessment_questions`, `questions` | Structure. A slot is identified by `zones.number` plus `alternative_groups.number`; these line up across offerings, while database IDs don't. |
| `assessment_instances` | One per student per assessment. Use `include_in_statistics` to drop staff and test instances. `date` gives the start time, which you need for checking assignment by day. |
| `instance_questions` | One per assigned question: `score_perc`, `first_submission_score`, `max_submission_score`, `number_attempts`, `duration`, `some_submission`, `used_for_grade`, `assigned_grader`, `last_grader`. |
| `submissions` (via `variants`) | `score`, `partial_scores` (per input), `feedback` (external-grader results in `feedback->'results'->'tests'`, each with `name`, `points`, `max_points`, `message`), `submitted_answer`, `true_answer`. |
| `variants` | `params` and `true_answer` hold the generated instance. |
| `rubrics`, `rubric_items`, `rubric_gradings`, `rubric_grading_items` | Manual grading: guidelines, item descriptions and grader notes, and which items were applied. |
| `question_score_logs` | Score changes. A row with `grading_job_id IS NULL` was a manual or staff change, which is how you date and count overrides. |

## Known quirks

- **Overrides and blanket credit.** Final scores at 100% while
  `max_submission_score` is lower mean staff set the score. Check whether every
  alternative in the slot got the same treatment.
- **Manually graded questions.** `some_submission`, `first_submission_score`,
  and `duration` can be empty or false even when graded submissions exist. Count
  submissions from `submissions`, and use rubric items in place of
  first-submission scores.
- **Exam length.** The exam length often isn't in PrairieLearn, for example when
  PrairieTest runs the exam. Don't infer it from when instances closed. Use the
  distribution of total durations as a rough guide, and say it's inferred.
- **Duration** includes idle time and revisits. Use medians.
- **JSON encodings.** NumPy arrays in `params`, `true_answer`, and
  `submitted_answer` appear as `{"_type": "ndarray", "_value": [...]}`. For
  checkbox and multiple-choice questions, the correct options are in
  `variants.true_answer`.
- **Grader messages** can echo student output. Mask numbers and group messages by
  pattern; never save raw messages.
- **Which submission.** Use the best submission when explaining the recorded
  score. Use the first submission when studying initial mistakes.
- **Questions worth zero points** and workspace placeholders don't need analysis.

## Starting query: per-question statistics across offerings

```sql
SELECT
  ci.short_name AS offering,
  z.number AS zone,
  ag.number AS slot,
  q.qid,
  aq.max_points,
  COUNT(*) AS n_assigned,
  ROUND(AVG(iq.score_perc)::numeric, 1) AS mean_final_pct,
  ROUND((100 * AVG((iq.score_perc >= 100)::int))::numeric, 1) AS full_credit_pct,
  ROUND((100 * AVG((NOT COALESCE(iq.some_submission, false))::int))::numeric, 1) AS no_submission_pct,
  ROUND((100 * AVG(iq.first_submission_score) FILTER (WHERE iq.some_submission))::numeric, 1) AS mean_first_pct,
  ROUND((100 * AVG(iq.max_submission_score) FILTER (WHERE iq.some_submission))::numeric, 1) AS mean_best_pct,
  ROUND((AVG(iq.number_attempts) FILTER (WHERE iq.some_submission))::numeric, 2) AS mean_attempts,
  ROUND(((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM iq.duration))
    FILTER (WHERE iq.some_submission)) / 60)::numeric, 1) AS median_minutes
FROM course_instances AS ci
JOIN assessments AS a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL
JOIN assessment_questions AS aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
JOIN alternative_groups AS ag ON ag.id = aq.alternative_group_id
JOIN zones AS z ON z.id = ag.zone_id
JOIN questions AS q ON q.id = aq.question_id
JOIN instance_questions AS iq ON iq.assessment_question_id = aq.id
JOIN assessment_instances AS ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
WHERE ci.course_id = :course_id
  AND ci.deleted_at IS NULL
  AND a.tid = :'assessment_tid'
  AND COALESCE(iq.used_for_grade, true)
GROUP BY ci.id, ci.short_name, z.number, ag.number, q.qid, aq.max_points
ORDER BY ci.id, zone, slot, q.qid;
```

Run it with `-v course_id=<id> -v assessment_tid=<tid>`. Find the course ID from
`courses` by matching the `uuid` in `infoCourse.json`.

## Starting query: external-grader test results

Use this to see which tests students fail on their best submission. Replace the
`IN (...)` list with the assessment question IDs you're comparing.

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
or `rubric_grading_items` (per rubric item). Always group before output; never
print per-student rows.
