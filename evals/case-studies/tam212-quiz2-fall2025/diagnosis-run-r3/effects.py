# Recompute per-finding effects (points out of 100) from saved aggregate CSVs.
import csv, sys, os
R = os.path.dirname(os.path.abspath(__file__))
rows = list(csv.DictReader(open(os.path.join(R, 'r06_strength.csv'))))
m = {r['qid']: (int(r['n']), float(r['mean_pts'])) for r in rows}
slot = {}
for r in rows: slot.setdefault(r['slot'], []).append(r['qid'])
def pooled(qs):
    n = sum(m[q][0] for q in qs); return sum(m[q][0]*m[q][1] for q in qs)/n, n
for s, qs in sorted(slot.items()):
    mean, n = pooled(qs); print(f"slot {s}: mean {mean:.2f} pts (n={n})")
oh, ohn = pooled(['OhareTrackComputeA','OhareTrackComputeR']); th12, _ = pooled(['thetaFunTAccln1','thetaFunTAccln2'])
s6, _ = pooled(slot['6'])
print(f"Ohare pooled {oh:.2f} (n={ohn}, {100*ohn/244:.0f}% of 244); vs slot mean {oh-s6:+.2f}; vs theta1/2 {oh-th12:+.2f}")
print(f"theta3 vs theta1/2: {m['thetaFunTAccln3'][1]-th12:+.2f}")
s7, _ = pooled(slot['7'])
print(f"pinSlot vs slot7 mean {m['pinSlotAcclnMag'][1]-s7:+.2f}; vs spiral {m['pinSlotAcclnMag'][1]-m['acclnSpiralCurve'][1]:+.2f}; vs telescopic {m['pinSlotAcclnMag'][1]-m['polarAcclnTelescopicArm'][1]:+.2f}")
s8, _ = pooled(slot['8'])
tri = {r['answer_is_zero']: r for r in csv.DictReader(open(os.path.join(R, 'r10b_slot8_final_F25.csv'))) if 'Tri' in r['qid']}
z = float(tri['t']['mean_final_pct'])/10; nz = float(tri['f']['mean_final_pct'])/10
print(f"slot8 mean {s8:.2f}; Tri zero-answer {z:.2f} (n={tri['t']['n']}), Tri nonzero {nz:.2f} (n={tri['f']['n']}); zero vs slot mean {z-s8:+.2f}")
g = list(csv.DictReader(open(os.path.join(R, 'r17_grader_strength.csv'))))
hi = max(g, key=lambda r: float(r['slot5_mean_pct'])); lo = min(g, key=lambda r: float(r['slot5_mean_pct']))
print(f"grader spread {hi['grader']} {hi['slot5_mean_pct']}% vs {lo['grader']} {lo['slot5_mean_pct']}% -> {0.2*(float(hi['slot5_mean_pct'])-float(lo['slot5_mean_pct'])):.1f} pts of 20")
