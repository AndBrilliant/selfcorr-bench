#!/bin/bash
cd /home/Drew/selfcorr-bench
python3 harness.py --start 364 --end 416 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_x2.jsonl --cap 10 >> athena_x2.log 2>&1
echo athena_x2_DONE
