#!/bin/bash
cd /home/Drew/selfcorr-bench
python3 harness.py --start 800 --end 811 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_x5.jsonl --cap 10 >> athena_x5.log 2>&1
python3 harness.py --start 819 --end 881 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_x5.jsonl --cap 10 >> athena_x5.log 2>&1
echo athena_x5_DONE
