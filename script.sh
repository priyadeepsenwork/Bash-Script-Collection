#!/bin/bash

#	System health monitoring script

# This script reports on:
# - CPU usage
# - Memory usage
# - Disk Space Usage
# - Provides altert if disk space is below threshold


#	Configuration
DISK_USAGE_THRESHOLD=80
# value in percentage

#	Real time monitoring
REFRESH_INTERVAL=1


#	Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color


#	 Script Body
echo "================================================="
echo "          System Health Report"
echo "================================================="
echo "Report generated on: $(date)"
echo ""


#	1. CPU usage
# Using 'top' in batch mode to get a snapshot, then 'awk' to calculate usage.
# Grabs the 'us'(user) and 'sy'(system) percentages.
echo -e "${YELLOW}--- CPU Usage ---${NC}"
CPU_USAGE=$(top -b -n 1 | grep "Cpu(s)" | awk '{print $2 + $4}')
echo "Current CPU usage: $CPU_USAGE"
echo ""


#	2. Memory usage
# Using 'free -m' to get memory details in Megabytes
echo -e "${YELLOW}--- Memory Usage ---${NC}"

# The 'Mem' line contains the main memory stats.
MEM_INFO=$(free -m | grep Mem)
TOTAL_MEM=$(echo $MEM_INFO | awk '{print $2}')
USED_MEM=$(echo $MEM_INFO | awk '{print $3}')
FREE_MEM=$(echo $MEM_INFO | awk '{print $4}')
MEM_PERCENTAGE=$((100 *USED_MEM / $TOTAL_MEM))

# Printing the variables to show memory status
echo "Total Memory: ${TOTAL_MEM}MB"
echo "Used Memory : ${USED_MEM}MB"
echo "Free Memory : ${FREE_MEM}MB"
echo "Memory Usage Percentage: ${MEM_PERCENTAGE}%"
echo ""







