#!/bin/bash

# tests/benchmark_speed.sh
# Benchmarks execution time between serial and parallel modes

target="example.com"
echo "Benchmarking Serial Mode..."
start=$(date +%s)
../serphunter.sh -d $target > /dev/null 2>&1
end=$(date +%s)
serial_time=$((end - start))

echo "Benchmarking Parallel Mode..."
start=$(date +%s)
../serphunter.sh -d $target -p > /dev/null 2>&1
end=$(date +%s)
parallel_time=$((end - start))

echo "Serial: ${serial_time}s"
echo "Parallel: ${parallel_time}s"
improvement=$(echo "scale=2; ($serial_time - $parallel_time) / $serial_time * 100" | bc)
echo "Improvement: $improvement%"
