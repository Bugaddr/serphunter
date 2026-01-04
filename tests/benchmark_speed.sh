#!/bin/bash

# tests/benchmark_speed.sh
# Benchmarks execution time between serial and parallel modes

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

target="example.com"
echo "Benchmarking Serial Mode..."
start=$(date +%s%N)
bash "$REPO_DIR/serphunter.sh" -d $target > /dev/null 2>&1
end=$(date +%s%N)
serial_time=$(( (end - start) / 1000000 ))

echo "Benchmarking Parallel Mode..."
start=$(date +%s%N)
bash "$REPO_DIR/serphunter.sh" -d $target -p > /dev/null 2>&1
end=$(date +%s%N)
parallel_time=$(( (end - start) / 1000000 ))

echo "Serial: ${serial_time}ms"
echo "Parallel: ${parallel_time}ms"

if [[ $serial_time -gt 0 ]]; then
    improvement=$(echo "scale=2; ($serial_time - $parallel_time) / $serial_time * 100" | bc)
    echo "Improvement: ${improvement}%"
else
    echo "Improvement: N/A (execution too fast to measure)"
fi
