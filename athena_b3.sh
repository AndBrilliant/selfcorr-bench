#!/bin/bash
cd /home/Drew/selfcorr-bench
python3 harness.py --start 774 --end 811 --bench mbpp --model athena-flash --arms selfcheck,steelman --sleep 15 --out athena_b3.jsonl --cap 10 >> athena_b3.log 2>&1
python3 harness.py --start 819 --end 947 --bench mbpp --model athena-flash --arms selfcheck,steelman --sleep 15 --out athena_b3.jsonl --cap 10 >> athena_b3.log 2>&1
echo athena_b3_DONE
