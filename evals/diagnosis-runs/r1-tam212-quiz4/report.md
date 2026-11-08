# Quiz 4 (Rigid Body Kinematics): diagnosis
2026-11-05 · Spring 2026 (primary, 581 students) plus Sp24, Fa24, Spring 2025, Fall 2025 and Fall 2026 offerings of `quiz04` · read-only production database (course 1) and the course working copy (late-August 2026 snapshot)

## Bottom line
Spring 2026 was mostly fair. No slot cost a student more than about 2 points out of 100 because of which questions they drew. Four fixes, most important first:
1. **Group 1, "choose 3 of 5" pool:** split it so every student gets one single-body question and two two-bar questions. Right now the draw decides whether the slot takes about 8 or about 15 minutes.
2. **Written slot:** the two questions only came out even in Spring 2026 because the four-bar question was graded 8–10 points lower than usual. In every other term the pin question scores 9–27 points lower. Give the four-bar rubric the same rules the pin rubric has, and calibrate graders on it.
3. **`rbmCircleChordConstraint`:** add a v_P arrow to the figure. Clockwise variants get 3 times as many sign-flipped answers.
4. **Piston question (last, 8 points):** the share of students who never submit it has grown every term, from 12% to 23%. Decide how long it should take, and consider adding an intermediate answer box. Separately, fix a one-character figure bug in two two-bar questions (no effect on scores).

## Findings

### 1. Group 1 pool: `twoPointVAlg` and `rbmAccelNum` are much lighter than the three two-bar questions
**Saw:** Spring 2026, per question (each worth 17 points):

| Question | n | Mean final | Full credit | Median minutes |
| --- | --- | --- | --- | --- |
| twoPointVAlg | 355 | 98.7% | 96.3% | 1.4 |
| rbmAccelNum | 348 | 98.7% | 96.3% | 1.8 |
| twoBarAPoint | 333 | 95.6% | 84.7% | 2.9 |
| twoBarOmegaFromV | 366 | 91.1% | 81.1% | 4.1 |
| twoBarFloatVMiddle | 341 | 86.5% | 74.8% | 5.0 |

The same order shows up in all six offerings since Sp24 ([results/03_per_question.txt](results/03_per_question.txt)). Results by draw, out of the 51 points in this pool ([results/11_slot3_combinations.txt](results/11_slot3_combinations.txt)):

| Single-body questions drawn | Spring 2026 n | Points earned | Median minutes | Other 5 offerings: points / minutes |
| --- | --- | --- | --- | --- |
| 0 | 65 | 46.6 | 14.8 | 47.4 / 12.6 |
| 1 | 329 | 47.9 | 10.8 | 48.4 / 10.6 |
| 2 | 187 | 48.6 | 7.8 | 49.5 / 7.7 |

**Why:** `questions/twoPointVAlg/server.py` needs one formula (v_Q = v_P + ω × r_PQ), and `questions/rbmAccelNum/server.py` needs one formula with ω and α each zero in 20% of variants. In contrast, `twoBarFloatVMiddle` and `twoBarOmegaFromV` need two bodies and a 2×2 solve, and `twoBarAPoint` needs a two-body chain in half its variants. The draw is random, so this is luck, not student choice.
**Confidence:** Observed. The gap is stable across six offerings.
**Effect:** In Spring 2026, students who drew no single-body question earned about 2.0 fewer points out of 100 and spent about 7 more minutes than students who drew both.
**Edit:** In `courseInstances/<next term>/assessments/quiz04/infoAssessment.json` (the current copy is `courseInstances/Fall2026/...`, which is the same as Spring 2026), replace the 5-alternative `"numberChoose": 3` block with two blocks: `{"numberChoose": 1, "alternatives": [twoPointVAlg, rbmAccelNum]}` and `{"numberChoose": 2, "alternatives": [twoBarFloatVMiddle, twoBarAPoint, twoBarOmegaFromV]}`. Keep the same points.

### 2. Written slot: even in Spring 2026, but only because one question was graded lower
**Saw:** Mean final score (n):

| Offering | rigidBodyPinAccel(Written) | fourBarAngVelSimple(Written) | Gap |
| --- | --- | --- | --- |
| Sp24 (auto-graded) | 73.1% (239) | 93.3% (222) | 20.2 |
| Fa24 (auto-graded) | 66.2% (96) | 93.5% (102) | 27.3 |
| Spring 2025 (auto-graded) | 66.8% (219) | 92.2% (249) | 25.4 |
| Fall 2025 (written) | 60.9% (123) | 82.5% (120) | 21.6 |
| **Spring 2026 (written)** | **72.5% (298)** | **72.3% (283)** | **0.2** |
| Fall 2026 (written) | 70.8% (146) | 80.2% (167) | 9.4 |

In Spring 2026 the four-bar question scored 8–10 points below its other written terms. It was lower in every parameter type compared with Fall 2025, and in most compared with Fall 2026 ([results/06_by_params.txt](results/06_by_params.txt)). Its "Correct final answer" rubric item was applied 68.5% of the time, compared with 84.2% (Fall 2025) and 90.1% (Fall 2026) ([results/05_written_rubrics.txt](results/05_written_rubrics.txt)). Among Spring 2026 graders with 19–41 papers each, the average four-bar score ranged from 63.1% to 88.1%. On the pin question, grader averages ranged from 69.7% to 79.6% ([results/10_written_by_grader.txt](results/10_written_by_grader.txt)). Fall 2025 also had a large spread on the pin question (57.4–88.2%).
**Why:** There are two separate causes.
- *Difficulty:* `questions/rigidBodyPinAccelWritten/server.py` needs the acceleration formula with the ω² term, a slot constraint, and a 3-unknown solve. In `questions/fourBarAngVelSimpleWritten/server.py`, 46% of Spring 2026 variants are rectangles (`rAD` and `rBC` both vertical), where ω₁ = ω₂ and ω₃ = 0 by inspection.
- *Grading:* the rubrics differ in more than point weights. The pin rubric's grader notes give a follow-through rule for "Correct final answer" and say deductions apply only when the final answer is credited. The four-bar rubric has neither rule, and neither rubric says how to grade a valid rectangle shortcut that skips the three formulas, which are worth 12 of 17 points.

**Confidence:** Difficulty gap: Likely (consistent in 5 of 6 terms, with a clear cause in the source). Grader spread: Observed. Its cause is Unexplained: the even split of papers suggests graders were assigned at random, but I couldn't confirm that.
**Effect:** Spring 2026 had no gap. In Fall 2025 the gap was about 3.7 points out of 100, and in Fall 2026 about 1.6. Grader differences on the four-bar question in Spring 2026 were worth up to about 4 points out of 100.
**Edit:** In the four-bar rubric on the assessment's manual-grading page, copy the pin rubric's notes for "Correct final answer" (follow-through) and for the two deductions. Add one line saying how to grade the rectangle shortcut. Optionally, to narrow the difficulty gap, make `fourBarAngVelSimpleWritten/server.py` redraw whenever `rAD[0] == rBC[0]`, so every variant needs the three-equation solve. Before grading, have all graders grade the same 5 papers together and compare.

### 3. `rbmCircleChordConstraint`: clockwise variants produce many more sign errors
**Saw:** Pooled over Spring 2025 to Fall 2026, on first submissions: clockwise variants were correct 33.2% of the time with 16.4% exact sign flips (n=226). Counter-clockwise variants were correct 44.1% of the time with 4.9% sign flips (n=245) ([results/16_circlechord_direction.txt](results/16_circlechord_direction.txt)). Spring 2026 full credit was 29.5% for clockwise (n=88) and 39.4% for counter-clockwise (n=94). Counter-clockwise was ahead on full credit in all four offerings ([results/06_by_params.txt](results/06_by_params.txt)).
**Why:** `questions/rbmCircleChordConstraint/question.html` gives P's motion only as a speed plus the word "clockwise" or "counter-clockwise", and its `pl-drawing` has no v_P arrow. The other two alternatives in the slot (`rodVelCircleConstraint`, `rbmTwoCornerConstraints`) both draw v_P.
**Confidence:** Observed (the sign flips) and Likely (the missing arrow as the cause).
**Effect:** About 1 point out of 100 for students who drew this question with a clockwise variant.
**Edit:** In `rbmCircleChordConstraint/server.py`, save the angle of `vP` (as the two-bar questions do with `angleOf`). In `question.html`, add a `<pl-vector>` at P labeled `\vec{v}_P`.

### 4. Piston question (Group 3): more and more students never submit it
**Saw:** Share with no submission: Sp24 11.5%, Fa24 13.1%, Spring 2025 14.5%, Fall 2025 15.6%, **Spring 2026 19.8%**, Fall 2026 22.7%. Spring 2026 mean final was 33.4%, and median time among students who submitted was 11.0 minutes, for 8 points (n=581) ([results/03_per_question.txt](results/03_per_question.txt), [results/07_time_and_skips.txt](results/07_time_and_skips.txt)). Among wrong answers, 9–15% are just the x-component of v_B, which means ignoring the rod. Sign flips are about 1% of submissions or less, and treating degrees as radians is about 1% ([results/08_common_mistakes.txt](results/08_common_mistakes.txt), [results/09_piston_mistakes.txt](results/09_piston_mistakes.txt)). The answer key matches an independent calculation for 100% of submissions. In the other five offerings, students who drew both slow two-bar questions in Group 1 skipped the piston question more often: 23.8% for those who drew no single-body question, against 10.9% for those who drew two. Spring 2026 shows no such pattern (21.5% vs 20.9%) ([results/13_time_pressure_link.txt](results/13_time_pressure_link.txt)).
**Why:** `questions/constrainedMotionPistonVelo/question.html` asks for one number that needs the rod angle, two rigid-body relations and the guide constraint. It is all-or-nothing and comes last in the quiz. The prompt's unsigned convention for ω ("angular velocity of −146 rad/s") is not causing errors.
**Confidence:** Observed (the rising non-submission). The cause (time pressure versus giving up) is Unexplained. The exam length in PrairieTest and the time students first open this question would settle it.
**Edit:** Add an intermediate input in `constrainedMotionPistonVelo/question.html` for the angular velocity of rod BC, with its own weight, before v_C. This gives partial credit on the step most students miss. Finding 1's edit should also reduce the time spread before students reach this question.

### 5. Figure bug in `twoBarAPoint` and `twoBarOmegaFromV` (housekeeping)
**Saw:** In about 78% of variants of the two questions the drawn point Q is out of place, by more than 1 m in 32% of them. Scores don't differ: twoBarAPoint is 93.3% when the figure is correct and 93.9% when Q is more than 1 m off. twoBarOmegaFromV is 91.7% and 92.6% ([results/15_figure_mismatch.txt](results/15_figure_mismatch.txt)).
**Why:** Both `server.py` files compute `Qy = 175 - k*(rQ[1] - C[0])`. They use the x-center `C[0]` where they should use `C[1]`.
**Confidence:** Observed (bug in the source). There is no effect on scores.
**Edit:** In both files, change `C[0]` to `C[1]` on the `Qy` line.

### Also checked: small or no change needed
- **Group 2, `twoAccChoosePoint` vs `twoVelChoosePoint`:** the acceleration version is answered correctly on the first try less often in all 6 offerings (Spring 2026: 60.5%, n=299, vs 71.6%, n=282). Final scores are 84.4% vs 89.2%, which is under 0.6 points out of 100. Both of the acceleration version's cases (zero ω, zero α) score about the same. The gap comes from the concept, not a bad variant, so no edit is needed.
- **Group 2, constraint pool:** the three alternatives are well matched on full credit in Spring 2026 (rbmCircleChordConstraint 34.6%, n=182; rbmTwoCornerConstraints 32.5%, n=203; rodVelCircleConstraint 35.2%, n=196). All three take 8–10 minutes for 12 points. `rodVelCircleConstraint` has the lowest mean in each of the last four terms (42.9% in Spring 2026) because it earns less partial credit. The effect is under 1 point out of 100. Within `rbmTwoCornerConstraints`, asking for v_R is answered correctly on the first try less often than v_S in all four recent terms (Spring 2026: 35.3%, n=101, vs 45.6%, n=102). That fits R being diagonal from the given point P, but final scores reverse in Fall 2026, so I'm treating it as minor.
- **What works:** `twoPointVAlg`, `rbmAccelNum` and `twoBarAPoint` are stable from term to term. No final score sits above the best submission score in any auto-graded question, so there are no overrides to explain away ([results/17_override_check.txt](results/17_override_check.txt)).

## Data notes
- **Scope:** `quiz04` in Sp24, Fa24, Spring 2025, Fall 2025, Spring 2026 and Fall 2026. The question set is the same in all of them, except that the written slot was auto-graded `rigidBodyPinAccel` / `fourBarAngVelSimple` before Fall 2025. Fall 2026 is complete and fully graded. Spring 2026 had 576 instances on Mar 31–Apr 2 and 5 makeups through Apr 10, with one instance per student ([results/01_offerings.txt](results/01_offerings.txt), [results/02_instance_profile.txt](results/02_instance_profile.txt)).
- **Excluded:** staff and test instances (`include_in_statistics`). Also excluded: the retake `quiz04r` (different questions, self-selected students), `quiz04p` (no Spring 2026 data), ZJUI and summer offerings (different students or a different assessment definition), and the zero-point Python workspace and tutorial questions.
- **Traps checked:** sample sizes are 80+ per alternative in Spring 2026, except per-parameter cells and per-grader counts (19–45). There are no best-N choices: Group 1's 3 of 5 is a random draw and `used_for_grade` is true throughout. No score overrides. Non-submissions are reported separately. Times are medians because durations include idle time.
- **Unreliable data for written questions:** in Spring 2026 and Fall 2026, `some_submission` is false and `duration` is empty for every written instance, even though submissions exist (91–96% have a graded photo). I counted submissions from the `submissions` table instead ([results/04_written_slot_grading.txt](results/04_written_slot_grading.txt)). Time for the written slot is known only for Fall 2025 (median 9.9 min for four-bar, 12.1 for pin).
- **Not covered:** the working copy has no git history, so question edits between terms couldn't be ruled out. The exam length is set in PrairieTest and isn't in the database. I didn't read individual photo submissions.
- **Supporting files:** queries are in [queries/](queries/), aggregate outputs in [results/](results/), and [run.sh](run.sh) runs them read-only. Graders are anonymized as G1…Gn. No file contains student identifiers or per-student rows.

## Questions for the instructor
- How long is the Quiz 4 exam session in PrairieTest, and how many minutes do you intend the piston question to take? This decides whether Finding 4 is time pressure or intended difficulty.
- Spring 2026 had no gap in the written slot, but the four-bar grades depended noticeably on who graded the paper (63–88% averages). Whether to revisit any Spring 2026 written grades is your call.
