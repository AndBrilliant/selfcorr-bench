#!/bin/bash
cd /home/Drew/selfcorr-bench
python3 harness.py --start 288 --end 356 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_b1.jsonl --cap 10 >> athena_b1.log 2>&1
python3 harness.py --start 364 --end 468 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_b1.jsonl --cap 10 >> athena_b1.log 2>&1
echo B1_DONE
