-- rotPoint questions: stored answer vs current code, and first-submission answer patterns
WITH first_sub AS (
  SELECT DISTINCT ON (iq.id) ci.short_name AS offering, ci.id AS ci_id, q.qid, v.params, v.true_answer, s.submitted_answer AS sa, s.score
  FROM instance_questions iq
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  JOIN assessments a ON a.id = ai.assessment_id
  JOIN course_instances ci ON ci.id = a.course_instance_id
  JOIN assessment_questions aq ON aq.id = iq.assessment_question_id
  JOIN questions q ON q.id = aq.question_id
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions s ON s.variant_id = v.id AND s.score IS NOT NULL
  WHERE a.id IN (2434746, 2497144, 2574213, 2634479, 2716830) AND q.qid = 'rotPointLoc'
  ORDER BY iq.id, s.date
), vals AS (
  SELECT offering, ci_id, score,
    (params->>'omega')::float8 AS w,
    (params->'v'->'_value'->>0)::float8 AS vx, (params->'v'->'_value'->>1)::float8 AS vy,
    (true_answer->>'rx')::float8 AS trx, (true_answer->>'ry')::float8 AS try_,
    CASE WHEN sa->>'rx' ~ '^\s*[-+]?(\d+\.?\d*|\.\d+)([eE][-+]?\d+)?\s*$' THEN (sa->>'rx')::float8 END AS srx,
    CASE WHEN sa->>'ry' ~ '^\s*[-+]?(\d+\.?\d*|\.\d+)([eE][-+]?\d+)?\s*$' THEN (sa->>'ry')::float8 END AS sry
  FROM first_sub
), cat AS (
  SELECT *,
    abs(trx - vy/w) < 1e-9 AND abs(try_ + vx/w) < 1e-9 AS key_matches_code,
    CASE
      WHEN srx IS NULL OR sry IS NULL THEN 'unparsed'
      WHEN abs(srx-trx) <= 1e-5+0.01*abs(trx) AND abs(sry-try_) <= 1e-5+0.01*abs(try_) THEN 'correct'
      WHEN abs(srx+trx) <= 1e-5+0.01*abs(trx) AND abs(sry+try_) <= 1e-5+0.01*abs(try_) THEN 'negated (-r)'
      WHEN abs(srx-try_) <= 1e-5+0.01*abs(try_) AND abs(sry-trx) <= 1e-5+0.01*abs(trx) THEN 'components swapped'
      WHEN abs(srx - vy*w) <= 1e-5+0.01*abs(vy*w) AND abs(sry + vx*w) <= 1e-5+0.01*abs(vx*w) THEN 'multiplied by omega instead of dividing'
      WHEN abs(srx + vy*w) <= 1e-5+0.01*abs(vy*w) AND abs(sry - vx*w) <= 1e-5+0.01*abs(vx*w) THEN 'multiplied by omega, negated'
      ELSE 'other' END AS first_answer
  FROM vals
)
SELECT offering, first_answer, COUNT(*) AS n, SUM(key_matches_code::int) AS n_key_matches_current_code,
  ROUND(100.0*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY offering),1) AS pct_of_offering
FROM cat GROUP BY ci_id, offering, first_answer ORDER BY ci_id, n DESC;
