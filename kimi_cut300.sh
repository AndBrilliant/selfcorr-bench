#!/bin/bash
# Drive kimi-hs to the 300-task precision cut, then STOP (weekly cap is at 50%).
cd /home/Drew/selfcorr-bench
cov() { python3 -c "
import json
good={}
for l in open('kimi_mbpp.jsonl'):
    if not l.strip(): continue
    r=json.loads(l)
    if r.get('model')=='kimi-k28-hs' and 'T' in r and 'accept' in r: good.setdefault(r['idx'],set()).add(r['arm'])
print(sum(1 for i in range(947) if len(good.get(i,set()))==2))"; }
while [ "$(cov)" -lt 300 ]; do
  if ! pgrep -f "[h]arness.py.*kimi-k28-hs" > /dev/null; then
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
    echo "$(date '+%F %T') cut300: resuming from $NEXT (covered=$(cov))" >> kimi_watch.log
    python3 harness.py --start $NEXT --end 947 --bench mbpp --model kimi-k28-hs --arms selfcheck,steelman --out kimi_mbpp.jsonl --cap 10 >> kimi_mbpp.log 2>&1
    if [ "$(cov)" -lt 300 ]; then
      echo "$(date '+%F %T') quota died below cut; next window in 5h05m" >> kimi_watch.log
      sleep 12600
      for i in $(seq 1 9); do
        rm -f kimi_probe.log kimi_probe.jsonl
        timeout 120 python3 harness.py --start $NEXT --end $((NEXT+1)) --bench mbpp --model kimi-k28-hs --arms selfcheck --out kimi_probe.jsonl --cap 5 >> kimi_probe.log 2>&1
        grep -q 'T=' kimi_probe.log && ! tail -1 kimi_probe.log | grep -q 'T=None' && break
        sleep 1200
      done
    fi
  fi
  sleep 120
done
echo "$(date '+%F %T') KIMI 300-TASK CUT MET (covered=$(cov)) — frozen" >> kimi_watch.log
