#!/usr/bin/env python3
"""kappa = P(A=1 | T=0): the model acts (accepts) though no trigger occurred."""
import json, math, datetime

def load(f):
    try:
        return [json.loads(l) for l in open(f) if l.strip()]
    except FileNotFoundError:
        return []

def kappa(rows):
    t0 = [r for r in rows if r.get('T') == 0]
    if not t0: return None, 0, 0
    k = sum(1 for r in t0 if r.get('accept') == 1)
    p = k/len(t0)
    z = 1.96; s = math.sqrt(p*(1-p)/len(t0))
    return p, len(t0), (max(0,p-z*s), min(1,p+z*s))

models = {
 'DeepSeek-V3.2 (cloud)': 'deepseek_v32_mbpp.jsonl',
 'GLM-5.3-Flash (cloud)': 'glm53_mbpp.jsonl',
 'Qwen-3.8-Flash (cloud)': 'qwen38flash_mbpp.jsonl',
 'Athena-s1 (local)': 'athena_s1_mbpp.jsonl',
 'Athena-s0 (local)': 'athena_s0_mbpp.jsonl',
}
report = {'generated': datetime.datetime.now().isoformat(), 'kappa': {}}
print(f"{'model':26s} {'n(T=0)':>7s} {'kappa':>7s} {'95% CI':>17s}")
for name, f in models.items():
    rows = load(f)
    p, n, ci = kappa(rows)
    if p is None:
        print(f"{name:26s}  -- no T=0 records --"); continue
    report['kappa'][name] = {'n': n, 'p': p, 'ci': list(ci)}
    print(f"{name:26s} {n:7d} {p*100:6.1f}%  [{ci[0]*100:.1f}%, {ci[1]*100:.1f}%]")
json.dump(report, open('consolidated.json','w'), indent=2)
print('wrote consolidated.json')
