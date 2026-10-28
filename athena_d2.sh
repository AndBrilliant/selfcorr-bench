#!/bin/bash
cd /home/Drew/selfcorr-bench
python3 harness.py --start 479 --end 499 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_d2.jsonl --cap 10 >> athena_d2.log 2>&1
python3 harness.py --start 738 --end 739 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_d2.jsonl --cap 10 >> athena_d2.log 2>&1
python3 harness.py --start 744 --end 774 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_d2.jsonl --cap 10 >> athena_d2.log 2>&1
echo athena_d2_DONE
