#!/bin/bash
# Kill any live harness workers (match on cmdline from /proc, not pgrep -f,
# so this script's own cmdline never matches), then relaunch two disjoint workers.
for p in $(pgrep -f 'harness\.py' 2>/dev/null); do
  cmd=$(tr '\0' ' ' < /proc/$p/cmdline 2>/dev/null)
  case "$cmd" in
    *"harness.py --start"*) kill "$p" 2>/dev/null && echo "killed $p";;
  esac
done
sleep 2
cd /home/Drew/selfcorr-bench
nohup setsid python3 harness.py --start 37 --end 490 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_mbpp_s1.jsonl --cap 5 > athena_mbpp_s1.log 2>&1 < /dev/null &
nohup setsid python3 harness.py --start 490 --end 947 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_mbpp_s3.jsonl --cap 5 > athena_mbpp_s3.log 2>&1 < /dev/null &
sleep 3
for p in $(pgrep -f 'harness\.py' 2>/dev/null); do
  cmd=$(tr '\0' ' ' < /proc/$p/cmdline 2>/dev/null)
  case "$cmd" in *"harness.py --start"*) echo "ALIVE $p $(echo $cmd | grep -o '\-\-start [0-9]* --end [0-9]*')";; esac
done
