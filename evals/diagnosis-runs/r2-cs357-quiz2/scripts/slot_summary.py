"""Combine the three Quiz 2 question-statistics exports into per-slot comparisons.

Usage: python3 -I slot_summary.py <exports_dir> <out_dir>
Inputs are already aggregated per question (no student rows).
"""
import csv, sys, os, glob
from collections import defaultdict

exp_dir, out_dir = sys.argv[1], sys.argv[2]
rows = []
for f in sorted(glob.glob(os.path.join(exp_dir, "*.csv"))):
    rows += list(csv.DictReader(open(f)))
order = {"Spring2025": 0, "Fall2025": 1, "Spring2026": 2}
rows.sort(key=lambda r: (int(r["slot"]), r["qid"], order[r["offering"]]))

total_points = {}
for off in order:
    seen = {}
    for r in rows:
        if r["offering"] == off:
            seen[r["slot"]] = float(r["max_points"])
    total_points[off] = sum(seen.values())

out = []
by_slot_off = defaultdict(list)
for r in rows:
    by_slot_off[(int(r["slot"]), r["offering"])].append(r)
for (slot, off), rs in sorted(by_slot_off.items(), key=lambda k: (k[0][0], order[k[0][1]])):
    n_tot = sum(int(r["n_assigned"]) for r in rs)
    for r in rs:
        out.append({
            "slot": slot, "offering": off, "qid": r["qid"], "max_points": r["max_points"],
            "n": r["n_assigned"], "share_of_slot_pct": round(100 * int(r["n_assigned"]) / n_tot, 1),
            "expected_share_pct": round(100 / len(rs), 1),
            "mean_final": r["mean_final_pct"], "full_credit": r["full_credit_pct"],
            "partial_gap": round(float(r["mean_final_pct"]) - float(r["full_credit_pct"]), 1),
            "first": r["mean_first_pct"], "attempts": r["mean_attempts"],
            "median_min": r["median_minutes"], "no_sub": r["no_submission_pct"],
        })
    if len(rs) > 1:
        hi = max(rs, key=lambda r: float(r["mean_final_pct"]))
        lo = min(rs, key=lambda r: float(r["mean_final_pct"]))
        gap = float(hi["mean_final_pct"]) - float(lo["mean_final_pct"])
        pts = gap / 100 * float(lo["max_points"])
        print(f"slot {slot:>2} {off:<10} spread {gap:5.1f} pts-of-q -> {pts:4.2f}/{total_points[off]:.0f} quiz pts "
              f"| high {hi['qid'].split('/')[1]} {hi['mean_final_pct']} (n={hi['n_assigned']}) "
              f"| low {lo['qid'].split('/')[1]} {lo['mean_final_pct']} (n={lo['n_assigned']})")
print("assessment totals:", total_points)

with open(os.path.join(out_dir, "slot_summary.csv"), "w", newline="") as fh:
    w = csv.DictWriter(fh, fieldnames=list(out[0].keys()))
    w.writeheader(); w.writerows(out)
