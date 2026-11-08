"""Checks of question generators/graders, re-implemented from the course source.
No student data is used. Usage: python3 -I source_checks.py"""
import math, random
import numpy as np
random.seed(0); np.random.seed(0)

print("== Error-TaylorErrorBound: actual error vs Lagrange-bound answer")
for err, key in [(0.01, 3), (0.001, 5), (0.0001, 7)]:
    def taylor_sin(x, n):
        return sum((-1)**k * x**(2*k+1) / math.factorial(2*k+1) for k in range(n//2 + 1) if 2*k+1 <= n)
    actual = next(n for n in range(1, 20) if max(abs(math.sin(x) - taylor_sin(x, n)) for x in np.linspace(0, 1, 2001)) < err)
    bound = next(n for n in range(1, 20) if 1 / math.factorial(n + 1) < err)
    print(f"  error<{err}: key={key} actual-error answer={actual} remainder-bound answer={bound}")

print("== Energy vs RobotArm: credit available without a correct Taylor polynomial")
agree = 0; N = 20000
for _ in range(N):
    a = random.choice([2,3,4,5,6]); b = random.choice([2,3,4,5,6]); c = random.choice(range(1,10)); d = random.choice([3,4])
    x = random.uniform(-1, 1); thr = random.choice([random.uniform(-30,-20), random.uniform(20,30)])
    f = math.sin(a*x) + b*math.cos(x) + c
    t = c + b + a*x - b*x*x/2 - a**3 * x**3/6 + (b*x**4/24 if d == 4 else 0)
    agree += ((f > thr) == (t > thr))
print(f"  Energy: boolean computed from the exact f agrees with the key in {100*agree/N:.1f}% of draws")
print("  Energy grading: per case approximation, true_value, boolean (6 items); RobotArm: approximation, true_value, absolute_error (3 items)")

print("== UFLtoOFL vs UFLtoSubnormal: size of the list students must produce (all-or-nothing, 8 of 10 test points)")
lo, ls, nb = [], [], []
for _ in range(N):
    L = -random.choice([4,5,6]); n = random.choice([3,4,5]); start = np.random.uniform(0, .5); end = np.random.uniform(1, 1.5)
    vals = [(1 + m/2**n) * 2.0**e for e in range(L, -L+1) for m in range(2**n) if start <= (1 + m/2**n) * 2.0**e <= end]
    lo.append(len(vals)); nb.append(len({math.floor(math.log2(v)) for v in vals})); ls.append(2*(2**n - 1))
print(f"  UFLtoOFL fp_lst: median {int(np.median(lo))} values over median {int(np.median(nb))} exponents (range {min(nb)}-{max(nb)})")
print(f"  UFLtoSubnormal subnormal_lst: median {int(np.median(ls))} values over 1 exponent")

print("== Weather vs Graphics (Fall 2026): does the common formula gap = eps * 2^e give the key?")
for name in ["Weather", "Graphics"]:
    ok = 0
    for _ in range(N):
        n = random.randint(2,6); L = random.randint(-9,-3); U = random.randint(3,9)
        if name == "Weather":
            e = random.randint(L, U); key = 2.0**(e - n)
        else:
            e = random.randint(L+1, U); key = 2.0**(e - n - 1)
        ok += math.isclose(2.0**-n * 2.0**e, key, rel_tol=1e-5)
    print(f"  {name}: formula matches key in {100*ok/N:.0f}% of variants (gap item = 35 of 100 test points)")

print("== Binary64 vs binary32 rounding (Fall 2026): spacing via floor(log2(x))")
def cases(P, top):
    out = []; g = 8; l = (2**P + 20)*g; out += [l, l+1, l+g-1]
    out += [top]; g = 4; e = (2**P+10)*g; o = (2**P+11)*g; out += [e, e+1, e+2, o+2, o+3]
    for ex, off in ([(56,19),(58,28),(60,37)] if P == 52 else [(27,19),(29,28),(30,37)]):
        g = 2**(ex-P); l = (2**P+off)*g; out += [l+1, l+g//2, l+g-1]
    return out
for name, P, top in [("binary64", 52, 2**55-1), ("binary32", 23, 2**26-1)]:
    bad = [x for x in cases(P, top) if 2**(int(np.floor(np.log2(x))) - P) != 2**(x.bit_length() - 1 - P)]
    print(f"  {name}: log2 spacing wrong on {len(bad)} of {len(cases(P, top))} graded inputs; key(2^k-1 boundary case) rounds exactly in float64: {float(top) == top}")
