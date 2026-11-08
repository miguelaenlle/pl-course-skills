"""Recompute the numbers used in report.md from the saved aggregate CSVs."""
import csv, os, sys
R = os.path.dirname(os.path.abspath(__file__))
rows = list(csv.DictReader(open(os.path.join(R, '02_per_question.csv'))))
TOTAL = 41
def get(off, qid):
    return next(r for r in rows if r['offering'] == off and r['qid'].endswith(qid))
print('Slot 1.1 (5 pts): v2a vs mean(v1a, v3a)')
for off in ['Fall2022','Spring2023','Fall2023','Spring2024','Fall2024','Spring2025','Fall2025','Spring2026']:
    sfx = 'a' if off not in ('Fall2022','Spring2023') else ''
    a, b, c = (get(off, f'RankDeficient-v{i}{sfx}') for i in (1,2,3))
    others = (float(a['mean_final_pct']) + float(c['mean_final_pct'])) / 2
    gap = others - float(b['mean_final_pct'])
    print(f"  {off:10} v1 {a['mean_final_pct']:>5} (n={a['n_assigned']}) v2 {b['mean_final_pct']:>5} (n={b['n_assigned']}) v3 {c['mean_final_pct']:>5} (n={c['n_assigned']})"
          f"  full: {a['full_credit_pct']}/{b['full_credit_pct']}/{c['full_credit_pct']}  gap {gap:.1f} pct = {gap/100*5:.2f} pts = {gap/100*5/TOTAL*100:.1f}% of quiz")
print('Slot 2.8 (5 pts): Geese vs Squirrels')
for off in ['Spring2025','Fall2025','Spring2026']:
    g, s = get(off, 'Geese'), get(off, 'Squirrels')
    gap = float(g['mean_final_pct']) - float(s['mean_final_pct'])
    print(f"  {off:10} Geese {g['mean_final_pct']} (n={g['n_assigned']}, nosub {g['no_submission_pct']}, med {g['median_minutes']} min) "
          f"Squirrels {s['mean_final_pct']} (n={s['n_assigned']}, nosub {s['no_submission_pct']}, med {s['median_minutes']} min) gap {gap:.1f} = {gap/100*5:.2f} pts")
print('Slot 1.2 (3 pts): PseudoInv vs others')
for off in ['Fall2023','Spring2024','Fall2024','Spring2025','Fall2025','Spring2026']:
    p, e, m = get(off, 'SVD-APP-PseudoInv'), get(off, 'PseudoInverseExpression'), get(off, 'PropertiesMulti')
    others = (float(e['mean_final_pct']) + float(m['mean_final_pct'])) / 2
    gap = others - float(p['mean_final_pct'])
    print(f"  {off:10} PseudoInv {p['mean_final_pct']} (n={p['n_assigned']}) Expression {e['mean_final_pct']} (n={e['n_assigned']}) PropertiesMulti {m['mean_final_pct']} (n={m['n_assigned']}) gap {gap:.1f} = {gap/100*3:.2f} pts")
print('Coding slot 2.8 mean by offering')
for off in ['Fall2022','Spring2023','Fall2023','Spring2024','Fall2024','Spring2025','Fall2025','Spring2026']:
    print('  ', off, [(r['qid'].split('/')[-1], r['mean_final_pct'], r['n_assigned']) for r in rows if r['offering']==off and r['zone']=='2' and r['slot']=='8'])
shapes = {}
for r in csv.DictReader(open(os.path.join(R, '10_coding_M_messages.csv'))):
    k = r['qid'].split('-')[-1]
    cat = 'shape' if 'shape' in r['msg_pattern'] else ('undefined' if 'not defined' in r['msg_pattern'] else ('inaccurate' if 'inaccurate' in r['msg_pattern'] else 'other'))
    shapes.setdefault(k, {}).setdefault(cat, 0); shapes[k][cat] += int(r['n'])
den = {'Geese': 0, 'Squirrels': 0}
for r in csv.DictReader(open(os.path.join(R, '06_coding_tests.csv'))):
    if r['test'] == 'Check matrix M':
        if r['aq_id'] in ('1574901765','1648711431','1986540840'): den['Geese'] += int(r['n'])
        if r['aq_id'] in ('1574901766','1648711433','1986540841'): den['Squirrels'] += int(r['n'])
for k in shapes:
    print('  M failures', k, {c: f"{n} ({100*n/den[k]:.1f}%)" for c, n in shapes[k].items()}, 'of', den[k])
