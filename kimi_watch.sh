#!/bin/bash
# Probe kimi quota every 20 min; when it answers, resume the sweep 160->947.
cd /home/Drew/selfcorr-bench
while true; do
  sleep 1200
  timeout 120 python3 harness.py --start 160 --end 161 --bench mbpp --model kimi-k28-hs --arms selfcheck --out kimi_probe.jsonl --cap 5 >> kimi_probe.log 2>&1
  if grep -q 'T=' kimi_probe.log && ! tail -1 kimi_probe.log | grep -q 'T=None'; then
    echo "$(date '+%F %T') QUOTA BACK — resuming kimi 160->947" >> kimi_watch.log
    python3 harness.py --start 160 --end 947 --bench mbpp --model kimi-k28-hs --arms selfcheck,steelman --out kimi_mbpp.jsonl --cap 10 >> kimi_mbpp.log 2>&1
    echo "$(date '+%F %T') KIMI RESUME EXITED rc=$?" >> kimi_watch.log
    break
  fi
  echo "$(date '+%F %T') still quota-dead" >> kimi_watch.log
done
