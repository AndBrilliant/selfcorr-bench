#!/bin/bash
cd /home/Drew/selfcorr-bench
python3 harness.py --start 416 --end 468 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_x3.jsonl --cap 10 >> athena_x3.log 2>&1
echo athena_x3_DONE
