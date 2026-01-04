#!/bin/bash

# tests/run_benchmarks.sh
# Aggregates results from all benchmark scripts

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Running all benchmarks..."
echo "----------------------------------------"

bash "$SCRIPT_DIR/benchmark_speed.sh"
echo "----------------------------------------"

bash "$SCRIPT_DIR/benchmark_load.sh"
echo "----------------------------------------"

bash "$SCRIPT_DIR/benchmark_memory.sh"
echo "----------------------------------------"

echo "All 4 benchmark scenarios completed."
