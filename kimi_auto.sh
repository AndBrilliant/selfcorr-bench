#!/bin/bash
# Cycle kimi-hs resume through 5h subscription windows until 947 complete.
cd /home/Drew/selfcorr-bench
while true; do
  NEXT=$(python3 -c "
import json
good={}
for l in open('kimi_mbpp.jsonl'):
    if not l.strip(): continue
    r=json.loads(l)
    if r.get('model')=='kimi-k28-hs' and 'T' in r and 'accept' in r: good.setdefault(r['idx'],set()).add(r['arm'])
miss=[i for i in range(947) if len(good.get(i,set()))<2]
print(miss[0] if miss else -1)")
  if [ "$NEXT" = "-1" ]; then echo "$(date '+%F %T') KIMI COMPLETE" >> kimi_watch.log; break; fi
  echo "$(date '+%F %T') resuming from idx $NEXT" >> kimi_watch.log
  python3 harness.py --start $NEXT --end 947 --bench mbpp --model kimi-k28-hs --arms selfcheck,steelman --out kimi_mbpp.jsonl --cap 10 >> kimi_mbpp.log 2>&1
  echo "$(date '+%F %T') run exited; probing quota in 5h window cycle" >> kimi_watch.log
  sleep 12600   # wait out the 5h window (5h05m), then loop re-probes by running the next resume
  # quick probe: if still dead, keep sleeping in 20m increments
  for i in $(seq 1 9); do
    rm -f kimi_probe.log
    timeout 120 python3 harness.py --start $NEXT --end $((NEXT+1)) --bench mbpp --model kimi-k28-hs --arms selfcheck --out kimi_probe.jsonl --cap 5 >> kimi_probe.log 2>&1
    if grep -q 'T=' kimi_probe.log && ! tail -1 kimi_probe.log | grep -q 'T=None'; then rm -f kimi_probe.jsonl; break; fi
    echo "$(date '+%F %T') still dead, retry 20m" >> kimi_watch.log
    sleep 1200
  done
done
