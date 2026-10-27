#!/bin/bash
cd /home/Drew/selfcorr-bench
python3 harness.py --start 506 --end 676 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_mbpp_c.jsonl --cap 10 >> athena_mbpp_c.log 2>&1
echo ATHENA_C_DONE
