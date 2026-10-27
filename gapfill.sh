#!/bin/bash
cd /home/Drew/selfcorr-bench
set -x
# dsv4flash: idx5 selfcheck+steelman, idx4 steelman
python3 harness.py --start 5 --end 6 --bench mbpp --model ds-v4-flash --arms selfcheck,steelman --out dsv4flash_mbpp.jsonl --cap 10 >> dsv4flash_mbpp.log 2>&1
python3 harness.py --start 4 --end 5 --bench mbpp --model ds-v4-flash --arms steelman --out dsv4flash_mbpp.jsonl --cap 10 >> dsv4flash_mbpp.log 2>&1
# glm: idx205 steelman
python3 harness.py --start 205 --end 206 --bench mbpp --model glm-5.3-flash --arms steelman --out glm53_mbpp.jsonl --cap 10 >> glm53_mbpp.log 2>&1
# qwen clusters
python3 harness.py --start 72  --end 73  --bench mbpp --model qwen38-flash --arms steelman --out qwen38flash_mbpp.jsonl --cap 10 >> qwen38flash_mbpp.log 2>&1
python3 harness.py --start 207 --end 208 --bench mbpp --model qwen38-flash --arms selfcheck --out qwen38flash_mbpp.jsonl --cap 10 >> qwen38flash_mbpp.log 2>&1
python3 harness.py --start 725 --end 730 --bench mbpp --model qwen38-flash --arms selfcheck,steelman --out qwen38flash_mbpp.jsonl --cap 10 >> qwen38flash_mbpp.log 2>&1
python3 harness.py --start 768 --end 769 --bench mbpp --model qwen38-flash --arms steelman --out qwen38flash_mbpp.jsonl --cap 10 >> qwen38flash_mbpp.log 2>&1
python3 harness.py --start 783 --end 784 --bench mbpp --model qwen38-flash --arms steelman --out qwen38flash_mbpp.jsonl --cap 10 >> qwen38flash_mbpp.log 2>&1
python3 harness.py --start 809 --end 817 --bench mbpp --model qwen38-flash --arms selfcheck,steelman --out qwen38flash_mbpp.jsonl --cap 10 >> qwen38flash_mbpp.log 2>&1
python3 harness.py --start 821 --end 822 --bench mbpp --model qwen38-flash --arms selfcheck --out qwen38flash_mbpp.jsonl --cap 10 >> qwen38flash_mbpp.log 2>&1
echo GAPFILL_DONE
