#!/bin/bash
# Kimi single-stream runner. Fixed probe: 'T=None' anywhere = dead quota.
cd /home/Drew/selfcorr-bench
cov() { python3 -c "
import json
good={}
for l in open('kimi_mbpp.jsonl'):
    if not l.strip(): continue
    r=json.loads(l)
    if r.get('model')=='kimi-k28-hs' and 'T' in r and 'accept' in r: good.setdefault(r['idx'],set()).add(r['arm'])
print(sum(1 for i in range(947) if len(good.get(i,set()))==2))"; }
while [ "$(cov)" -lt 947 ]; do
  NEXT=$(python3 -c "
import json
good={}
for l in open('kimi_mbpp.jsonl'):
    if not l.strip(): continue
    r=json.loads(l)
    if r.get('model')=='kimi-k28-hs' and 'T' in r and 'accept' in r: good.setdefault(r['idx'],set()).add(r['arm'])
miss=[i for i in range(947) if len(good.get(i,set()))<2]
print(miss[0] if miss else -1)")
  [ "$NEXT" = "-1" ] && break
  rm -f kimi_probe.log kimi_probe.jsonl
  timeout 150 python3 harness.py --start $NEXT --end $((NEXT+1)) --bench mbpp --model kimi-k28-hs --arms selfcheck --out kimi_probe.jsonl --cap 5 >> kimi_probe.log 2>&1
  if grep -qE 'T=[01]' kimi_probe.log; then
    echo "$(date '+%F %T') quota LIVE — single stream from $NEXT (cov=$(cov))" >> kimi_watch.log
    python3 harness.py --start $NEXT --end 947 --bench mbpp --model kimi-k28-hs --arms selfcheck,steelman --sleep 5 --out kimi_mbpp.jsonl --cap 10 >> kimi_mbpp.log 2>&1
    echo "$(date '+%F %T') stream exited (cov=$(cov))" >> kimi_watch.log
  else
    echo "$(date '+%F %T') quota DEAD — retry in 20m" >> kimi_watch.log
  fi
  sleep 1200
done
echo "$(date '+%F %T') KIMI COMPLETE 947/947" >> kimi_watch.log
