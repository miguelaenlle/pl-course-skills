-- tnPolarEqual: on the first submission, how often each half (e_t boxes, e_n boxes) is exactly right.
WITH firsts AS (
  SELECT DISTINCT ON (iq.id) ci.short_name AS offering, s.submitted_answer AS sa, v.true_answer AS ta, s.score
  FROM course_instances ci
  JOIN assessments a ON a.course_instance_id=ci.id AND a.deleted_at IS NULL AND a.tid='quiz03'
  JOIN assessment_questions aq ON aq.assessment_id=a.id AND aq.deleted_at IS NULL
  JOIN questions q ON q.id=aq.question_id AND q.qid='tnPolarEqual'
  JOIN instance_questions iq ON iq.assessment_question_id=aq.id
  JOIN assessment_instances ai ON ai.id=iq.assessment_instance_id AND ai.include_in_statistics
  JOIN variants v ON v.instance_question_id=iq.id
  JOIN submissions s ON s.variant_id=v.id
  WHERE ci.course_id=:course_id AND ci.short_name IN ('Spring2025','Fall2025','Spring2026','Fall2026')
  ORDER BY iq.id, s.date, s.id
),
p AS (
  SELECT offering, score,
    (SELECT bool_and(COALESCE((sa->>k)::boolean,false) = COALESCE((ta->>k)::boolean,false)) FROM unnest(ARRAY['trp','trm','thp','thm']) k) AS t_ok,
    (SELECT bool_and(COALESCE((sa->>k)::boolean,false) = COALESCE((ta->>k)::boolean,false)) FROM unnest(ARRAY['nrp','nrm','nhp','nhm']) k) AS n_ok,
    (SELECT COUNT(*) FROM unnest(ARRAY['trp','trm','thp','thm','nrp','nrm','nhp','nhm']) k WHERE COALESCE((ta->>k)::boolean,false)) AS n_true_boxes,
    (ta->>'trp')::boolean OR (ta->>'trm')::boolean AS et_along_er
  FROM firsts
)
SELECT COALESCE(offering,'ALL') offering, COUNT(*) n_first,
  ROUND(100*AVG((score>=1)::int)::numeric,1) first_correct_pct,
  ROUND(100*AVG(t_ok::int)::numeric,1) et_half_right_pct,
  ROUND(100*AVG(n_ok::int)::numeric,1) en_half_right_pct,
  ROUND(AVG(n_true_boxes)::numeric,2) mean_correct_boxes,
  ROUND(100*AVG((t_ok AND NOT n_ok)::int)::numeric,1) only_en_wrong_pct,
  ROUND(100*AVG((n_ok AND NOT t_ok)::int)::numeric,1) only_et_wrong_pct
FROM p GROUP BY ROLLUP(offering) ORDER BY offering NULLS LAST;
