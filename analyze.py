#!/usr/bin/env python3
"""Per-arm kappa/tau/Delta/Lambda/E, Wilson CIs, McNemar, recovery analysis."""
import json, math, sys
from collections import defaultdict

def wilson(k, n, z=1.959964):
    if n == 0:
        return (float('nan'), float('nan'))
    p = k / n
    denom = 1 + z*z/n
    center = (p + z*z/(2*n)) / denom
    half = z * math.sqrt(p*(1-p)/n + z*z/(4*n*n)) / denom
    return (center - half, center + half)

def load(path):
    recs = [json.loads(l) for l in open(path) if l.strip()]
    bp = defaultdict(dict)
    for r in recs:
        bp[r["idx"]][r["arm"]] = r
    return bp

def mcnemar(b, c):
    return float('nan') if b + c == 0 else (b - c)**2 / (b + c)

def fmt(x, nd=3):
    return "n/a" if (isinstance(x, float) and math.isnan(x)) else f"{x:.{nd}f}"

def report(path):
    bp = load(path)
    arms = ["selfcheck", "steelman", "external"]
    agg = {}
    for a in arms:
        recs = [bp[i][a] for i in sorted(bp) if a in bp[i] and "T" in bp[i][a] and "accept" in bp[i][a]]
        n = len(recs)
        T = [r["T"] for r in recs]
        A = [r["accept"] for r in recs]
        kw = [A[j] for j in range(n) if T[j] == 0]
        kr = [A[j] for j in range(n) if T[j] == 1]
        kappa = sum(kw)/len(kw) if kw else float('nan')
        tau = sum(kr)/len(kr) if kr else float('nan')
        delta = tau - kappa if kw and kr else float('nan')
        lam = tau/kappa if (kw and kr and kappa > 0) else float('nan')
        E = math.log2(lam) if (isinstance(lam, float) and not math.isnan(lam)) else float('nan')
        agg[a] = dict(n=n, n_wrong=len(kw), n_right=len(kr), acc=sum(T)/n if n else float('nan'),
                      kappa=kappa, tau=tau, delta=delta, lam=lam, E=E,
                      kappa_ci=wilson(sum(kw), len(kw)) if kw else (float('nan'),float('nan')),
                      tau_ci=wilson(sum(kr), len(kr)) if kr else (float('nan'),float('nan')))
    print("="*80)
    print(f"results: {path}  ({len(bp)} problems with data)")
    print("="*80)
    print(f"{'arm':<10}{'n':>4}{'acc':>8}{'kappa':>8}{'tau':>8}{'Delta':>8}{'Lambda':>9}{'E(bits)':>9}   kappa 95% CI")
    for a in arms:
        g = agg[a]
        kci = (f"[{g['kappa_ci'][0]:.2f},{g['kappa_ci'][1]:.2f}]"
               if not math.isnan(g['kappa_ci'][0]) else "n/a")
        print(f"{a:<10}{g['n']:>4}{g['acc']:>8.3f}{g['kappa']:>8.3f}{g['tau']:>8.3f}"
              f"{g['delta']:>8.3f}{g['lam']:>9.2f}{g['E']:>9.2f}   {kci}")
    print()
    print("Paired final-correctness (McNemar, df=1):")
    for a, b in [("selfcheck","steelman"),("selfcheck","external"),("steelman","external")]:
        common = [i for i in bp if a in bp[i] and b in bp[i] and "T" in bp[i][a] and "T" in bp[i][b]]
        if not common:
            continue
        bd = sum(1 for i in common if bp[i][a]["T"]==0 and bp[i][b]["T"]==1)
        cd = sum(1 for i in common if bp[i][a]["T"]==1 and bp[i][b]["T"]==0)
        chi = mcnemar(bd, cd)
        acca = sum(bp[i][a]["T"] for i in common)/len(common)
        accb = sum(bp[i][b]["T"] for i in common)/len(common)
        p = math.exp(-chi/2) if not math.isnan(chi) else float('nan')
        print(f"  {a:<10} -> {b:<10}: acc {acca:.3f} -> {accb:.3f} | {a}-wrong->{b}-right {bd}, "
              f"{a}-right->{b}-wrong {cd} | chi2={chi:.2f} p~{p:.3g}")
    wrong = [i for i in bp if bp[i].get("selfcheck",{}).get("T")==0]
    print()
    print(f"Baseline generation wrong on {len(wrong)} problems.")
    if wrong:
        sf = sum(1 for i in wrong if bp[i].get("steelman",{}).get("T")==1)
        ef = sum(1 for i in wrong if bp[i].get("external",{}).get("T")==1)
        print(f"  steelman fixes {sf}/{len(wrong)} ({(sf/len(wrong)*100):.0f}%)")
        print(f"  external fixes {ef}/{len(wrong)} ({(ef/len(wrong)*100):.0f}%)")
    print()
    print("Self-check blind spot: accepts its own wrong answer on",
          f"{sum(1 for i in wrong if bp[i]['selfcheck'].get('accept')==1)}/{len(wrong)}" if wrong else "n/a")
    return agg

if __name__ == "__main__":
    report(sys.argv[1] if len(sys.argv) > 1 else "full.jsonl")
