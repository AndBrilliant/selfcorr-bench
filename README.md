# Self-Correction Benchmark: Cross-Model Measurement on MBPP

Companion data to the paper *"Limits of Self-Correction in LLMs: An Information-Theoretic Analysis of Correlated Errors"* (Section: Cross-Model Measurement on MBPP). The HumanEval paired experiment is audited in the separate repository [human-eval-selfcorr](https://github.com/AndBrilliant/human-eval-selfcorr).

## Protocol

The full 947-task MBPP corpus is frozen as a fixed candidate set: one immutable candidate per task, generated once. Each candidate is then judged by the model family that produced it, under two evaluator conditions:

- **selfcheck** — a plain self-check prompt ("check your work") in a fresh context.
- **steelman** — a structured adversarial prompt that first argues the candidate is correct, then asks the evaluator to name any failure it actually believes.

Accepted quantities:

- **κ** = P(A=1 | T=0) — false-acceptance rate: the evaluator accepts a candidate that fails the reference tests.
- **τ** = P(A=1 | T=1) — true-acceptance rate: the evaluator accepts a candidate that passes the reference tests.
- **Δ** = τ − κ, **Λ** = τ/κ — separation and dominance ratios.

## Model families

| Family | Data file | Status |
|---|---|---|
| DeepSeek-V4.1-Flash | `dsv4flash_mbpp.jsonl` | 947/947 |
| GLM-5.3-Flash | `glm53_mbpp.jsonl` | 947/947 |
| Qwen-3.8-Flash | `qwen38flash_mbpp.jsonl` | 947/947 |
| GPT-5.4 | `gpt54_mbpp.jsonl` | 947/947 |
| GPT-6-Luna | `gpt6luna_mbpp.jsonl` | 947/947 |
| Kimi-K2.7-code | `k27code_mbpp.jsonl` | partial (mid-sweep) |
| Athena Flash-Next (local) | `athena_mbpp_*.jsonl` (shards) | 947/947 |

Athena's data is stored as shards (`athena_mbpp_s0.jsonl`, `athena_mbpp_s1.jsonl`, and gap-fill suffixes) — `final_table.py` dedupes on `(arm, idx)` keeping the FIRST record per (arm, task), so gap-fill reruns never overwrite original measurements.

## Reproducing the table

```bash
python3 scripts/final_table.py
```

writes `kappa_table.tex` and `consolidated.json` — the paper's Table (κ per family, 95% Wilson CIs, Δ, Λ).

## Contents

- `MBPP.jsonl` — the 947-task corpus (task id, prompt, code, reference tests)
- `*_mbpp.jsonl` — raw evaluator outputs per family: `idx`, `task_id`, `arm`, `T`, `accept`, `verdict_text`, `why`, `seconds`, `model`
- `scripts/` — `final_table.py`, `block_drift.py`, `consolidate.py`, `harness.py` (runner), `analyze.py`

The block-drift analysis (`block_drift.py`) examines κ variation across task blocks and motivates the paper's wide-interval reading of small-n point estimates.

## License

CC BY-NC-SA 4.0 (attribution required, non-commercial, share-alike).
