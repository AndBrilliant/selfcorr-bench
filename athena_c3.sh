#!/bin/bash
cd /home/Drew/selfcorr-bench
python3 harness.py --start 744 --end 811 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_c3.jsonl --cap 10 >> athena_c3.log 2>&1
python3 harness.py --start 819 --end 856 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_c3.jsonl --cap 10 >> athena_c3.log 2>&1
echo athena_c3_DONE
