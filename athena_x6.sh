#!/bin/bash
cd /home/Drew/selfcorr-bench
python3 harness.py --start 881 --end 947 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_x6.jsonl --cap 10 >> athena_x6.log 2>&1
echo athena_x6_DONE
