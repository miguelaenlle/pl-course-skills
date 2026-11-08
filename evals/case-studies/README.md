# Case studies

End-to-end evidence for the three case studies in the deck
(`presentations/course-agent-skills`). Each folder holds:

- `fix.patch`: the authoring agent's change to the course repository (applied to a local clone, never pushed).
- `authoring-run/`: screenshots, test submissions, and grader output from verifying the fix on local PrairieLearn.
- `diagnosis-run*/`: the diagnosis agent's queries and aggregate results.
- `*.sql` / `*.csv`: the queries behind the numbers on the slides (read-only production data, aggregates only).

| Folder | Course instance · assessment · question | Gap | Cause |
| --- | --- | --- | --- |
| `cs357-quiz5-spring2026` | CS 357 · Spring 2026 · Quiz 5 · Q10 | 52.3% vs 35.9% | Only 10.2 tests a saddle point; its prompt says there is none |
| `cs357-quiz3-fall2026` | CS 357 · Fall 2026 · Quiz 3 · Q10 | 50.4% vs 24.7% | 10.2 needs a harder A/b construction with no worked example |
| `tam212-quiz2-fall2025` | TAM 212 · Fall 2025 · Quiz 2 · Q8 | 73.2% vs 45–58% | 47% of 8.2 variants have answer 0 |

`evals/diagnosis-runs/` holds the other diagnosis test runs logged in `evals/diagnose-test-log.md`.
