import itertools
# Treasure: ordered 4-key draws with neither pair matching
def m(a,b): return a==2*b or b==2*a
for K in range(4,9):
    tot=0; nm=0; nm0=0
    for p in itertools.permutations(range(1,K+1),4):
        tot+=1
        if not m(p[0],p[1]) and not m(p[2],p[3]): nm+=1
    for p in itertools.permutations(range(0,K),4):
        if not m(p[0],p[1]) and not m(p[2],p[3]): nm0+=1
    print("K",K,"total",tot,"no_match",nm,"P(no)",round(nm/tot,4),"0-indexed P(no)",round(nm0/tot,4))
# Arcade: DP count of 10-subsets of 1..30 by sum
from functools import lru_cache
dp={(0,0):1}
for v in range(1,31):
    nd=dict(dp)
    for (k,s),c in dp.items():
        if k<10: nd[(k+1,s+v)]=nd.get((k+1,s+v),0)+c
    dp=nd
tot=sum(c for (k,s),c in dp.items() if k==10)
print("arcade total",tot)
for lo,hi in [(145,165),(144,166),(143,167),(142,168),(141,169),(140,170),(139,171),(138,172),(137,173),(136,174)]:
    w=sum(c for (k,s),c in dp.items() if k==10 and lo<=s<=hi)
    w0=sum(c for (k,s),c in dp.items() if k==10 and lo<=s-10<=hi)
    print(lo,hi,w,round(w/tot,4),"0-indexed",round(w0/tot,4))
