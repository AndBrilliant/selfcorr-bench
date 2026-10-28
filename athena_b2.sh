#!/bin/bash
cd /home/Drew/selfcorr-bench
python3 harness.py --start 479 --end 499 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_b2.jsonl --cap 10 >> athena_b2.log 2>&1
python3 harness.py --start 738 --end 739 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_b2.jsonl --cap 10 >> athena_b2.log 2>&1
python3 harness.py --start 744 --end 774 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_b2.jsonl --cap 10 >> athena_b2.log 2>&1
python3 harness.py --start 775 --end 811 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_b2.jsonl --cap 10 >> athena_b2.log 2>&1
python3 harness.py --start 819 --end 947 --bench mbpp --model athena-flash --arms selfcheck,steelman --out athena_b2.jsonl --cap 10 >> athena_b2.log 2>&1
echo B2_DONE
