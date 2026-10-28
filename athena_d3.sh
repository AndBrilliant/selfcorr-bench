#!/bin/bash
cd /home/Drew/selfcorr-bench
python3 harness.py --start 775 --end 811 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_d3.jsonl --cap 10 >> athena_d3.log 2>&1
python3 harness.py --start 819 --end 880 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_d3.jsonl --cap 10 >> athena_d3.log 2>&1
echo athena_d3_DONE
