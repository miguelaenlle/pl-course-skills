"""Compare a calendar-shifted copy of the source instance to the instance the instructor actually made."""
import sys, os, collections
sys.path.insert(0, os.path.dirname(__file__))
from normalize import load
pred, actual = load(sys.argv[1]), load(sys.argv[2])
stats = collections.Counter(); misses = []
for t in sorted(set(pred) & set(actual)):
    p, a = pred[t], actual[t]
    for field in ('release', 'due'):
        if p[field] and a[field]:
            ok = p[field] == a[field]
            sameday = p[field].date() == a[field].date()
            stats[(field, 'exact' if ok else ('same day' if sameday else 'different'))] += 1
            if not sameday: misses.append((t, field, p[field], a[field], (a[field]-p[field]).days))
    pl = [d for d, _ in p['late']]; al = [d for d, _ in a['late']]
    if pl and al:
        stats[('late', 'exact' if pl[0] == al[0] else 'different')] += 1
for k in sorted(stats): print(k, stats[k])
tot = collections.Counter(); 
for (f, r), n in stats.items(): tot[f] += n
for f in tot: print(f, f"{100*stats[(f,'exact')]/tot[f]:.0f}% exact of {tot[f]}")
print('\nmisses (assessment, field, predicted, actual, actual-predicted days):')
for m in misses: print(f"  {m[0]:24} {m[1]:8} {m[2]:%a %Y-%m-%d %H:%M}  {m[3]:%a %Y-%m-%d %H:%M}  {m[4]:+d}")
