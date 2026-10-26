#!/usr/bin/env python3
"""Self-correction blind-spot benchmark on HumanEval (CorrectBench code track).

Arms (differ only in evaluator access):
  selfcheck : generate, then self-check "correct? YES/NO"          (T=0, weak G)
  steelman  : generate, then self-debate under rigorous rubric     (T=1a, strong G)
  external  : generate, execute vs unit tests, revise on failure   (T=1b, Z)

Per arm: T = final code passes tests (ground truth), A = evaluator accepts.
kappa = Pr(A=1|T=0), tau = Pr(A=1|T=1), Delta = tau-kappa, Lambda = tau/kappa, E = log2(Lambda).
"""
import argparse, ast, json, os, re, subprocess, sys, tempfile, time
from pathlib import Path

sys.path.insert(0, "/home/Drew/mcp-servers/paper-tools/check-citations")
import api_client

BENCH = Path.home() / "selfcorr-bench"

DANGEROUS = {"os","subprocess","sys","socket","shutil","pickle","ctypes",
             "importlib","builtins","pathlib","tempfile","webbrowser","requests",
             "urllib","http","smtplib","ftplib","telnetlib","multiprocessing",
             "signal","resource","gc","inspect"}
DANGEROUS_CALLS = {"eval","exec","open","__import__","compile","input",
                   "breakpoint","system","popen","getattr","setattr","delattr",
                   "globals","locals","vars","exit","quit"}

# Prepended to executed code so `List` etc. resolve no matter how the model
# formats its answer. sys is present for rare maxsize uses; ast_guard still
# blocks sys.exit()/sys.* calls in the MODEL's code.
SAFE_HEADER = ("from typing import *\n"
               "import math, re, collections, itertools, heapq, bisect, string, "
               "functools, operator, random, statistics, cmath, fractions, "
               "decimal, datetime, copy, sys\n")

def load_rows(bench="humaneval"):
    fn = {"humaneval": "HumanEval.jsonl", "mbpp": "MBPP.jsonl"}[bench.lower()]
    return [json.loads(l) for l in open(BENCH / fn)]

def extract_code(text, prompt, entry_point):
    t = (text or "").strip()
    m = re.search(r"```(?:python|py)?\s*\n?(.*?)```", t, re.DOTALL)
    if m:
        t = m.group(1).strip()
    lines = t.split("\n")
    start = None
    for i, ln in enumerate(lines):
        s = ln.strip()
        if s.startswith("def ") or s.startswith("import ") or s.startswith("from "):
            start = i
            break
    if start is not None:
        return "\n".join(lines[start:])
    return prompt.rstrip() + "\n" + t

def ast_guard(code):
    try:
        tree = ast.parse(code)
    except SyntaxError as e:
        return False, f"syntax error: {str(e)[:80]}"
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            for a in node.names:
                if a.name.split(".")[0] in DANGEROUS:
                    return False, f"blocked import {a.name}"
        elif isinstance(node, ast.ImportFrom):
            if node.module and node.module.split(".")[0] in DANGEROUS:
                return False, f"blocked from-import {node.module}"
        elif isinstance(node, ast.Call):
            f = node.func
            nm = f.id if isinstance(f, ast.Name) else (f.attr if isinstance(f, ast.Attribute) else None)
            if nm in DANGEROUS_CALLS:
                return False, f"blocked {nm}()"
            if isinstance(f, ast.Attribute) and isinstance(f.value, ast.Name) \
               and f.value.id in DANGEROUS:
                return False, f"blocked {f.value.id}.{f.attr}"
    return True, ""

def run_tests(code, test, entry_point):
    ok, why = ast_guard(code)
    if not ok:
        return False, why
    runner = SAFE_HEADER + "\n" + code + "\n\n" + test + "\n\ncheck(" + entry_point + ")\nprint('PASS')\n"
    path = None
    try:
        with tempfile.NamedTemporaryFile("w", suffix=".py", delete=False, dir="/tmp") as tf:
            tf.write(runner); path = tf.name
        r = subprocess.run(["python3", path], capture_output=True, text=True, timeout=15)
        if r.returncode == 0 and "PASS" in r.stdout:
            return True, "pass"
        err = (r.stderr or r.stdout or "").strip()
        if "AssertionError" in err:
            return False, "assertion failed: " + (err.splitlines()[-1][:160] if err.splitlines() else "")
        return False, (err or f"exit {r.returncode}")[:200]
    except subprocess.TimeoutExpired:
        return False, "timeout"
    finally:
        if path and os.path.exists(path):
            os.unlink(path)

def generate(prompt, model):
    return api_client.call_model(model, prompt, label="gen", temperature=0)

def yesno(out):
    m = re.search(r"\b(YES|NO)\b", (out or "").upper())
    return (m.group(1) == "YES") if m else False

def arm_selfcheck(row, model):
    prompt, test, ep = row["prompt"], row["test"], row["entry_point"]
    gen = generate(prompt, model)
    code = extract_code(gen, prompt, ep)
    t, why = run_tests(code, test, ep)
    p = (f"Here is a coding problem and a candidate solution.\n\n[PROBLEM]\n{prompt}\n\n"
         f"[SOLUTION]\n{code}\n\nIs the solution correct? Answer with a single word "
         f"YES or NO, then a one-sentence reason.")
    out = api_client.call_model(model, p, label="selfcheck", temperature=0)
    return dict(arm="selfcheck", T=int(t), accept=int(yesno(out)), why=why,
                verdict_text=out[:400])

def arm_steelman(row, model):
    prompt, test, ep = row["prompt"], row["test"], row["entry_point"]
    gen = generate(prompt, model)
    code = extract_code(gen, prompt, ep)
    p = (f"You are a neutral arbiter judging a debate between two expert Python "
         f"programmers who are exactly as capable as you and will not bluff. Every "
         f"claim must survive scrutiny, not merely be plausible.\n\n"
         f"Here is a coding problem:\n\n[PROBLEM]\n{prompt}\n\n"
         f"Here is one candidate's solution:\n\n[SOLUTION]\n{code}\n\n"
         f"Do the following in order:\n"
         f"1. STEELMAN AGAINST: the strongest case that the solution is WRONG. Hunt "
         f"every bug: edge cases, off-by-one errors, type mismatches, logic flaws. "
         f"Argue as an expert who disagrees and is exactly as smart as you.\n"
         f"2. STEELMAN FOR: the strongest case the solution is RIGHT.\n"
         f"3. VERDICT: which case survives scrutiny. If correct, ACCEPT. If you found "
         f"a real bug, REJECT and give the corrected complete function in a ```python block.\n\n"
         f"End with exactly one line: VERDICT: ACCEPT  or  VERDICT: REJECT")
    out = api_client.call_model(model, p, label="steelman", temperature=0)
    m = re.search(r"VERDICT:\s*(ACCEPT|REJECT)", out.upper())
    verdict = m.group(1) if m else ("ACCEPT" if "ACCEPT" in out.upper() else "REJECT")
    accept = (verdict == "ACCEPT")
    final = code
    if verdict == "REJECT":
        nc = extract_code(out, prompt, ep)
        if nc and nc.strip() != code.strip():
            final = nc
    t, why = run_tests(final, test, ep)
    return dict(arm="steelman", T=int(t), accept=int(accept), why=why,
                verdict=verdict, revised=int(final.strip() != code.strip()),
                verdict_text=out[:700])

def arm_external(row, model):
    prompt, test, ep = row["prompt"], row["test"], row["entry_point"]
    gen = generate(prompt, model)
    code = extract_code(gen, prompt, ep)
    t, why = run_tests(code, test, ep)
    final = code
    nrev = 0
    if not t:
        p = (f"Here is a coding problem and your candidate solution.\n\n"
             f"[PROBLEM]\n{prompt}\n\n[YOUR SOLUTION]\n{code}\n\n"
             f"The solution was executed against unit tests and FAILED:\n\n{why}\n\n"
             f"Fix the solution. Return ONLY the corrected complete function in a "
             f"```python block.")
        out = api_client.call_model(model, p, label="external-revise", temperature=0)
        nc = extract_code(out, prompt, ep)
        if nc and nc.strip() != code.strip():
            final, nrev = nc, 1
        t, why = run_tests(final, test, ep)
    p = (f"Here is a coding problem and your final solution.\n\n"
         f"[PROBLEM]\n{prompt}\n\n[FINAL SOLUTION]\n{final}\n\n"
         f"Execution result: {'PASS' if t else 'FAIL: ' + why}. Is your final solution "
         f"correct? Answer YES or NO.")
    out = api_client.call_model(model, p, label="external-verdict", temperature=0)
    return dict(arm="external", T=int(t), accept=int(yesno(out)), why=why,
                nrev=nrev, verdict_text=out[:300])

ARMS = {"selfcheck": arm_selfcheck, "steelman": arm_steelman, "external": arm_external}

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--start", type=int, default=0)
    ap.add_argument("--end", type=int, default=3)
    ap.add_argument("--model", default="gpt-5.4")
    ap.add_argument("--out", default="results.jsonl")
    ap.add_argument("--cap", type=float, default=25.0)
    ap.add_argument("--arms", default="selfcheck,steelman,external")
    ap.add_argument("--bench", default="humaneval", choices=["humaneval", "mbpp"])
    args = ap.parse_args()
    api_client.configure_tracker(args.cap)
    rows = load_rows(args.bench)
    armnames = [a.strip() for a in args.arms.split(",")]
    outpath = BENCH / args.out
    for i in range(args.start, min(args.end, len(rows))):
        row = rows[i]
        tid = row["task_id"]
        for an in armnames:
            t0 = time.time()
            try:
                rec = ARMS[an](row, args.model)
            except Exception as e:
                rec = dict(arm=an, error=f"{type(e).__name__}: {str(e)[:250]}")
            rec.update(task_id=tid, idx=i, model=args.model,
                       seconds=round(time.time() - t0, 1))
            with open(outpath, "a") as f:
                f.write(json.dumps(rec) + "\n")
            print(f"[{i}] {tid} {an}: T={rec.get('T')} A={rec.get('accept')} "
                  f"{rec.get('seconds')}s", flush=True)
    print("COST", json.dumps(api_client.get_tracker().summary()), flush=True)

if __name__ == "__main__":
    main()
