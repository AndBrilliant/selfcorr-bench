#!/bin/bash
cd /home/Drew/selfcorr-bench
python3 harness.py --start 707 --end 811 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_mbpp_w2.jsonl --cap 10 >> athena_mbpp_w2.log 2>&1
python3 harness.py --start 819 --end 947 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_mbpp_w2.jsonl --cap 10 >> athena_mbpp_w2.log 2>&1
echo athena_mbpp_w2_DONE
