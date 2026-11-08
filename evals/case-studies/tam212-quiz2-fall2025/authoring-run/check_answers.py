"""Independently recompute v_y for many seeds and compare with server.py's answer."""

import collections
import importlib.util
import math
import random
import sys

qdir = sys.argv[1]
spec = importlib.util.spec_from_file_location("server", f"{qdir}/server.py")
server = importlib.util.module_from_spec(spec)
spec.loader.exec_module(server)

combos = collections.Counter()
slopes = collections.Counter()
bad = 0
n = 1000
for seed in range(n):
    random.seed(seed)
    data = {"params": {}, "correct_answers": {}}
    server.generate(data)
    p = data["params"]
    A, B, xp = p["coefficient1"], p["coefficient2"], p["xPos"]
    if p["func"] == "Sin":
        s = A * B * math.cos(B * xp)
    else:
        s = -A * B * math.sin(B * xp)
    vx = p["speed"] / math.sqrt(1 + s * s)
    if p["direction"] == "left":
        vx = -vx
    vy = s * vx
    got = data["correct_answers"]["yVel"]
    if abs(got - vy) > 1e-9 * max(1, abs(vy)):
        bad += 1
        print("mismatch", seed, p, got, vy)
    combos[(p["func"], abs(B))] += 1
    slopes[round(abs(s), 6)] += 1
    if abs(vy) < 0.5:
        print("small answer", seed, p, vy)

print(f"{n} seeds, {bad} mismatches")
print("func/|B|:", dict(combos))
print("|slope|:", dict(slopes))
