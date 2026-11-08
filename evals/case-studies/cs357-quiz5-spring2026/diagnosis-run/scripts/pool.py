"""Pool per-question stats (n-weighted) across Spring2025, Fall2025, Spring2026 from results/03_per_question.csv."""
import csv, sys, collections
src, out = sys.argv[1], sys.argv[2]
rows = [r for r in csv.DictReader(open(src)) if r['offering'] in ('Spring2025', 'Fall2025', 'Spring2026')]
agg = collections.OrderedDict()
for r in rows:
    k = (int(r['slot']), r['qid'].split('/')[-1], r['max_points'])
    a = agg.setdefault(k, {'n': 0, 'fin': 0, 'full': 0, 'nosub': 0, 'first': 0, 'att': 0, 'min': [], 'offs': []})
    n = int(r['n_assigned']); a['n'] += n
    for f, c in (('fin', 'mean_final_pct'), ('full', 'full_credit_pct'), ('nosub', 'no_sub_pct'), ('first', 'first_pct'), ('att', 'attempts')):
        a[f] += n * float(r[c] or 0)
    a['min'].append(r['med_min']); a['offs'].append(f"{r['offering']}:{r['mean_final_pct']}(n={n})")
w = csv.writer(open(out, 'w'))
w.writerow(['slot', 'qid', 'max_points', 'n_pooled', 'mean_final_pct', 'full_credit_pct', 'no_sub_pct', 'first_pct_among_submitters', 'attempts', 'median_min_by_offering', 'final_by_offering'])
for (slot, qid, mp), a in agg.items():
    n = a['n']
    w.writerow([slot, qid, mp, n] + [round(a[f] / n, 1) for f in ('fin', 'full', 'nosub', 'first')] + [round(a['att'] / n, 2), '/'.join(a['min']), '; '.join(a['offs'])])
