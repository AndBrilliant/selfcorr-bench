#!/bin/bash
cd /home/Drew/selfcorr-bench
while true; do
  D=$(wc -l < dsv4flash_mbpp.jsonl 2>/dev/null || echo 0)
  A=$(cat athena_mbpp_s0.jsonl athena_mbpp_s1.jsonl 2>/dev/null | wc -l)
  DP=$(pgrep -fc 'harness.py.*ds-v4-flash' || echo 0)
  AP=$(pgrep -fc 'harness.py.*athena-flash' || echo 0)
  echo "$(date '+%H:%M:%S') ds=$D(ds_procs=$DP) athena=$A(athena_procs=$AP)" >> sweep_watchdog.log
  sleep 600
done
