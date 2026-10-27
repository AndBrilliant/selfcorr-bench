#!/bin/bash
# Full-947 kimi-hs via monthly plan: two disjoint half-ranges, supervisor
# relaunches each half while it has missing pairs; on quota death (no progress)
# it backs off 20 min per retry. Runs until 947 covered.
cd /home/Drew/selfcorr-bench
cov() { python3 -c "
import json
good={}
for l in open('kimi_mbpp.jsonl'):
    if not l.strip(): continue
    r=json.loads(l)
    if r.get('model')=='kimi-k28-hs' and 'T' in r and 'accept' in r: good.setdefault(r['idx'],set()).add(r['arm'])
print(sum(1 for i in range(947) if len(good.get(i,set()))==2))"; }
half_count() { python3 -c "
import json
good={}
for l in open('kimi_mbpp.jsonl'):
    if not l.strip(): continue
    r=json.loads(l)
    if r.get('model')=='kimi-k28-hs' and 'T' in r and 'accept' in r: good.setdefault(r['idx'],set()).add(r['arm'])
lo,hi=$1
print(sum(1 for i in range(lo,hi) if len(good.get(i,set()))==2))"; }
declare -A LAST=( [1]=-1 [2]=-1 )
while [ "$(cov)" -lt 947 ]; do
  for H in 1 2; do
    if [ $H = 1 ]; then LO=160; HI=550; else LO=550; HI=947; fi
    C=$(half_count $LO $HI)
    RUNNING=$(pgrep -fc "[h]arness.py.*kimi-k28-hs.*--start $LO")
    if [ "$RUNNING" = "0" ]; then
      NEEDS=$(python3 -c "
import json
good={}
for l in open('kimi_mbpp.jsonl'):
    if not l.strip(): continue
    r=json.loads(l)
    if r.get('model')=='kimi-k28-hs' and 'T' in r and 'accept' in r: good.setdefault(r['idx'],set()).add(r['arm'])
lo,hi=$LO,$HI
miss=[i for i in range(lo,hi) if len(good.get(i,set()))<2]
print(miss[0] if miss else -1)")
      if [ "$NEEDS" != "-1" ]; then
        if [ "${LAST[$H]}" = "$C" ]; then
          echo "$(date '+%F %T') half$H no progress (quota?) — backoff 20m" >> kimi_watch.log
          sleep 1200
        fi
        echo "$(date '+%F %T') half$H launch $NEEDS->$HI (halfcov=$C total=$(cov))" >> kimi_watch.log
        setsid nohup python3 harness.py --start $NEEDS --end $HI --bench mbpp --model kimi-k28-hs --arms selfcheck,steelman --out kimi_mbpp.jsonl --cap 10 >> kimi_mbpp.log 2>&1 < /dev/null &
        LAST[$H]=$C
      fi
    fi
  done
  sleep 300
done
echo "$(date '+%F %T') KIMI COMPLETE 947/947" >> kimi_watch.log
