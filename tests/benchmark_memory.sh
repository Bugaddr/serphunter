#!/bin/bash

# tests/benchmark_memory.sh
# Checks memory usage during execution

echo "Monitoring Memory Usage..."
../serphunter.sh -d google.com -p > /dev/null 2>&1 &
pid=$!

while kill -0 $pid 2>/dev/null; do
    ps -o rss= -p $pid >> memory.log 2>/dev/null
    sleep 0.1
done

peak=$(sort -nr memory.log | head -n1)
echo "Peak Memory Usage: ${peak}KB"
rm memory.log
