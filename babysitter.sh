#!/bin/bash
# Overnight/day babysitter. Logs every cycle; relaunches dead runners;
# regenerates athena spans from live coverage; commits on completion.
cd /home/Drew/selfcorr-bench
LOCK=/home/Drew/selfcorr-bench/.babysitter.lock
exec 9>$LOCK
flock -n 9 || { echo "$(date '+%F %T') babysitter already running" >> overnight.log; exit 0; }
while true; do
  A=$(python3 -c "
import json
good={}
for i in range(1,7):
    try:
        for l in open(f'athena_b{i}.jsonl'):
            if not l.strip(): continue
            r=json.loads(l)
            if 'T' in r and 'accept' in r: good.setdefault(r['idx'],set()).add(r['arm'])
    except FileNotFoundError: pass
for f in ('athena_mbpp_s0.jsonl','athena_mbpp_s1.jsonl','athena_mbpp_c.jsonl','athena_mbpp_d.jsonl','athena_mbpp_e.jsonl','athena_mbpp_f.jsonl','athena_mbpp_g.jsonl','athena_mbpp_h.jsonl','athena_mbpp_w1.jsonl','athena_mbpp_w2.jsonl','athena_single.jsonl'):
    try:
        for l in open(f):
            if not l.strip(): continue
            r=json.loads(l)
            if 'T' in r and 'accept' in r: good.setdefault(r['idx'],set()).add(r['arm'])
    except FileNotFoundError: pass
print(sum(1 for i in range(947) if len(good.get(i,set()))==2))" 2>/dev/null)
  K=$(python3 -c "
import json
good={}
for l in open('kimi_mbpp.jsonl'):
    if not l.strip(): continue
    r=json.loads(l)
    if r.get('model')=='kimi-k28-hs' and 'T' in r and 'accept' in r: good.setdefault(r['idx'],set()).add(r['arm'])
print(sum(1 for i in range(947) if len(good.get(i,set()))==2))" 2>/dev/null)
  AB=$(pgrep -fc 'harness.py.*athena' 2>/dev/null || echo 0)
  KB=$(pgrep -fc 'harness.py.*kimi' 2>/dev/null || echo 0)
  echo "$(date '+%F %T') athena=$A/947 (procs=$AB) kimi=$K/947 (procs=$KB)" >> overnight.log
  if [ "$A" -ge 947 ] && [ ! -f .athena_done ]; then
    touch .athena_done
    echo "$(date '+%F %T') ATHENA COMPLETE" >> overnight.log
    python3 final_table.py >> final_table_run.log 2>&1
    git --git-dir=/ARCHIVE/GIT_REPOS/selfcorr-bench.git --work-tree=$PWD add -A
    git --git-dir=/ARCHIVE/GIT_REPOS/selfcorr-bench.git --work-tree=$PWD commit -q -m "athena sweep complete" || true
  fi
  if [ "$K" -ge 947 ] && [ ! -f .kimi_done ]; then
    touch .kimi_done
    echo "$(date '+%F %T') KIMI COMPLETE" >> overnight.log
    python3 final_table.py >> final_table_run.log 2>&1
    git --git-dir=/ARCHIVE/GIT_REPOS/selfcorr-bench.git --work-tree=$PWD add -A
    git --git-dir=/ARCHIVE/GIT_REPOS/selfcorr-bench.git --work-tree=$PWD commit -q -m "kimi sweep complete" || true
  fi
  [ "$A" -ge 947 ] && [ "$K" -ge 947 ] && break
  # relaunch athena runners if all dead and incomplete
  if [ "$AB" -eq 0 ] && [ "$A" -lt 947 ]; then
    echo "$(date '+%F %T') athena runners dead — regenerating + relaunching" >> overnight.log
    python3 - <<'PYEOF'
import json
good={}
for i in range(1,7):
    try:
        for l in open(f'athena_b{i}.jsonl'):
            if not l.strip(): continue
            r=json.loads(l)
            if 'T' in r and 'accept' in r: good.setdefault(r['idx'],set()).add(r['arm'])
    except FileNotFoundError: pass
for f in ('athena_mbpp_s0.jsonl','athena_mbpp_s1.jsonl','athena_mbpp_c.jsonl','athena_mbpp_d.jsonl','athena_mbpp_e.jsonl','athena_mbpp_f.jsonl','athena_mbpp_g.jsonl','athena_mbpp_h.jsonl','athena_mbpp_w1.jsonl','athena_mbpp_w2.jsonl','athena_single.jsonl'):
    try:
        for l in open(f):
            if not l.strip(): continue
            r=json.loads(l)
            if 'T' in r and 'accept' in r: good.setdefault(r['idx'],set()).add(r['arm'])
    except FileNotFoundError: pass
miss=[i for i in range(947) if len(good.get(i,set()))<2]
spans=[]
for i in miss:
    if spans and i==spans[-1][1]+1: spans[-1][1]=i
    else: spans.append([i,i])
third=(len(miss)*2+2)//3
shards=[[],[],[]]; acc=0; k=0
for sp in spans:
    n=(sp[1]-sp[0]+1)*2
    shards[min(k,2)].append(sp); acc+=n
    if acc>=third and k<2: k+=1; acc=0
for j,sh in enumerate(shards,1):
    if not sh: continue
    lines="\n".join(f"python3 harness.py --start {a} --end {b+1} --bench mbpp --model athena-flash --arms selfcheck,steelman --sleep 15 --out athena_b{j}.jsonl --cap 10 >> athena_b{j}.log 2>&1" for a,b in sh)
    open(f"athena_b{j}.sh","w").write(f"#!/bin/bash\ncd /home/Drew/selfcorr-bench\n{lines}\necho B{j}_DONE\n")
PYEOF
    chmod +x athena_b*.sh 2>/dev/null
    for i in 1 2 3; do [ -f athena_b$i.sh ] && setsid nohup bash athena_b$i.sh >> athena_b$i.out 2>&1 < /dev/null & done
  fi
  # relaunch kimi gate if dead and incomplete
  if ! pgrep -f "[k]imi_paced" > /dev/null && [ "$K" -lt 947 ]; then
    echo "$(date '+%F %T') kimi gate dead — relaunching" >> overnight.log
    setsid nohup bash kimi_paced.sh >> kimi_paced.out 2>&1 < /dev/null &
  fi
  sleep 600
done
echo "$(date '+%F %T') ALL SWEEPS COMPLETE — babysitter exiting" >> overnight.log
