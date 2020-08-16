#!/usr/bin/env bash
set -e

echo "=== Running Etch EDA Unified Verification ==="

# 1. Typography verification
echo "[1/3] Verifying typography (zero em dashes)..."
python3 verify_no_em_dashes.py

# 2. Master test runner
echo "[2/3] Running 21 test suites..."
./node_modules/.bin/coffee tests/runner.coffee

# 3. CLI Demo Verification
echo "[3/3] Testing CLI demo board synthesis..."
./bin/etch demo > /dev/null

echo "=== All Verification Passes Succeeded Smoothly ==="
