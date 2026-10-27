#!/bin/bash
# Sleep until 00:00 JST tonight, then resume kimi-hs 160->947.
# If quota is still dead at midnight, fall back to 20-min probes until it answers.
cd /home/Drew/selfcorr-bench
TARGET=$(date -d "tomorrow 00:00" +%s)
NOW=$(date +%s)
SLEEP_S=$((TARGET - NOW))
echo "$(date '+%F %T') sleeping $SLEEP_S s until midnight" >> kimi_watch.log
sleep "$SLEEP_S"
echo "$(date '+%F %T') midnight reached — probing quota" >> kimi_watch.log
while true; do
  rm -f kimi_probe.log
  timeout 120 python3 harness.py --start 160 --end 161 --bench mbpp --model kimi-k28-hs --arms selfcheck --out kimi_probe.jsonl --cap 5 >> kimi_probe.log 2>&1
  if grep -q 'T=' kimi_probe.log && ! tail -1 kimi_probe.log | grep -q 'T=None'; then
    echo "$(date '+%F %T') QUOTA LIVE — launching kimi-hs 160->947" >> kimi_watch.log
    python3 harness.py --start 160 --end 947 --bench mbpp --model kimi-k28-hs --arms selfcheck,steelman --out kimi_mbpp.jsonl --cap 10 >> kimi_mbpp.log 2>&1
    echo "$(date '+%F %T') KIMI RESUME EXITED rc=$?" >> kimi_watch.log
    break
  fi
  echo "$(date '+%F %T') midnight+probe: still dead, retry in 20m" >> kimi_watch.log
  sleep 1200
done
