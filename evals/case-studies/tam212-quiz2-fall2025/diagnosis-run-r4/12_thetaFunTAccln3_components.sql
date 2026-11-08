-- thetaFunTAccln3: first-submission categories per component, against several predicted mistakes
WITH first_sub AS (
  SELECT DISTINCT ON (iq.id) ci.id AS ci_id, ci.short_name AS offering, v.params p, v.true_answer ta, s.submitted_answer sa
  FROM instance_questions iq
  JOIN assessment_instances ai ON ai.id = iq.assessment_instance_id AND ai.include_in_statistics
  JOIN assessments a ON a.id = ai.assessment_id
  JOIN course_instances ci ON ci.id = a.course_instance_id
  JOIN assessment_questions aq ON aq.id = iq.assessment_question_id
  JOIN questions q ON q.id = aq.question_id
  JOIN variants v ON v.instance_question_id = iq.id
  JOIN submissions s ON s.variant_id = v.id AND s.score IS NOT NULL
  WHERE a.id IN (2434746, 2497144, 2574213, 2634479, 2716830) AND q.qid = 'thetaFunTAccln3'
  ORDER BY iq.id, s.date
), k AS (
  SELECT ci_id, offering, (p->>'constantO')::float8 O, (p->>'constantI')::float8 I, (p->>'coeff1')::float8 n,
    (p->>'coeff2')::float8 c2, (p->>'power')::float8 pw, (p->>'time')::float8 t,
    (ta->>'ansValue1')::float8 tar, (ta->>'ansValue2')::float8 tat,
    CASE WHEN sa->>'ansValue1' ~ '^\s*[-+]?(\d+\.?\d*|\.\d+)([eE][-+]?\d+)?\s*$' THEN (sa->>'ansValue1')::float8 END sar,
    CASE WHEN sa->>'ansValue2' ~ '^\s*[-+]?(\d+\.?\d*|\.\d+)([eE][-+]?\d+)?\s*$' THEN (sa->>'ansValue2')::float8 END sat
  FROM first_sub
), d AS (SELECT *, c2*exp(pw*t) th, c2*pw*exp(pw*t) thd, c2*pw*pw*exp(pw*t) thdd FROM k),
e AS (SELECT *, O*(I+sin(n*th)) r, O*n*cos(n*th) r1, -O*n*n*sin(n*th) r2 FROM d),
f AS (
  SELECT *,
    -- predicted mistakes
    r2*thd*thd - r*thd*thd AS ar_no_r1thdd,        -- r-double-dot taken as r''*thetadot^2 only
    2*r1*thd*thd AS at_no_rthdd,                    -- dropped r*thetaddot in a_theta
    (r1*thdd + r2*thd*thd) - r*thd AS ar_thd_not_squared,
    -- theta treated as degrees inside sin
    O*(I+sin(radians(n*th))) AS r_deg
  FROM e
), g AS (
  SELECT *,
    CASE WHEN sar IS NULL THEN 'unparsed'
      WHEN abs(sar-tar) <= 1e-5+0.01*abs(tar) THEN 'correct'
      WHEN abs(sar-ar_no_r1thdd) <= 1e-5+0.01*abs(ar_no_r1thdd) THEN 'dropped r''*thetaddot in r-ddot'
      WHEN abs(sar+tar) <= 1e-5+0.01*abs(tar) THEN 'sign flipped'
      WHEN abs(sar-tar) <= 0.1*abs(tar) THEN 'within 10% (rounding?)'
      WHEN abs(sar-ar_thd_not_squared) <= 1e-5+0.01*abs(ar_thd_not_squared) THEN 'thetadot not squared'
      ELSE 'other' END AS cat_ar,
    CASE WHEN sat IS NULL THEN 'unparsed'
      WHEN abs(sat-tat) <= 1e-5+0.01*abs(tat) THEN 'correct'
      WHEN abs(sat-at_no_rthdd) <= 1e-5+0.01*abs(at_no_rthdd) THEN 'dropped r*thetaddot'
      WHEN abs(sat+tat) <= 1e-5+0.01*abs(tat) THEN 'sign flipped'
      WHEN abs(sat-tat) <= 0.1*abs(tat) THEN 'within 10% (rounding?)'
      ELSE 'other' END AS cat_at
  FROM f
)
SELECT offering, 'e_r' AS component, cat_ar AS category, COUNT(*) n, ROUND(100.0*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY offering),1) pct
FROM g GROUP BY ci_id, offering, cat_ar
UNION ALL
SELECT offering, 'e_theta', cat_at, COUNT(*), ROUND(100.0*COUNT(*)/SUM(COUNT(*)) OVER (PARTITION BY offering),1)
FROM g GROUP BY ci_id, offering, cat_at
ORDER BY 1, 2, 4 DESC;
