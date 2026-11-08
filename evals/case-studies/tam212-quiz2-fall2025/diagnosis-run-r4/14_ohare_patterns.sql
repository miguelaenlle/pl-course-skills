-- O'Hare questions: first-answer ratio to the correct value, grouped (aggregates only)
WITH first_sub AS (
  SELECT DISTINCT ON (iq.id) ci.id AS ci_id, ci.short_name AS offering, q.qid, v.true_answer ta, s.submitted_answer sa
  FROM instance_questions iq
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  JOIN assessments a ON a.id = ai.assessment_id
  JOIN course_instances ci ON ci.id = a.course_instance_id
  JOIN assessment_questions aq ON aq.id = iq.assessment_question_id
  JOIN questions q ON q.id = aq.question_id
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions s ON s.variant_id = v.id AND s.score IS NOT NULL
  WHERE a.id IN (2434746, 2497144, 2574213) AND q.qid IN ('OhareTrackComputeA','OhareTrackComputeR')
  ORDER BY iq.id, s.date
), k AS (
  SELECT ci_id, offering, qid, COALESCE((ta->>'AVal')::float8, (ta->>'R')::float8) c,
    CASE WHEN COALESCE(sa->>'AVal', sa->>'R') ~ '^\s*[-+]?(\d+\.?\d*|\.\d+)([eE][-+]?\d+)?\s*$' THEN COALESCE(sa->>'AVal', sa->>'R')::float8 END s
  FROM first_sub
), cat AS (
  SELECT *, CASE
    WHEN s IS NULL THEN 'unparsed'
    WHEN abs(s-c) <= 1e-5+0.01*abs(c) THEN 'correct'
    WHEN s = 0 THEN 'zero'
    WHEN abs(s/c - 0.5) < 0.01 THEN 'half the answer'
    WHEN abs(s/c - 2) < 0.02 THEN 'double the answer'
    WHEN qid='OhareTrackComputeA' AND abs(s/c - pi()^2/2) < 0.05 THEN 'A = R (no pi^2/2)'
    WHEN qid='OhareTrackComputeR' AND abs(s/c - 2/pi()^2) < 0.01 THEN 'R = A (no pi^2/2)'
    WHEN abs(s/c + 1) < 0.01 THEN 'sign flipped'
    ELSE 'other' END AS first_answer
  FROM k
)
SELECT offering, qid, first_answer, COUNT(*) n, ROUND(100.0*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY offering, qid),1) pct
FROM cat GROUP BY ci_id, offering, qid, first_answer ORDER BY ci_id, qid, n DESC;
