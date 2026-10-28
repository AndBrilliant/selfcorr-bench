#!/bin/bash
cd /home/Drew/selfcorr-bench
python3 harness.py --start 856 --end 947 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_c4.jsonl --cap 10 >> athena_c4.log 2>&1
echo athena_c4_DONE
