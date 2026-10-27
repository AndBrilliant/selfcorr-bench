#!/bin/bash
cd /home/Drew/selfcorr-bench
python3 harness.py --start 30 --end 37 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_mbpp_s0.jsonl --cap 10 >> athena_mbpp_s0.log 2>&1
python3 harness.py --start 230 --end 499 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_mbpp_s0.jsonl --cap 10 >> athena_mbpp_s0.log 2>&1
echo ATHENA_A_DONE
