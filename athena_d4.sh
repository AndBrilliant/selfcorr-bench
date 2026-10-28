#!/bin/bash
cd /home/Drew/selfcorr-bench
python3 harness.py --start 881 --end 947 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_d4.jsonl --cap 10 >> athena_d4.log 2>&1
echo athena_d4_DONE
