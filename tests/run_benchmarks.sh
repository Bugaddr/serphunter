#!/bin/bash

# tests/run_benchmarks.sh
# Aggregates results from all benchmark scripts

echo "Running all benchmarks..."
echo "----------------------------------------"

./tests/benchmark_speed.sh
echo "----------------------------------------"

./tests/benchmark_load.sh
echo "----------------------------------------"

./tests/benchmark_memory.sh
echo "----------------------------------------"

echo "All 4 benchmark scenarios completed."
