-- Assessment-level time and skipping pattern, Quiz 4 (aggregates only).
WITH ai AS (
  SELECT ci.id AS ci_id, ci.short_name AS offering, ai.*
  FROM course_instances ci
  JOIN assessments a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL AND a.tid = 'quiz04'
  JOIN assessment_instances ai ON ai.assessment_id = a.id AND ai.include_in_statistics
  WHERE ci.course_id = 1 AND ci.short_name IN ('Sp24','Fa24','Spring2025','Fall2025','Spring2026','Fall2026')
), per_ai AS (
  SELECT ai.ci_id, ai.offering, ai.id, ai.score_perc, ai.duration,
    EXTRACT(EPOCH FROM (ai.closed_at - ai.date))/60 AS open_to_close_min,
    BOOL_OR(q.qid = 'constrainedMotionPistonVelo' AND NOT COALESCE(iq.some_submission,false)) AS skipped_piston,
    BOOL_OR(ag.number = 6 AND NOT COALESCE(iq.some_submission,false)) AS skipped_slot6,
    SUM(EXTRACT(EPOCH FROM iq.duration))/60 AS sum_q_min
  FROM ai
  JOIN instance_questions iq ON iq.assessment_instance_id = ai.id
  JOIN assessment_questions aq ON aq.id = iq.assessment_question_id
  JOIN alternative_groups ag ON ag.id = aq.alternative_group_id
  JOIN questions q ON q.id = aq.question_id
  GROUP BY 1,2,3,4,5,6
)
SELECT offering, COUNT(*) AS n,
  ROUND(AVG(score_perc)::numeric,1) AS mean_score,
  ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY open_to_close_min))::numeric,1) AS med_open_to_close_min,
  ROUND((PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY open_to_close_min))::numeric,1) AS p90_open_to_close_min,
  ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sum_q_min))::numeric,1) AS med_sum_question_min,
  ROUND(100*AVG(skipped_piston::int)::numeric,1) AS skipped_piston_pct,
  ROUND(100*AVG(skipped_slot6::int)::numeric,1) AS skipped_slot6_pct,
  ROUND(100*AVG((skipped_piston AND skipped_slot6)::int)::numeric,1) AS skipped_both_pct
FROM per_ai GROUP BY ci_id, offering ORDER BY ci_id;
