import sys, itertools, time, signal, numpy as np
Q = sys.argv[1]
ns = {}
exec(open(Q+'/tests/setup_code.py').read(), ns)
exec(open(Q+'/tests/ans.py').read(), ns)
gen = [v for k,v in ns.items() if k.startswith('generate_')][0]
find = [v for k,v in ns.items() if k.startswith('find_')][0]
def handler(*a): raise TimeoutError
signal.signal(signal.SIGALRM, handler)
from collections import Counter
c = Counter(); bad = 0; slow = 0
for signs in itertools.product([1,-1], repeat=3):
    for _ in range(150):
        f,g,h,x0 = gen(signs)
        signal.alarm(5); t=time.time()
        try:
            xs, v, typ = find(f,g,h,x0.copy())
        except TimeoutError:
            bad += 1; continue
        finally:
            signal.alarm(0)
        if time.time()-t > 1: slow += 1
        c[(signs, typ)] += 1
        if np.linalg.norm(g(xs)) > 1e-3 * max(1, abs(v)): bad += 1
print(Q.split('/')[-1], 'timeouts/unconverged:', bad, 'slow:', slow)
for k in sorted(c): print(' ', k, c[k])
