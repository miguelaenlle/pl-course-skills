# Quiz 2 (Vector calculus and rotations): diagnosis

2026-11-05 · Fall 2025 `quiz02` (244 students), checked against Fa24, Spring
2025, Spring 2026 and Fall 2026 · PrairieLearn production database (read-only),
plus question source

Scope, exclusions and caveats are at the top of details.md.

## Bottom line

- **Not fully fair.** On a 100-point quiz, the draw alone moved a student's
  expected score from −9 to +8 points against the average draw. 14% of students
  lost 5 or more points.
- **The biggest cause, the O'Hare questions in slot 6, is already fixed.** They
  were removed starting in Spring 2026. The 92 students who drew one lost about
  4 points against the average draw, and about 7 against the easiest draw.
- **Fix `particleVelonTriCurveSpeed` now.** About half of its variants have the
  answer 0, and almost everyone gets those right. This still happened in Fall
  2026.
- **`pinSlotAcclnMag` and `thetaFunTAccln3` each cost about 2–3 points** against
  their alternatives. Both are still in the quiz.
- **Calibrate the graders on the written question.** Grader averages ranged from
  81% to 96% on equally strong students.

## Findings

### Slot 6: the O'Hare questions were far harder than the θ(t) questions

Fall 2025 mean final score: `OhareTrackComputeA` 23% (n=52) and
`OhareTrackComputeR` 24% (n=40), against 72–73% for `thetaFunTAccln1`/`2` (n=56,
45). They were also the lowest in Fa24 and Spring 2025 (15–39% against 54–73%).

**Why:** `questions/OhareTrackComputeA` and `OhareTrackComputeR` test one design
idea from Discussion 4: the track must have zero acceleration where it joins the
straight segments. They have no Python-inputs block and one all-or-nothing
answer. On first answers, 15% entered 0 (A version) and 22% entered the given A
(R version), which points to not knowing the approach rather than slips.
Students who drew them also gave up sooner (median 7 minutes against 10–13), and
23% of the A version never submitted.

**Confidence:** Observed (in three terms); cause Likely.

**Effect:** −4.0 points out of 100 against the average draw, and −7.4 against
`thetaFunTAccln1`/`2`, for 92 of 244 students.

**Edit:** No edit needed; the questions are already out of `quiz02`. Whether to
adjust Fall 2025 grades is your decision.

### Slot 8: half of the `particleVelonTriCurveSpeed` variants have answer 0

Fall 2025: 99% on variants whose answer is 0 (n=35), and 50% otherwise (n=39).
That 50% is in line with `particleVelOnExpnCurveSpeed` (45%) and
`particleVelComponentOnCurve` (58%). Every term showed the same split, 91–99%
against 37–55% (Fall 2026: 91% against 39%).

**Why:** `questions/particleVelonTriCurveSpeed/server.py` puts x at a multiple of
π/2 on the curve A·sin(Bx) or A·cos(Bx) with B = ±1 or ±2. At those points the
slope is 0 half the time, so v_y = 0.

**Confidence:** Observed.

**Effect:** The 14% of students who drew a zero variant scored about 4 points
above the slot average.

**Edit:** In `generate`, redraw when the slope at x is 0, or use x values such as
π/6, π/4 and π/3.

### Slot 7: `pinSlotAcclnMag` scores lowest

Fall 2025: `pinSlotAcclnMag` 40% (n=57), `polarAcclnTelescopicArm` 57% (n=53),
`polarPolyCurveAcc` 56% (n=65), `acclnSpiralCurve` 69% (n=69). The pin question
scored 7–20 points below the nearly identical telescopic-arm question in all five
terms. The spiral question was the highest in all five.

**Why:** The pin and telescopic-arm questions share a generator, but the pin
question asks only for the magnitude. Both components must be right, there's no
partial credit, and feedback doesn't show which component is wrong. The spiral
question has constant ω (θ̈ = 0), so it has fewer terms.

**Confidence:** Likely. The answer format explains part of the gap with the
telescopic arm, not all of it (42% against 55% ever fully correct).

**Effect:** −2.4 points against the slot average and −4.3 against the spiral
question, for 23% of students.

**Edit:** Ask for a_r and a_θ in `pinSlotAcclnMag` (the magnitude can stay as a
third input). Give `acclnSpiralCurve` a non-zero θ̈, or accept that it is the
easy item.

### Slot 6: `thetaFunTAccln3` needs an extra step

Fall 2025: 52% (n=51) against 72–73% for versions 1 and 2. The gap repeats in all
five terms (Fall 2026: 52% against 60–67%).

**Why:** In `questions/thetaFunTAccln3`, θ(t) is exponential, so θ̈ ≠ 0 and the
chain rule is needed. In versions 1 and 2, θ is linear in t. The a_r input, which
gets the extra θ̈ term, is the weakest (23% correct on first answers against
38–49%). Answers that just drop θ̈ account for only 6% of first answers, though,
so the exact mistake isn't confirmed.

**Confidence:** Likely (specific mistake not confirmed).

**Effect:** −3.0 points against versions 1 and 2, for 21% of students.

**Edit:** Give versions 1 and 2 a non-linear θ(t), for example θ = c·t², so all
three need θ̈.

### Slot 5: grading depended on the grader

Fall 2025 written question, average score by grader: G1 96%, G2 85%, G3 87%, G4
93%, G5 81% (44–50 papers each). The same students earned 57–62 of the 80
auto-graded points elsewhere on the quiz. "Correct final answer" was applied to
100% of G1's papers and only 59% of G5's.

**Why:** The graders used the same rubric but applied an objective item very
differently.

**Confidence:** Observed.

**Effect:** Up to 3.1 points out of 100 between G1's and G5's students.

**Edit:** Before grading, have graders score a shared set of about 10 papers
together, and define "correct final answer" (for example, within 1%).

## Checked, no change needed

- Assignment was random: each alternative's share was similar on all three exam
  days (Sept 30 – Oct 2), and counts were near an even split.
- There were no staff score changes on the auto-graded questions, apart from one
  on `pointKinChangeRV`.
- `rotPointLoc` vs `rotPointVel`: −1.8 points in Fall 2025 and under 1 point in
  other terms. It's an inverse problem, so the gap looks intended.
- `distFromVelWritten` vs `fcnPosSpeedWritten`: about 1 point; integrating is
  somewhat harder than differentiating.
- `particleVelOnExpnCurveSpeed` vs `particleVelComponentOnCurve`: 0.8–2.3 points
  lower every term. Unexplained; neither sign errors nor which component was
  asked accounts for it.
- Time was tight: 58% of students used 45–50 minutes of an inferred 50-minute
  exam.

## Questions for the instructor

- How did the Quiz 2 retake count last fall: did it replace the score, take the
  higher of the two, or something else? 51% of students who drew O'Hare took it,
  against 35% of the others. The answer decides how much of the slot 6 loss
  stayed in final grades.
