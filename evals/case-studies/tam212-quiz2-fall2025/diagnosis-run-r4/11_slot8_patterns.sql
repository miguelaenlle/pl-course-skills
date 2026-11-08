-- Slot 8: share of variants whose correct v_y is zero, score by that, and first-answer patterns
WITH first_sub AS (
  SELECT DISTINCT ON (iq.id) ci.id AS ci_id, ci.short_name AS offering, q.qid, v.params p, v.true_answer ta, s.submitted_answer sa, iq.score_perc
  FROM instance_questions iq
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  JOIN assessments a ON a.id = ai.assessment_id
  JOIN course_instances ci ON ci.id = a.course_instance_id
  JOIN assessment_questions aq ON aq.id = iq.assessment_question_id
  JOIN questions q ON q.id = aq.question_id
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions s ON s.variant_id = v.id AND s.score IS NOT NULL
  WHERE a.id IN (2434746, 2497144, 2574213, 2634479, 2716830)
    AND q.qid IN ('particleVelonTriCurveSpeed','particleVelOnExpnCurveSpeed','particleVelComponentOnCurve')
  ORDER BY iq.id, s.date
), k AS (
  SELECT *, COALESCE((ta->>'yVel')::float8, (ta->>'v')::float8) AS c, (p->>'speed')::float8 AS speed,
    CASE WHEN COALESCE(sa->>'yVel', sa->>'v') ~ '^\s*[-+]?(\d+\.?\d*|\.\d+)([eE][-+]?\d+)?\s*$' THEN COALESCE(sa->>'yVel', sa->>'v')::float8 END AS s
  FROM first_sub
), cat AS (
  SELECT *, abs(c) < 1e-6 AS zero_answer,
    CASE WHEN s IS NULL THEN 'unparsed'
      WHEN abs(s-c) <= 1e-5+0.01*abs(c) THEN 'correct'
      WHEN abs(s+c) <= 1e-5+0.01*abs(c) THEN 'sign flipped'
      WHEN speed IS NOT NULL AND abs(abs(s) - sqrt(greatest(speed*speed - c*c,0))) <= 1e-5+0.01*sqrt(greatest(speed*speed - c*c,0)) THEN 'gave |v_x| instead of v_y'
      WHEN speed IS NOT NULL AND abs(abs(s) - speed) <= 0.01*speed THEN 'gave +/- speed'
      ELSE 'other' END AS first_answer
  FROM k
)
SELECT offering, qid,
  COUNT(*) AS n,
  ROUND(100*AVG(zero_answer::int),1) AS pct_variants_correct_answer_zero,
  ROUND(AVG(score_perc) FILTER (WHERE zero_answer)::numeric,1) AS mean_final_if_zero,
  ROUND(AVG(score_perc) FILTER (WHERE NOT zero_answer)::numeric,1) AS mean_final_if_nonzero,
  ROUND(100*AVG((first_answer='correct')::int),1) AS pct_first_correct,
  ROUND(100*AVG((first_answer='sign flipped')::int),1) AS pct_first_sign_flipped,
  ROUND(100*AVG((first_answer='gave |v_x| instead of v_y')::int),1) AS pct_first_vx,
  ROUND(100*AVG((first_answer='gave +/- speed')::int),1) AS pct_first_speed,
  ROUND(100*AVG((first_answer='other')::int),1) AS pct_first_other,
  ROUND(100*AVG((first_answer='correct')::int) FILTER (WHERE NOT zero_answer),1) AS pct_first_correct_nonzero_only
FROM cat GROUP BY ci_id, offering, qid ORDER BY ci_id, qid;
