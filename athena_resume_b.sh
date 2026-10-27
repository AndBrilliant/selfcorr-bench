#!/bin/bash
cd /home/Drew/selfcorr-bench
python3 harness.py --start 499 --end 505 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_mbpp_s1.jsonl --cap 10 >> athena_mbpp_s1.log 2>&1
python3 harness.py --start 676 --end 947 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_mbpp_s1.jsonl --cap 10 >> athena_mbpp_s1.log 2>&1
echo ATHENA_B_DONE
