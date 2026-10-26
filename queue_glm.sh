#!/bin/bash
# Waits for DeepSeek sweep to finish (COST line), then launches GLM-5.3-flash automatically.
cd /home/Drew/selfcorr-bench
while ! grep -q COST dsv4flash_mbpp.log 2>/dev/null; do sleep 120; done
sleep 30
nohup setsid python3 harness.py --start 0 --end 947 --bench mbpp --model glm-5.3-flash \
  --arms selfcheck,steelman --out glm53_mbpp.jsonl --cap 10 > glm53_mbpp.log 2>&1 < /dev/null &
echo "$(date '+%H:%M:%S') deepseek finished; glm-5.3-flash launched" >> queue_log.txt
