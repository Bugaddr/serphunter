#!/bin/bash

# tests/benchmark_load.sh
# Simulates load by running multiple instances

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Starting Load Test..."
for i in {1..5}; do
    bash "$REPO_DIR/serphunter.sh" -d "example$i.com" -p &
done
wait
echo "Load test complete: 5 concurrent scans finished."
