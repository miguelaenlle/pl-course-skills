"""Simulate Eigen-TwoLargestEig grading on the matrices its setup_code generates.
Reproduces the generator and reference from questions/12-Eigenvalues/Eigen-TwoLargestEig/tests,
then grades a few plausible student implementations with the same checks as test.py
(check_scalar defaults rtol=1e-5, atol=1e-8; vector allclose rtol=1e-3 for v_max, default rtol=1e-5/atol=1e-8 for v_2nd)."""
import numpy as np, numpy.linalg as la

def generate_M(eigs):
    n = len(eigs); Q, _ = la.qr(np.random.rand(n, n)); return Q.T @ np.diag(eigs) @ Q

def make():
    eigs = [np.random.uniform(10, 15), np.random.uniform(5, 6), np.random.uniform(1, 4),
            np.random.uniform(-5, -1), np.random.uniform(-10, -6)]
    return generate_M(eigs), eigs

def power(M, x0, tol=1e-12, maxiter=500, evfun='rayleigh', crit='diff'):
    x = x0.copy(); its = 0
    for k in range(maxiter):
        xp = x; y = M @ xp; x = y / la.norm(y, 2); its += 1
        if crit == 'diff' and la.norm(x - xp, 2) < tol: break
    if evfun == 'rayleigh': ev = x @ M @ x
    elif evfun == 'norm': ev = la.norm(M @ x)
    return ev, x, its

def ref(M, x0):
    l1, v1, _ = power(M, x0); M1 = M - l1*np.outer(v1, v1); l2, v2, its = power(M1, x0); return l1, v1, l2, v2, its

def student(M, x0, kind):
    l1, v1, _ = power(M, x0, evfun='norm' if kind == 'norm_eig' else 'rayleigh')
    M1 = M - l1*np.outer(v1, v1)
    start = v1 if kind == 'start_from_v0' else x0
    l2, v2, _ = power(M1, start, evfun='norm' if kind == 'norm_eig' else 'rayleigh')
    return l1, v1, l2, v2

def close(a, b, rtol=1e-5, atol=1e-8): return np.allclose(a, b, rtol=rtol, atol=atol)
def vec_ok(r, s, rtol=1e-5): r = r/la.norm(r); s = s/la.norm(s); return close(r, s, rtol) or close(-r, s, rtol)

np.random.seed(0)
x0 = np.ones(5)/np.sqrt(5)
N = 2000; dominant_neg = 0; hit_maxiter = 0
res = {k: [0, 0, 0, 0] for k in ['same_as_ref', 'norm_eig', 'start_from_v0']}
for _ in range(N):
    M, eigs = make()
    l1, v1, l2, v2, its = ref(M, x0)
    dominant_neg += l2 < 0; hit_maxiter += its >= 500
    for k in res:
        s = student(M, x0, k)
        res[k][0] += close(l1, s[0]); res[k][1] += vec_ok(v1, s[1], 1e-3)
        res[k][2] += close(l2, s[2]); res[k][3] += vec_ok(v2, s[3])
print(f"trials={N}")
print(f"second eigenpair found by reference is the negative one (from [-10,-6]): {100*dominant_neg/N:.1f}%")
print(f"reference second power iteration ran all 500 iterations (never met stopping rule): {100*hit_maxiter/N:.1f}%")
for k, v in res.items():
    print(k, "pass% lambda_max, v_max, lambda_2nd, v_2nd:", [round(100*c/N, 1) for c in v])

# Plausible deflation mistakes when v0 is a 1-D numpy array
def student_deflation(M, x0, kind):
    l1, v1, _ = power(M, x0)
    if kind == 'outer': M1 = M - l1*np.outer(v1, v1)
    elif kind == 'v@v.T': M1 = M - l1*(v1 @ v1.T)          # 1-D: inner product -> scalar 1, subtracted from every entry
    elif kind == 'v*v.T': M1 = M - l1*(v1 * v1.T)          # 1-D: elementwise square, broadcast across rows
    elif kind == 'v.T@v': M1 = M - l1*(v1.T @ v1)
    l2, v2, _ = power(M1, x0)
    return l1, v1, l2, v2

np.random.seed(1)
res = {k: [0, 0, 0, 0] for k in ['outer', 'v@v.T', 'v*v.T', 'v.T@v']}
for _ in range(N):
    M, eigs = make(); l1, v1, l2, v2, its = ref(M, x0)
    for k in res:
        s = student_deflation(M, x0, k)
        res[k][0] += close(l1, s[0]); res[k][1] += vec_ok(v1, s[1], 1e-3)
        res[k][2] += close(l2, s[2]); res[k][3] += vec_ok(v2, s[3])
print("deflation variants:")
for k, v in res.items():
    print(k, "pass% lambda_max, v_max, lambda_2nd, v_2nd:", [round(100*c/N, 1) for c in v])
