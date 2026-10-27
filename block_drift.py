#!/usr/bin/env python3
"""Block-drift check: per-arm kappa in 5 contiguous task-index blocks.

Settles the flag from the partial sweeps (GLM kappa rose 65.9% -> 73.2% as n
grew). If the full-sweep estimate sits inside the block-level variation, the
pooled number stands; if early blocks diverge beyond sampling noise, the paper
needs a sentence on block composition.
"""
import json, math
from pathlib import Path

BENCH = Path.home() / "selfcorr-bench"
N_BLOCKS = 5
N_TASKS = 947

def wilson(p, n, z=1.96):
    d = 1 + z * z / n
    c = (p + z * z / (2 * n)) / d
    h = (z / d) * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n))
    return max(0, c - h), min(1, c + h)

def load_dedup(fn):
    seen, rows = set(), []
    for line in open(BENCH / fn):
        if not line.strip():
            continue
        r = json.loads(line)
        if "T" not in r or "accept" not in r:
            continue
        key = (r["arm"], r["idx"])
        if key in seen:
            continue
        seen.add(key)
        rows.append(r)
    return rows

for fn in ["dsv4flash_mbpp.jsonl", "glm53_mbpp.jsonl", "qwen38flash_mbpp.jsonl"]:
    rows = load_dedup(fn)
    print(f"\n=== {fn}  ({len({r['idx'] for r in rows})} tasks) ===")
    size = math.ceil(N_TASKS / N_BLOCKS)
    for arm in ("selfcheck", "steelman"):
        cells = []
        for b in range(N_BLOCKS):
            lo, hi = b * size, min((b + 1) * size, N_TASKS)
            pool = [r for r in rows
                    if r["arm"] == arm and lo <= r["idx"] < hi and r["T"] == 0]
            if not pool:
                cells.append((b, 0, None, None))
                continue
            p = sum(r["accept"] for r in pool) / len(pool)
            cells.append((b, len(pool), p, wilson(p, len(pool))))
        print(f"  {arm}:")
        for b, n, p, ci in cells:
            if p is None:
                print(f"    block {b} (idx {b*size}-{min((b+1)*size,N_TASKS)-1}): no T=0")
            else:
                print(f"    block {b} (idx {b*size}-{min((b+1)*size,N_TASKS)-1}): "
                      f"n={n:3d} kappa={p*100:5.1f}%  [{ci[0]*100:.1f}, {ci[1]*100:.1f}]")
        vals = [p for _, n, p, _ in cells if p is not None and n >= 20]
        if vals:
            print(f"    spread: {min(vals)*100:.1f}% .. {max(vals)*100:.1f}%  "
                  f"(max-min = {(max(vals)-min(vals))*100:.1f} pt)")
