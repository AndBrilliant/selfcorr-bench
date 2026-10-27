#!/bin/bash
cd /home/Drew/selfcorr-bench
set -ex
python3 harness.py --start 72 --end 73 --bench mbpp --model qwen38-flash --arms steelman --out qwen38flash_mbpp.jsonl --cap 10 >> qwen38flash_mbpp.log 2>&1
python3 harness.py --start 207 --end 208 --bench mbpp --model qwen38-flash --arms selfcheck --out qwen38flash_mbpp.jsonl --cap 10 >> qwen38flash_mbpp.log 2>&1
python3 harness.py --start 725 --end 726 --bench mbpp --model qwen38-flash --arms selfcheck --out qwen38flash_mbpp.jsonl --cap 10 >> qwen38flash_mbpp.log 2>&1
python3 harness.py --start 726 --end 728 --bench mbpp --model qwen38-flash --arms selfcheck,steelman --out qwen38flash_mbpp.jsonl --cap 10 >> qwen38flash_mbpp.log 2>&1
python3 harness.py --start 728 --end 729 --bench mbpp --model qwen38-flash --arms selfcheck --out qwen38flash_mbpp.jsonl --cap 10 >> qwen38flash_mbpp.log 2>&1
python3 harness.py --start 729 --end 730 --bench mbpp --model qwen38-flash --arms selfcheck,steelman --out qwen38flash_mbpp.jsonl --cap 10 >> qwen38flash_mbpp.log 2>&1
python3 harness.py --start 768 --end 769 --bench mbpp --model qwen38-flash --arms steelman --out qwen38flash_mbpp.jsonl --cap 10 >> qwen38flash_mbpp.log 2>&1
python3 harness.py --start 783 --end 784 --bench mbpp --model qwen38-flash --arms steelman --out qwen38flash_mbpp.jsonl --cap 10 >> qwen38flash_mbpp.log 2>&1
python3 harness.py --start 809 --end 810 --bench mbpp --model qwen38-flash --arms steelman --out qwen38flash_mbpp.jsonl --cap 10 >> qwen38flash_mbpp.log 2>&1
python3 harness.py --start 810 --end 811 --bench mbpp --model qwen38-flash --arms selfcheck,steelman --out qwen38flash_mbpp.jsonl --cap 10 >> qwen38flash_mbpp.log 2>&1
python3 harness.py --start 811 --end 812 --bench mbpp --model qwen38-flash --arms selfcheck --out qwen38flash_mbpp.jsonl --cap 10 >> qwen38flash_mbpp.log 2>&1
python3 harness.py --start 812 --end 817 --bench mbpp --model qwen38-flash --arms selfcheck,steelman --out qwen38flash_mbpp.jsonl --cap 10 >> qwen38flash_mbpp.log 2>&1
python3 harness.py --start 821 --end 822 --bench mbpp --model qwen38-flash --arms selfcheck --out qwen38flash_mbpp.jsonl --cap 10 >> qwen38flash_mbpp.log 2>&1
echo GAPFILL_QWEN_DONE
