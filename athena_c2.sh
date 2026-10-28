#!/bin/bash
cd /home/Drew/selfcorr-bench
python3 harness.py --start 395 --end 468 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_c2.jsonl --cap 10 >> athena_c2.log 2>&1
python3 harness.py --start 479 --end 499 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_c2.jsonl --cap 10 >> athena_c2.log 2>&1
python3 harness.py --start 738 --end 739 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_c2.jsonl --cap 10 >> athena_c2.log 2>&1
echo athena_c2_DONE
