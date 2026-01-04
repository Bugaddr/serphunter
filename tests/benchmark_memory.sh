#!/bin/bash

# tests/benchmark_memory.sh
# Checks memory usage during execution

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

MEMORY_LOG=$(mktemp /tmp/serphunter_memlog.XXXXXX)

echo "Monitoring Memory Usage..."
bash "$REPO_DIR/serphunter.sh" -d google.com -p > /dev/null 2>&1 &
pid=$!

while kill -0 $pid 2>/dev/null; do
    ps -o rss= -p $pid >> "$MEMORY_LOG" 2>/dev/null
    sleep 0.1
done

if [[ -s "$MEMORY_LOG" ]]; then
    peak=$(sort -nr "$MEMORY_LOG" | head -n1)
    echo "Peak Memory Usage: ${peak}KB"
else
    echo "Peak Memory Usage: N/A (process completed too quickly)"
fi

rm -f "$MEMORY_LOG"
