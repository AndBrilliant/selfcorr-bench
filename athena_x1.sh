#!/bin/bash
cd /home/Drew/selfcorr-bench
python3 harness.py --start 288 --end 356 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_x1.jsonl --cap 10 >> athena_x1.log 2>&1
echo athena_x1_DONE
