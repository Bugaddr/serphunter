#!/bin/bash

# tests/benchmark_load.sh
# Simulates load by running multiple instances

echo "Starting Load Test..."
for i in {1..5}; do
    ../serphunter.sh -d "example$i.com" -p &
done
wait
echo "Load test complete: 5 concurrent scans finished."
