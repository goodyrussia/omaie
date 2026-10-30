#!/bin/bash
cd /root/omaie

echo "=== 1. TERMINAL ATTRIBUTES & INPUT STREAM CHECK ==="
stty -a
echo ""

echo "=== 2. CHECKING IF READ COMMAND WAITS OR FAILS ==="
# Test if a non-blocking or redirected read triggers EOF immediately
timeout 2 bash -c 'read -p "Test prompt: " ans; echo "Read input: $ans"' 2>&1 || echo "  [NOTICE] read command timed out or received EOF."
echo ""

echo "=== 3. TRACING DASHBOARD FUNCTION EXECUTION ==="
# Source the dashboard and test show_dashboard execution time/behavior
source ./menu/dashboard.sh
echo "Testing show_dashboard() single execution..."
time show_dashboard > /dev/null
echo ""

echo "=== 4. SIMULATING CASE BRANCH EVALUATION WITH INPUT '1' ==="
# Feed input '1' directly into the case logic block to see if it triggers the branch
bash -c '
source ./menu/dashboard.sh
choice="1"
echo "Testing choice variable: [$choice]"
case "$choice" in
    1|01) echo "SUCCESS: Branch 1 matched." ;;
    *) echo "FAILURE: Branch 1 did not match." ;;
esac
'
