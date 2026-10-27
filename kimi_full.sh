#!/bin/bash
# Full-947 kimi-hs: two disjoint halves; supervisor PROBES before each launch
# (no more fast-fail spam through dead windows), backs off 20 min on dead quota,
# and logs the parsed error class. Runs until 947 covered.
cd /home/Drew/selfcorr-bench
cov() { python3 -c "
import json
good={}
for l in open('kimi_mbpp.jsonl'):
    if not l.strip(): continue
    r=json.loads(l)
    if r.get('model')=='kimi-k28-hs' and 'T' in r and 'accept' in r: good.setdefault(r['idx'],set()).add(r['arm'])
print(sum(1 for i in range(947) if len(good.get(i,set()))==2))"; }
probe() {  # $1 = idx to probe; returns 0 if quota live
  rm -f kimi_probe.log kimi_probe.jsonl
  timeout 120 python3 harness.py --start $1 --end $(( $1 + 1 )) --bench mbpp --model kimi-k28-hs --arms selfcheck --out kimi_probe.jsonl --cap 5 >> kimi_probe.log 2>&1
  grep -q 'T=' kimi_probe.log && ! tail -1 kimi_probe.log | grep -q 'T=None'
}
while [ "$(cov)" -lt 947 ]; do
  for H in 1 2; do
    if [ $H = 1 ]; then LO=160; HI=550; else LO=550; HI=947; fi
    RUNNING=$(pgrep -fc "[h]arness.py.*kimi-k28-hs.*--start $LO")
    if [ "$RUNNING" != "0" ]; then continue; fi
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
    [ "$NEEDS" = "-1" ] && continue
    if probe $NEEDS; then
      echo "$(date '+%F %T') half$H live — launch $NEEDS->$HI (total=$(cov))" >> kimi_watch.log
      setsid nohup python3 harness.py --start $NEEDS --end $HI --bench mbpp --model kimi-k28-hs --arms selfcheck,steelman --out kimi_mbpp.jsonl --cap 10 >> kimi_mbpp.log 2>&1 < /dev/null &
    else
      ERR=$(python3 -c "
import json
e=[json.loads(l) for l in open('kimi_mbpp.jsonl') if l.strip() and 'T' not in json.loads(l)]
print((e[-1].get('error','?') if e else '?')[:90])" 2>/dev/null)
      echo "$(date '+%F %T') half$H probe DEAD: $ERR — backoff 20m" >> kimi_watch.log
      sleep 1200
    fi
  done
  sleep 300
done
echo "$(date '+%F %T') KIMI COMPLETE 947/947" >> kimi_watch.log
