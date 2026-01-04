#!/bin/bash

# tests/test_basic.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Running basic tests..."

if [[ -x "$REPO_DIR/serphunter.sh" ]]; then
    echo "[PASS] Main script is executable"
else
    echo "[FAIL] Main script is not executable"
    exit 1
fi

if bash "$REPO_DIR/serphunter.sh" -h 2>&1 | grep -q "SerphunterRecon"; then
    echo "[PASS] Help message works"
else
    echo "[FAIL] Help message failed"
    exit 1
fi

echo "All tests passed."
