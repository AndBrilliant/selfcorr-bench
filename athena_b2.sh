#!/bin/bash
cd /home/Drew/selfcorr-bench
python3 harness.py --start 477 --end 499 --bench mbpp --model athena-flash --arms selfcheck,steelman --sleep 15 --out athena_b2.jsonl --cap 10 >> athena_b2.log 2>&1
python3 harness.py --start 738 --end 739 --bench mbpp --model athena-flash --arms selfcheck,steelman --sleep 15 --out athena_b2.jsonl --cap 10 >> athena_b2.log 2>&1
python3 harness.py --start 744 --end 774 --bench mbpp --model athena-flash --arms selfcheck,steelman --sleep 15 --out athena_b2.jsonl --cap 10 >> athena_b2.log 2>&1
echo athena_b2_DONE
