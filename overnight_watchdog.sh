#!/bin/bash
# Overnight self-healing watchdog for the IJCS benchmark sweeps (2026-10-28 night).
# Athena: hard-verifies generation, relaunches the locked master, restarts the
#   llama-server on stall, reboots the box if the service restart is insufficient.
# Kimi: self-managed by kimi_full.sh (window cycling); watchdog only logs status.
# When either sweep reaches full coverage, refreshes consolidated.json + commits.
cd /home/Drew/selfcorr-bench
ATHENA=192.168.2.105
gen_ok() { timeout 40 curl -s -m 30 http://$ATHENA:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"x","messages":[{"role":"user","content":"Say OK"}],"max_tokens":5}' | grep -q '"content"'; }
cov_athena() { python3 -c "
import json
good={}
for i in range(1,7):
    try:
        for l in open(f'athena_mbpp_x{i}.jsonl'):
            if not l.strip(): continue
            r=json.loads(l)
            if 'T' in r and 'accept' in r: good.setdefault(r['idx'],set()).add(r['arm'])
    except FileNotFoundError: pass
for f in ('athena_mbpp_s0.jsonl','athena_mbpp_s1.jsonl','athena_mbpp_c.jsonl','athena_mbpp_d.jsonl','athena_mbpp_e.jsonl','athena_mbpp_f.jsonl','athena_mbpp_g.jsonl','athena_mbpp_h.jsonl','athena_mbpp_w1.jsonl','athena_mbpp_w2.jsonl'):
    try:
        for l in open(f):
            if not l.strip(): continue
            r=json.loads(l)
            if 'T' in r and 'accept' in r: good.setdefault(r['idx'],set()).add(r['arm'])
    except FileNotFoundError: pass
print(sum(1 for i in range(947) if len(good.get(i,set()))==2))"; }
cov_kimi() { python3 -c "
import json
good={}
for l in open('kimi_mbpp.jsonl'):
    if not l.strip(): continue
    r=json.loads(l)
    if r.get('model')=='kimi-k28-hs' and 'T' in r and 'accept' in r: good.setdefault(r['idx'],set()).add(r['arm'])
print(sum(1 for i in range(947) if len(good.get(i,set()))==2))"; }
last_x=0; stall=0; rebooted=0
while true; do
  sleep 600
  A=$(cov_athena); K=$(cov_kimi); X=$(cat athena_mbpp_x*.jsonl 2>/dev/null | wc -l)
  echo "$(date '+%F %T') status: athena=$A/947 kimi=$K/947 xrecs=$X" >> overnight.log
  if [ "$X" = "$last_x" ]; then stall=$((stall+1)); else stall=0; fi
  last_x=$X
  # completion handling
  if [ "$A" -ge 947 ] && [ ! -f .athena_done ]; then
    touch .athena_done
    echo "$(date '+%F %T') ATHENA COMPLETE — refreshing table" >> overnight.log
    python3 final_table.py >> final_table_run.log 2>&1
    git --git-dir=/ARCHIVE/GIT_REPOS/selfcorr-bench.git --work-tree=$PWD add -A
    git --git-dir=/ARCHIVE/GIT_REPOS/selfcorr-bench.git --work-tree=$PWD commit -q -m "overnight: athena sweep complete ($(date '+%F %T'))" || true
  fi
  if [ "$K" -ge 947 ] && [ ! -f .kimi_done ]; then
    touch .kimi_done
    echo "$(date '+%F %T') KIMI COMPLETE — refreshing table" >> overnight.log
    python3 final_table.py >> final_table_run.log 2>&1
    git --git-dir=/ARCHIVE/GIT_REPOS/selfcorr-bench.git --work-tree=$PWD add -A
    git --git-dir=/ARCHIVE/GIT_REPOS/selfcorr-bench.git --work-tree=$PWD commit -q -m "overnight: kimi sweep complete ($(date '+%F %T'))" || true
  fi
  [ "$A" -ge 947 ] && [ "$K" -ge 947 ] && { echo "$(date '+%F %T') ALL SWEEPS COMPLETE" >> overnight.log; break; }
  # athena healing (only if incomplete)
  if [ "$A" -lt 947 ]; then
    if [ $stall -ge 2 ]; then
      echo "$(date '+%F %T') STALL ($stall cycles) — healing athena stack" >> overnight.log
      stall=0
      kill -9 $(pgrep -f "[a]thena_master.sh") 2>/dev/null
      for p in $(pgrep -f "[a]thena_x[0-9].sh"); do kill -9 $p 2>/dev/null; done
      for p in $(pgrep -f "[h]arness.py.*athena-flash"); do kill -9 $p 2>/dev/null; done
      if ping -c1 -W2 $ATHENA > /dev/null 2>&1; then
        timeout 30 ssh -o BatchMode=yes -o ConnectTimeout=8 athena 'sudo -n systemctl restart flash-next-gguf.service' 2>/dev/null
        sleep 240
        if gen_ok; then
          echo "$(date '+%F %T') generation verified — relaunching master" >> overnight.log
        else
          if [ $rebooted -eq 0 ]; then
            echo "$(date '+%F %T') gen still failing — REBOOTING BOX" >> overnight.log
            rebooted=1
            timeout 30 ssh -o BatchMode=yes -o ConnectTimeout=8 athena 'sudo -n reboot' 2>/dev/null
            sleep 180
            for i in $(seq 1 40); do ping -c1 -W2 $ATHENA >/dev/null 2>&1 && break; sleep 15; done
            sleep 60
            for i in $(seq 1 60); do gen_ok && break; sleep 30; done
            gen_ok && echo "$(date '+%F %T') post-reboot gen verified" >> overnight.log || { echo "$(date '+%F %T') post-reboot gen STILL failing — manual help needed" >> overnight.log; }
          else
            echo "$(date '+%F %T') already rebooted once — gen still failing" >> overnight.log
          fi
        fi
      else
        echo "$(date '+%F %T') box unreachable" >> overnight.log
      fi
      setsid nohup bash athena_master.sh >> athena_master.out 2>&1 < /dev/null &
    fi
    if ! pgrep -f "[a]thena_master.sh" > /dev/null && [ ! -f .athena_done ]; then
      if gen_ok; then
        echo "$(date '+%F %T') master not running — relaunching" >> overnight.log
        setsid nohup bash athena_master.sh >> athena_master.out 2>&1 < /dev/null &
      fi
    fi
  fi
done
