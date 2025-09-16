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


# --- Robust CPU usage calculation by reading /proc/stat ---

# CPU data Variables
get_cpu_usage(
	CPU_LINE=$(grep "cpu" /proc/stat)
	USER=$(echo "$CPU_LINE" | awk '{print $2}')
	NICE=$(echo "$CPU_LINE" | awk '{print $3}')
	SYSTEM=$(echo "$CPU_LINE" | awk '{print $4}')
	IDLE=$(echo "$CPU_LINE" | awk '{print $5}')
	IOWAIT=$(echo "$CPU_LINE" | awk '{print $6}')
	IRQ=$(echo "$CPU_LINE" | awk '{print $7}')
	SOFTIRQ=$(echo "$CPU_LINE" | awk '{print $8}')

	# IDLE calculation
	TOTAL_IDLE=$((IDLE + IOWAIT))
	NON_IDLE=$((USER + NICE + SYSTEM + IRQ + SOFTIRQ))
	TOTAL=$((TOTAL_IDLE + NON_IDLE))

	# Calculate difference from previous measurement
	TOTAL_DIFF=$((TOTAL - PREV_TOTAL))
	IDLE_DIFF=$((TOTAL_IDLE - PREV_IDLE))

	# Avoid division by zero on first run
	if [ "$TOTAL_DIFF" -eq 0 ]; then
		CPU_PERCENTAGE=0
	else
		CPU_PERCENTAGE=$((100 * (TOTAL_DIFF - IDLE_DIFF) / TOTAL_DIFF))
	fi

	# Save current values for next iteration
	PREV_TOTAL=$TOTAL
	PREV_IDLE=$TOTAL_IDLE

	echo $CPU_PERCENTAGE
)


# Display CPU Usage
display_cpu_usage() {
	echo -e "${YELLOW}${BOLD}CPU Usage:${NC}"
	CPU_NUM=${get_cpu_usage}

	BAR_LENGTH=50
	FILLED_LENGTH=$((CPU_NUM * BAR_LENGTH / 100))
	BAR=$(printf "%*s" $FILLED_LENGTH | tr ' ' '█')
	EMPTY=$(printf "%*s" $((BAR_LENGTH - FILLED_LENGTH)) | tr ' ' '░')

	if [ $CPU_NUM -gt 80 ]; then
		BAR_COLOR=$RED
	elif [ $CPU_NUM -gt 50 ]; then
		BAR_COLOR=$YELLOW
	else
		BAR_COLOR=$GREEN
	fi

	echo -e "CPU: [${BAR_COLOR}${BAR}${NC}${EMPTY}] ${CPU_NUM}%"
	echo ""
}

#	---Advanced Memory Usage Calculation by reading /proc/meminfo---

# Get Memory Usage Function
get_memory_usage(){
	# Read Memory info from /proc/meminfo
	local MEM_INFO
	MEM_INFO=$(grep -E 'MemTotal|MemAvailable' /proc/meminfo)

	local TOTAL_MEM AVAIL_MEM
	TOTAL_MEM=$(echo "$MEM_INFO" | grep MemTotal | awk '{print $2}')
	AVAIL_MEM=$(echo "$MEM_INFO" | grep MemAvailable | awk '{print $2}')


	# Perform calculations (all values are in KiB from /proc/meminfo)
	local USED_MEM=$((TOTAL_MEM - AVAIL_MEM))
	local MEM_PERCENTAGE=$((100 * USED_MEM / TOTAL_MEM))
	local USED_MB=$((USED_MEM / 1024))
	local TOTAL_MB=$((TOTAL_MEM / 1024))


	# Output the calculated values for the display function to consume
	echo "$MEM_PERCENTAGE $USED_MB $TOTAL_MB"
}

# Display Memory Usage Function
display_memory_usage() {
	# Call the get function and read its output into variables
	local USAGE_DATA
	USAGE_DATA=$(get_memory_usage)

	local MEM_PERCENTAGE USED_MB TOTAL_MB
	read -r MEM_PERCENTAGE USED_MB TOTAL_MB <<< "$USAGE_DATA"


	# --- BAR drawing logic
	local BAR_LENGTH=50
	local FILLED_LENGTH=$((MEM_PERCENTAGE * BAR_LENGTH / 100))
	local BAR
	BAR=$(printf "%*s" $FILLED_LENGTH | tr ' ' '█')
	local EMPTY
	EMPTY=$(printf "%*s" $((BAR_LENGTH - FILLED_LENGTH)) | tr ' ' '░')

	# --- Color Selection logic
	local BAR_COLOR
	if [ "$MEM_PERCENTAGE" -gt 80 ]; then
		BAR_COLOR=$RED
	elif [ "$MEM_PERCENTAGE" -gt 50 ]; then
		BAR_COLOR=$YELLOW
	else
		BAR_COLOR=$GREEN
	fi


	# --- Final Output
	echo -e "${YELLOW}${BOLD}Memory Usage (Available):${NC}"
	echo -e "RAM : [${BAR_COLOR}${BAR}${NC}${EMPTY}] ${MEM_PERCENTAGE}% (${USED_MB}MB / ${TOTAL_MB}MB used)"
	echo ""
}



#	--- Displaying Top Processes in System
display_top_processes() {
	echo -e "${YELLOW}${BOLD}Top 5 Processes (by CPU):${NC}"
	echo -e "${BOLD}COMMAND			%CPU  %MEM${NC}"
	# Using ps with POSIX-compliant flags for better portability within Linux
	ps -eo comm,%cpu,%mem --sort=-%cpu | head -6 | tail -5 | awk '{printf "%-20s %5s%% %5s%%\n", $1, $2, $3}'
}


#	--- Display Disk usage ---
display_disk_usage() {
	echo -e "${YELLOW}${BOLD}Disk Usage (threshold ${DISK_USAGE_THRESHOLD}%):${NC}"
	echo -e "${BOLD}Filesystem		Size   Used   Avail  Use%${NC}"
	# Use -P for POSIX format to prevent line wrapping, skip tmpfs/devtmpfs
	df -hP | grep -vE 'tmpfs|devtmpfs|Filesystem' | awk -V threshold="$DISK_USAGE_THRESHOLD" -v red="$RED" -v nc="$NC" '{
		usage = substr($5, 1, length($5)-1);
		if (usage > threshold) {
			printf "%-22s %5s %6s %7s  %s%s%s\n", $1, $2, $3, $4, red, $5, nc;
		} else {
			printf "%-22s %5s %6s %7s  %s\n", $1, $2, $3, $4, $5;
		}
	}'
}


#	--- Main Display and Input handling function ---
display_all() {
	echo -ne "${HOME_CURSOR}"
	draw_header

	# --- Static Info ---
	echo -e "${YELLOW}${BOLD}System Information:${NC}"
	echo "Hostname: ${hostname}"
	echo "Uptime: $(uptime -p)"
	echo ""

	# --- View-dependent Info ---
	case $CURRENT_VIEW in
		0) display_top_processes ;;
		1) display_disk_usage ;;
	esac
}

handle_input() {
	read -t 0.5 -n 1 key
	case $key in
		q|Q)
			return 1 ;;
		p|P)
			echo -e "\n${YELLOW} Paused - Press any key to continue...${NC}"
			read -n 1
			;;
		n|N)
			CURRENT_VIEW=$(((CURRENT_VIEW + 1) % 2)) #Cycle through 2 views
			;;
	esac
	return 0
}


#	--- Main Execution Code
main() {
	trap 'restore_terminal' EXIT INT TERM
	init_terminal

	# Initial run to populate PREV values for CPU calc
	get_cpu_usage > /dev/null

	while true; do
		display_all
		if ! handle_input; then
			break
		fi
	done
}



#	--- Run the Main function ---
main







