#!/bin/bash
cd /home/Drew/selfcorr-bench
python3 harness.py --start 251 --end 356 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_mbpp_w1.jsonl --cap 10 >> athena_mbpp_w1.log 2>&1
python3 harness.py --start 364 --end 468 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_mbpp_w1.jsonl --cap 10 >> athena_mbpp_w1.log 2>&1
python3 harness.py --start 477 --end 499 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_mbpp_w1.jsonl --cap 10 >> athena_mbpp_w1.log 2>&1
echo athena_mbpp_w1_DONE
