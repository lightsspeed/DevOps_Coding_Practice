#!/bin/bash

# Simple System Health Check
# Usage: ./health_check.sh [service1] [service2] ...

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Print status with color
status() {
    case $1 in
        OK) echo -e "${GREEN}✓${NC} $2" ;;
        WARN) echo -e "${YELLOW}⚠${NC} $2" ;;
        FAIL) echo -e "${RED}✗${NC} $2" ;;
    esac
}

echo "=== System Health Check ==="

# CPU Usage
cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
if (( $(echo "$cpu > 80" | bc -l) )); then
    status FAIL "CPU: ${cpu}% (High)"
elif (( $(echo "$cpu > 60" | bc -l) )); then
    status WARN "CPU: ${cpu}% (Moderate)"
else
    status OK "CPU: ${cpu}%"
fi

# Memory Usage  
mem=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}')
if [ "$mem" -gt 85 ]; then
    status FAIL "Memory: ${mem}% (High)"
elif [ "$mem" -gt 70 ]; then
    status WARN "Memory: ${mem}% (Moderate)"
else
    status OK "Memory: ${mem}%"
fi

# Disk Usage
disk=$(df / | tail -1 | awk '{print $5}' | cut -d'%' -f1)
if [ "$disk" -gt 90 ]; then
    status FAIL "Disk: ${disk}% (Critical)"
elif [ "$disk" -gt 75 ]; then
    status WARN "Disk: ${disk}% (Low space)"
else
    status OK "Disk: ${disk}%"
fi

# Network
if ping -c1 8.8.8.8 &>/dev/null; then
    status OK "Network: Connected"
else
    status FAIL "Network: No connectivity"
fi

# Services
for service in "$@"; do
    if systemctl is-active --quiet "$service"; then
        status OK "Service: $service running"
    else
        status FAIL "Service: $service not running"
    fi
done

echo "=== Check completed ==="