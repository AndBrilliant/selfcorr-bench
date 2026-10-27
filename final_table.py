#!/usr/bin/env python3
"""Final consolidation for the IJCS resubmission: MBPP sweeps, five families.

kappa = P(A=1 | T=0)   false-acceptance rate
tau   = P(A=1 | T=1)   true-acceptance rate
Delta = tau - kappa    discrimination
Lambda= tau / kappa    likelihood ratio

Dedups per (arm, idx) keeping the FIRST record (gap-fill reruns appended later
must not overwrite original measurements). Writes kappa_table.tex and
consolidated.json.
"""
import json, math, datetime
from pathlib import Path

BENCH = Path.home() / "selfcorr-bench"
CUT_TASKS = 947  # full MBPP sweep; anything below this is labeled partial

FAMILIES = [
    ("DeepSeek-V4.1-Flash (cloud)", ["dsv4flash_mbpp.jsonl"]),
    ("GLM-5.3-Flash (cloud)",       ["glm53_mbpp.jsonl"]),
    ("Qwen-3.8-Flash (cloud)",      ["qwen38flash_mbpp.jsonl"]),
    ("GPT-5.4 (cloud)",             ["gpt54_mbpp.jsonl"]),
    ("GPT-6-Luna (cloud)",          ["gpt6luna_mbpp.jsonl"]),  # complete 947 ($0.78)
    ("Kimi-K2.8-hs (subscription)", ["kimi_mbpp.jsonl"]),
    ("Athena Flash-Next (local)",   ["athena_mbpp_s0.jsonl", "athena_mbpp_s1.jsonl",
                                     "athena_mbpp_c.jsonl", "athena_mbpp_d.jsonl",
                                     "athena_mbpp_e.jsonl", "athena_mbpp_f.jsonl",
                                     "athena_mbpp_g.jsonl", "athena_mbpp_h.jsonl",
                                     "athena_mbpp_w1.jsonl", "athena_mbpp_w2.jsonl"]),
]

def load_dedup(fns):
    """Load one or more shards; dedup on (arm, idx) keeping the FIRST record
    (gap-fill reruns appended later must not overwrite original measurements;
    for Athena the s0 shard wins over s1 where they overlap)."""
    seen, rows = set(), []
    for fn in fns:
        p = BENCH / fn
        if not p.exists():
            continue
        for line in open(p):
            if not line.strip():
                continue
            r = json.loads(line)
            if "T" not in r or "accept" not in r:   # error records (429s etc.)
                continue
            key = (r["arm"], r["idx"])
            if key in seen:
                continue
            seen.add(key)
            rows.append(r)
    return rows

def wilson(p, n, z=1.96):
    """Wilson score interval, matching the manuscript's stated convention."""
    d = 1 + z * z / n
    c = (p + z * z / (2 * n)) / d
    h = (z / d) * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n))
    return max(0, c - h), min(1, c + h)

def rate(records):
    t0 = [r for r in records if r["T"] == 0]
    t1 = [r for r in records if r["T"] == 1]
    out = {}
    for name, pool in (("kappa", t0), ("tau", t1)):
        if not pool:
            out[name] = None
            continue
        p = sum(r["accept"] for r in pool) / len(pool)
        out[name] = {"n": len(pool), "p": p, "ci": wilson(p, len(pool))}
    return out

report = {"generated": datetime.datetime.now().isoformat(), "families": {}}
tex_rows = []
print(f"{'model':30s} {'tasks':>5s} {'nT0':>5s} {'kappa%':>7s} {'CI':>15s} "
      f"{'nT1':>5s} {'tau%':>7s} {'Delta':>7s} {'Lambda':>7s}")
for name, fns in FAMILIES:
    rows = load_dedup(fns)
    if not rows:
        continue
    ntasks = len({r["idx"] for r in rows})
    fam = {}
    for arm in ("selfcheck", "steelman"):
        fam[arm] = rate([r for r in rows if r["arm"] == arm])
    fam["n_tasks"] = ntasks
    fam["partial"] = ntasks < CUT_TASKS
    report["families"][name] = fam

    sc, st = fam["selfcheck"], fam["steelman"]
    partial = " (partial)" if fam["partial"] else ""
    for arm, d in (("selfcheck", sc), ("steelman", st)):
        k, t = d.get("kappa"), d.get("tau")
        if k is None or t is None:
            continue
        delta = t["p"] - k["p"]
        lam = t["p"] / k["p"] if k["p"] > 0 else float("inf")
        d["delta"] = delta
        d["lambda"] = lam
        print(f"{name+(' / '+arm)+partial:30s} {ntasks:5d} {k['n']:5d} "
              f"{k['p']*100:6.1f}% [{k['ci'][0]*100:.1f},{k['ci'][1]*100:.1f}] "
              f"{t['n']:5d} {t['p']*100:6.1f}% {delta*100:6.1f} {lam:7.2f}")
        esc = name.replace("&", "\\&") + (" (partial)" if fam["partial"] else "")
        tex_rows.append(
            f"{esc} -- {arm} & {ntasks} & {k['n']} & {k['p']*100:.1f} & "
            f"[{k['ci'][0]*100:.1f}, {k['ci'][1]*100:.1f}] & {t['p']*100:.1f} & "
            f"{delta*100:.1f} & {lam:.2f} \\\\")

header = r"""\begin{table}[t]
\centering
\caption{MBPP results, seven model families. $\kappa = P(A{=}1 \mid T{=}0)$
(false-acceptance rate), $\tau = P(A{=}1 \mid T{=}1)$ (true-acceptance),
$\Delta = \tau - \kappa$, $\Lambda = \tau/\kappa$. Partial sweeps noted.}
\label{tab:kappa_mbpp}
\begin{tabular}{lrrccccc}
\hline
Model & $n_\text{tasks}$ & $n_{T=0}$ & $\hat\kappa$ (\%) & 95\% CI &
$\hat\tau$ (\%) & $\Delta$ (pt) & $\Lambda$ \\
\hline
"""
footer = "\\hline\n\\end{tabular}\n\\end{table}\n"
(BENCH / "kappa_table.tex").write_text(header + "\n".join(tex_rows) + "\n" + footer)
json.dump(report, open(BENCH / "consolidated.json", "w"), indent=2)
print("\nwrote kappa_table.tex and consolidated.json")
