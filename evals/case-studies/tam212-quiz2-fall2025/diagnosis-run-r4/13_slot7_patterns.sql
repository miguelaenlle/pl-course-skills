-- Slot 7 (polarAcclnTelescopicArm, pinSlotAcclnMag): first submissions vs predicted mistakes
-- (degrees used as radians, sign of theta-double-dot ignored, theta-double-dot omitted)
WITH first_sub AS (
  SELECT DISTINCT ON (iq.id) ci.id AS ci_id, ci.short_name AS offering, q.qid, v.params p, v.true_answer ta, s.submitted_answer sa
  FROM instance_questions iq
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  JOIN assessments a ON a.id = ai.assessment_id
  JOIN course_instances ci ON ci.id = a.course_instance_id
  JOIN assessment_questions aq ON aq.id = iq.assessment_question_id
  JOIN questions q ON q.id = aq.question_id
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions s ON s.variant_id = v.id AND s.score IS NOT NULL
  WHERE a.id IN (2434746, 2497144, 2574213, 2634479, 2716830) AND q.qid IN ('polarAcclnTelescopicArm','pinSlotAcclnMag')
  ORDER BY iq.id, s.date
), k AS (
  SELECT ci_id, offering, qid, p->>'fun' fun, p->>'rate' rate, (p->>'constant')::float8 c, (p->>'coeff')::float8 kk,
    (p->>'coefficient')::float8 n, (p->>'theta')::float8 th_deg, (p->>'thetadot')::float8 w, (p->>'thetaddot')::float8 amag,
    (ta->>'ansValue1')::float8 t1, (ta->>'ansValue2')::float8 t2, (ta->>'ansValue')::float8 tm,
    CASE WHEN sa->>'ansValue1' ~ '^\s*[-+]?(\d+\.?\d*|\.\d+)([eE][-+]?\d+)?\s*$' THEN (sa->>'ansValue1')::float8 END s1,
    CASE WHEN sa->>'ansValue2' ~ '^\s*[-+]?(\d+\.?\d*|\.\d+)([eE][-+]?\d+)?\s*$' THEN (sa->>'ansValue2')::float8 END s2,
    CASE WHEN sa->>'ansValue' ~ '^\s*[-+]?(\d+\.?\d*|\.\d+)([eE][-+]?\d+)?\s*$' THEN (sa->>'ansValue')::float8 END sm
  FROM first_sub
), sc AS (  -- scenarios: (theta in rad or deg-as-rad) x (alpha correct / sign ignored / zero)
  SELECT k.*, sc.name, sc.th, sc.al FROM k,
  LATERAL (VALUES
    ('code',               radians(th_deg), CASE WHEN rate='decreasing' THEN -amag ELSE amag END),
    ('degrees as radians', th_deg,          CASE WHEN rate='decreasing' THEN -amag ELSE amag END),
    ('alpha sign ignored', radians(th_deg), amag),
    ('alpha omitted',      radians(th_deg), 0.0)
  ) AS sc(name, th, al)
), ev AS (
  SELECT *,
    c + kk*CASE WHEN fun='sin' THEN sin(n*th) ELSE cos(n*th) END AS r,
    kk*n*CASE WHEN fun='sin' THEN cos(n*th) ELSE -sin(n*th) END AS r1,
    -kk*n*n*CASE WHEN fun='sin' THEN sin(n*th) ELSE cos(n*th) END AS r2
  FROM sc
), acc AS (
  SELECT *, (r1*al + r2*w*w) - r*w*w AS ar, r*al + 2*r1*w*w AS at FROM ev
), hit AS (
  SELECT ci_id, offering, qid, name, rate, t1, t2, tm, ar, at,
    CASE WHEN qid='pinSlotAcclnMag'
      THEN sm IS NOT NULL AND abs(sm - sqrt(ar*ar+at*at)) <= 1e-5+0.01*sqrt(ar*ar+at*at)
      ELSE s1 IS NOT NULL AND s2 IS NOT NULL AND abs(s1-ar) <= 1e-5+0.01*abs(ar) AND abs(s2-at) <= 1e-5+0.01*abs(at) END AS match
  FROM acc
), keycheck AS (
  SELECT ci_id, offering, qid,
    SUM((CASE WHEN qid='pinSlotAcclnMag' THEN abs(tm - sqrt(ar*ar+at*at)) < 1e-6*(1+tm) ELSE abs(t1-ar) < 1e-6*(1+abs(t1)) AND abs(t2-at) < 1e-6*(1+abs(t2)) END)::int) AS n_key_matches
  FROM hit WHERE name = 'code' GROUP BY 1,2,3
)
SELECT h.offering, h.qid, kc.n_key_matches, COUNT(*) FILTER (WHERE name='code') AS n,
  ROUND(100*AVG(match::int) FILTER (WHERE name='code'),1) AS pct_first_correct,
  ROUND(100*AVG(match::int) FILTER (WHERE name='degrees as radians'),1) AS pct_degrees_as_radians,
  COUNT(*) FILTER (WHERE name='code' AND rate='decreasing') AS n_decreasing,
  ROUND(100*AVG(match::int) FILTER (WHERE name='code' AND rate='decreasing'),1) AS pct_first_correct_when_decreasing,
  ROUND(100*AVG(match::int) FILTER (WHERE name='code' AND rate='increasing'),1) AS pct_first_correct_when_increasing,
  ROUND(100*AVG(match::int) FILTER (WHERE name='alpha sign ignored' AND rate='decreasing'),1) AS pct_alpha_sign_ignored_when_decreasing,
  ROUND(100*AVG(match::int) FILTER (WHERE name='alpha omitted'),1) AS pct_alpha_omitted
FROM hit h JOIN keycheck kc USING (ci_id, offering, qid)
GROUP BY h.ci_id, h.offering, h.qid, kc.n_key_matches ORDER BY h.ci_id, h.qid;
