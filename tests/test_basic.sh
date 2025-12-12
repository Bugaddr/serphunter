#!/bin/bash

# tests/test_basic.sh

echo "Running basic tests..."

if [[ -x "../serphunter.sh" ]]; then
    echo "[PASS] Main script is executable"
else
    echo "[FAIL] Main script is not executable"
    exit 1
fi

if ../serphunter.sh -h | grep -q "SerphunterRecon"; then
    echo "[PASS] Help message works"
else
    echo "[FAIL] Help message failed"
    exit 1
fi

echo "All tests passed."
