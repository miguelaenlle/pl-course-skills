-- twoBarAPoint / twoBarOmegaFromV: the drawn Q is shifted vertically by (256-Ox)-(Oy-175) px because server.py uses C[0] for Qy.
-- Group outcomes by size of that shift (computed from stored drawing params).
WITH base AS (
  SELECT ci.id AS ci_id, q.qid, iq.score_perc, iq.first_submission_score, iq.some_submission,
    abs((256 - (v.params->>'Ox')::float8) - ((v.params->>'Oy')::float8 - 175)) AS shift_px,
    CASE WHEN q.qid = 'twoBarAPoint' THEN 28 ELSE 22 END AS px_per_m
  FROM course_instances ci
  JOIN assessments a ON a.course_instance_id = ci.id AND a.deleted_at IS NULL AND a.tid = 'quiz04'
  JOIN assessment_questions aq ON aq.assessment_id = a.id AND aq.deleted_at IS NULL
  JOIN questions q ON q.id = aq.question_id AND q.qid IN ('twoBarAPoint','twoBarOmegaFromV')
  JOIN instance_questions iq ON iq.assessment_question_id = aq.id
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  JOIN LATERAL (SELECT v.params FROM variants v WHERE v.instance_question_id = iq.id ORDER BY v.number DESC NULLS LAST, v.id DESC LIMIT 1) v ON true
  WHERE ci.course_id = 1 AND ci.short_name IN ('Spring2025','Fall2025','Spring2026','Fall2026')
)
SELECT qid,
  CASE WHEN shift_px < 1 THEN 'a: figure correct' WHEN shift_px / px_per_m <= 1 THEN 'b: Q off by <=1 m' ELSE 'c: Q off by >1 m' END AS figure,
  COUNT(*) AS n, ROUND(AVG(score_perc)::numeric,1) AS final_pct,
  ROUND(100*AVG(first_submission_score) FILTER (WHERE some_submission)::numeric,1) AS first_pct
FROM base GROUP BY 1, 2 ORDER BY 1, 2;
