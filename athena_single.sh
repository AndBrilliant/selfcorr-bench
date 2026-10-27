#!/bin/bash
cd /home/Drew/selfcorr-bench
python3 harness.py --start 288 --end 356 --bench mbpp --model athena-flash --arms selfcheck,steelman --sleep 20 --out athena_single.jsonl --cap 10 >> athena_single.log 2>&1
python3 harness.py --start 364 --end 468 --bench mbpp --model athena-flash --arms selfcheck,steelman --sleep 20 --out athena_single.jsonl --cap 10 >> athena_single.log 2>&1
python3 harness.py --start 477 --end 499 --bench mbpp --model athena-flash --arms selfcheck,steelman --sleep 20 --out athena_single.jsonl --cap 10 >> athena_single.log 2>&1
python3 harness.py --start 738 --end 739 --bench mbpp --model athena-flash --arms selfcheck,steelman --sleep 20 --out athena_single.jsonl --cap 10 >> athena_single.log 2>&1
python3 harness.py --start 744 --end 811 --bench mbpp --model athena-flash --arms selfcheck,steelman --sleep 20 --out athena_single.jsonl --cap 10 >> athena_single.log 2>&1
python3 harness.py --start 819 --end 947 --bench mbpp --model athena-flash --arms selfcheck,steelman --sleep 20 --out athena_single.jsonl --cap 10 >> athena_single.log 2>&1
echo ATHENA_SINGLE_DONE
