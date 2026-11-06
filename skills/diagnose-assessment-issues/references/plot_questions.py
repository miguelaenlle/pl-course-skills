"""Chart per-question results for one offering of an assessment.

Reads the CSV produced by the "per-question statistics" starting query in
data.md and draws two side-by-side panels: mean final score and median minutes,
one bar per question, with alternatives for the same question grouped together.

Usage:
    python3 plot_questions.py RESULTS.csv OFFERING OUTPUT.png [--title TITLE]
"""

import argparse
import csv

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("csv_path")
    parser.add_argument("offering")
    parser.add_argument("output")
    parser.add_argument("--title", default=None)
    args = parser.parse_args()

    with open(args.csv_path, newline="") as f:
        rows = [r for r in csv.DictReader(f) if r["offering"] == args.offering]
    if not rows:
        raise SystemExit(f"No rows for offering {args.offering!r}")

    def group_of(row: dict) -> str:
        return row["question_number"].split(".")[0]

    labels, scores, minutes, colors, ns = [], [], [], [], []
    palette = ["#3b6ea8", "#9db7d5"]
    group_index = -1
    last_group = None
    for row in rows:
        group = group_of(row)
        if group != last_group:
            group_index += 1
            last_group = group
        labels.append(f'{row["question_number"]}  {row["qid"].split("/")[-1]}')
        scores.append(float(row["mean_final_pct"] or 0))
        minutes.append(float(row["median_minutes"] or 0))
        ns.append(row["n_assigned"])
        colors.append(palette[group_index % 2])

    height = max(3.0, 0.32 * len(rows) + 1.2)
    fig, (ax_score, ax_time) = plt.subplots(
        1, 2, figsize=(11, height), sharey=True, gridspec_kw={"width_ratios": [3, 2]}
    )
    y = list(range(len(rows)))[::-1]

    ax_score.barh(y, scores, color=colors)
    for yi, score, n in zip(y, scores, ns):
        ax_score.text(score + 1, yi, f"{score:.0f}%  (n={n})", va="center", fontsize=8)
    ax_score.set_xlim(0, 115)
    ax_score.set_xlabel("Mean final score (%)")
    ax_score.set_yticks(y)
    ax_score.set_yticklabels(labels, fontsize=8)

    ax_time.barh(y, minutes, color=colors)
    for yi, m in zip(y, minutes):
        ax_time.text(m + 0.2, yi, f"{m:.1f}", va="center", fontsize=8)
    ax_time.set_xlim(0, max(minutes + [1]) * 1.25)
    ax_time.set_xlabel("Median minutes (students who submitted)")

    for ax in (ax_score, ax_time):
        ax.spines[["top", "right"]].set_visible(False)

    fig.suptitle(args.title or f"Results by question, {args.offering}", fontsize=11)
    fig.text(
        0.01,
        0.005,
        "Bars with the same shade and question number (for example 6.1, 6.2) are "
        "alternatives: each student got one of them.",
        fontsize=7,
        color="#555555",
    )
    fig.tight_layout(rect=(0, 0.03, 1, 0.97))
    fig.savefig(args.output, dpi=150)


if __name__ == "__main__":
    main()
