#!/bin/bash

#	Real-Time ystem health monitoring script

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
BLUE='\033[0;34m'
BOLD='\033[1m'	# Bold
NC='\033[0m'	# No Color


#	--- TERMINAL CONTROLS ---
CLEAR_SCREEN='\033[2J'
HOME_CURSOR='\033[H'
HIDE_CURSOR='\033[?251'
SHOW_CURSOR='\033[?25h'

#	--- State Variables ---
CURRENT_VIEW=0	#0: Processes, 1: Disk
PREV_IDLE=0
PREV_TOTAL=0

#	--- Initialize $ Restore Terminal ---
init_terminal() {
	echo -ne "${HIDE_CURSOR}${CLEAR_SCREEN}${HOME_CURSOR}"
	stty -echo cbreak
}

restore_terminal() {
	stty echo -cbreak
	echo -ne "${SHOW_CURSOR}"
	clear
}


#	--- HEADER & FOOTER ---
draw_header() {
	echo -e "${HOME_CURSOR}${BLUE}${BOLD}"
	echo "╔══════════════════════════════════════════╗"
	echo "║	         Interative System Monitor       ║"
	echo "╠══════════════════════════════════════════╠"
	echo "║ Commands: [q]uit | [n]ext view | [p]ause ║"
	echo "╚══════════════════════════════════════════╝"
	echo ""
}
# need to add colors here


#	-- Script Data Fetching and Display Functions ---


#	Robust CPU usage calculation by reading /proc/stat


#	1. CPU usage
# Using 'top' in batch mode to get a snapshot, then 'awk' to calculate usage
# Grabs the 'us'(user) and 'sy'(system) percentages.
echo -e "${YELLOW}--- CPU Usage ---${NC}"
CPU_USAGE=$(top -b -n1 | grep "Cpu(s)" | awk '{print $2 + $4}' | sed 's/%us,//')
echo "Current CPU usage: ${CPU_USAGE}%"
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
echo ""

# Color Coding based on usage:
if [ $MEM_PERCENTAGE -gt 80 ]; then
	MEM_COLOR=$RED
elif [ $MEM_PERCENTAGE -gt 60 ]; then
	MEM_COLOR=$YELLOW
else
	MEM_COLOR=$GREEN
fi

# echo "Total Memory: ${TOTAL_MEM}MB"
echo -e "Memory Usage: ${MEM_COLOR}${MEM_PERCENTAGE}%${NC} (${USED_MEM}MB used, ${FREE_MEM}MB free)"
echo ""



#	3. Disk Usage
echo -e "${YELLOW}--- Disk Usage ---${NC}"
df -h | grep -E '^/dev' | while read output; do
	usage=$(echo $output | awk '{print $5}' | sed 's/%//')
	partition=$(echo $output | awk '{print $1}')
	if [ $usage -gt $DISK_USAGE_THRESHOLD ]; then
		echo -e "${RED}WARNING: ${partition} is ${usage}% full${NC}"
	else
		echo -r "${GREEN}${partition}: ${usage}% used${NC}"
	fi
done
echo ""


#	4. Load Average
echo -e "${YELLOW}--- Load Average ---${NC}"
LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}')
echo "Load Average: $LOAD_AVG"
echo ""



#	--- End main function ---

# Trap Ctrl+C to exit gracefully
trap 'echo -e "\n${GREEN}Monitoring stopped.${NC}"; exit 0' INT


#	Main Loop
while true; 
do
	display_stats
	sleep $REFRESH_INTERVAL
done

