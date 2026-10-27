#!/bin/bash
cd /home/Drew/selfcorr-bench
python3 harness.py --start 477 --end 499 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_x4.jsonl --cap 10 >> athena_x4.log 2>&1
python3 harness.py --start 738 --end 739 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_x4.jsonl --cap 10 >> athena_x4.log 2>&1
python3 harness.py --start 744 --end 800 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_x4.jsonl --cap 10 >> athena_x4.log 2>&1
echo athena_x4_DONE
