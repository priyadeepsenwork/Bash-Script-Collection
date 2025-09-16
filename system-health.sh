#!/bin/bash

#       Real-Time System Health Monitoring Script

# This script reports on:
# - CPU usage
# - Memory usage
# - Disk Space Usage
# - Provides alert if disk space is below threshold


#       Configuration
DISK_USAGE_THRESHOLD=80
# value in percentage

#       Real time monitoring
REFRESH_INTERVAL=1


#       Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'  # Bold
NC='\033[0m'    # No Color


#       --- TERMINAL CONTROLS ---
CLEAR_SCREEN='\033[2J'
HOME_CURSOR='\033[H'
HIDE_CURSOR='\033[?25l' # FIXED: Was '?251', changed to '?25l' (lowercase L)
SHOW_CURSOR='\033[?25h'

#       --- State Variables ---
CURRENT_VIEW=0  # 0: Processes, 1: Disk
PREV_IDLE=0
PREV_TOTAL=0

#       --- Initialize & Restore Terminal ---
init_terminal() {
        echo -ne "${HIDE_CURSOR}${CLEAR_SCREEN}${HOME_CURSOR}"
        stty -echo cbreak
}

restore_terminal() {
        stty echo -cbreak
        echo -ne "${SHOW_CURSOR}"
        clear
}


#       --- HEADER & FOOTER ---
draw_header() {
        echo -e "${HOME_CURSOR}${BLUE}${BOLD}"
        echo "╔══════════════════════════════════════════╗"
        echo "║          Interactive System Monitor      ║"
        echo "╠══════════════════════════════════════════╣" # Style fix for corner
        echo "║ Commands: [q]uit | [n]ext view | [p]ause ║"
        echo "╚══════════════════════════════════════════╝"
        echo -e "${NC}" # Reset color after header
}


#       -- Script Data Fetching and Display Functions ---


# --- Robust CPU usage calculation by reading /proc/stat ---
get_cpu_usage() {
        CPU_LINE=$(grep "cpu " /proc/stat) # Added space to match only the summary line
        USER=$(echo "$CPU_LINE" | awk '{print $2}')
        NICE=$(echo "$CPU_LINE" | awk '{print $3}')
        SYSTEM=$(echo "$CPU_LINE" | awk '{print $4}')
        IDLE=$(echo "$CPU_LINE" | awk '{print $5}')
        IOWAIT=$(echo "$CPU_LINE" | awk '{print $6}')
        IRQ=$(echo "$CPU_LINE" | awk '{print $7}')
        SOFTIRQ=$(echo "$CPU_LINE" | awk '{print $8}')

        TOTAL_IDLE=$((IDLE + IOWAIT))
        NON_IDLE=$((USER + NICE + SYSTEM + IRQ + SOFTIRQ))
        TOTAL=$((TOTAL_IDLE + NON_IDLE))

        TOTAL_DIFF=$((TOTAL - PREV_TOTAL))
        IDLE_DIFF=$((TOTAL_IDLE - PREV_IDLE))

        if [ "$TOTAL_DIFF" -eq 0 ]; then
                CPU_PERCENTAGE=0
        else
                CPU_PERCENTAGE=$((100 * (TOTAL_DIFF - IDLE_DIFF) / TOTAL_DIFF))
        fi

        PREV_TOTAL=$TOTAL
        PREV_IDLE=$TOTAL_IDLE

        echo $CPU_PERCENTAGE
}


# Display CPU Usage
display_cpu_usage() {
        echo -e "${YELLOW}${BOLD}CPU Usage:${NC}"
        local CPU_NUM
        CPU_NUM=$(get_cpu_usage)

        local BAR_LENGTH=50
        local FILLED_LENGTH=$((CPU_NUM * BAR_LENGTH / 100))
        local BAR
        BAR=$(printf "%*s" "$FILLED_LENGTH" | tr ' ' '#')
        local EMPTY
        EMPTY=$(printf "%*s" $((BAR_LENGTH - FILLED_LENGTH)) | tr ' ' '.')
        local BAR_COLOR

        if [ "$CPU_NUM" -gt 80 ]; then
                BAR_COLOR=$RED
        elif [ "$CPU_NUM" -gt 50 ]; then
                BAR_COLOR=$YELLOW
        else
                BAR_COLOR=$GREEN
        fi

        echo -e "CPU: [${BAR_COLOR}${BAR}${NC}${EMPTY}] ${CPU_NUM}%"
        echo ""
}

#       ---Advanced Memory Usage Calculation by reading /proc/meminfo---
get_memory_usage(){
        local MEM_INFO
        MEM_INFO=$(grep -E 'MemTotal|MemAvailable' /proc/meminfo)

        local TOTAL_MEM AVAIL_MEM
        TOTAL_MEM=$(echo "$MEM_INFO" | grep MemTotal | awk '{print $2}')
        AVAIL_MEM=$(echo "$MEM_INFO" | grep MemAvailable | awk '{print $2}')

        local USED_MEM=$((TOTAL_MEM - AVAIL_MEM))
        local MEM_PERCENTAGE=$((100 * USED_MEM / TOTAL_MEM))
        local USED_MB=$((USED_MEM / 1024))
        local TOTAL_MB=$((TOTAL_MEM / 1024))

        echo "$MEM_PERCENTAGE $USED_MB $TOTAL_MB"
}

# Display Memory Usage Function
display_memory_usage() {
        local USAGE_DATA
        USAGE_DATA=$(get_memory_usage)

        local MEM_PERCENTAGE USED_MB TOTAL_MB
        read -r MEM_PERCENTAGE USED_MB TOTAL_MB <<< "$USAGE_DATA"

        local BAR_LENGTH=50
        local FILLED_LENGTH=$((MEM_PERCENTAGE * BAR_LENGTH / 100))
        local BAR
        BAR=$(printf "%*s" "$FILLED_LENGTH" | tr ' ' '#')
        local EMPTY
        EMPTY=$(printf "%*s" $((BAR_LENGTH - FILLED_LENGTH)) | tr ' ' '.')
        local BAR_COLOR

        if [ "$MEM_PERCENTAGE" -gt 80 ]; then
                BAR_COLOR=$RED
        elif [ "$MEM_PERCENTAGE" -gt 50 ]; then
                BAR_COLOR=$YELLOW
        else
                BAR_COLOR=$GREEN
        fi

        echo -e "${YELLOW}${BOLD}Memory Usage:${NC}"
        echo -e "RAM: [${BAR_COLOR}${BAR}${NC}${EMPTY}] ${MEM_PERCENTAGE}% (${USED_MB}MB / ${TOTAL_MB}MB used)"
        echo ""
}

#       --- Displaying Top Processes in System
display_top_processes() {
        echo -e "${YELLOW}${BOLD}Top 5 Processes (by CPU):${NC}"
        echo -e "${BOLD}COMMAND                 %CPU   %MEM${NC}"
        ps -eo comm,%cpu,%mem --sort=-%cpu | head -n 6 | tail -n 5 | awk '{printf "%-20s %5s%% %5s%%\n", $1, $2, $3}'
        echo "" # Added for spacing
}

#       --- Display Disk usage ---
display_disk_usage() {
        echo -e "${YELLOW}${BOLD}Disk Usage (threshold ${DISK_USAGE_THRESHOLD}%):${NC}"
        echo -e "${BOLD}Filesystem              Size   Used  Avail  Use%${NC}"
        # FIXED: Changed -V to -v for portability.
        # IMPROVEMENT: Simplified awk logic to convert usage percentage to a number.
        df -hP | grep -vE 'tmpfs|devtmpfs|Filesystem' | awk -v threshold="$DISK_USAGE_THRESHOLD" -v red="$RED" -v nc="$NC" '{
                usage = int($5); # Use int() to get number from "80%" -> 80
                if (usage > threshold) {
                        printf "%-22s %5s %6s %6s  %s%s%s\n", $1, $2, $3, $4, red, $5, nc;
                } else {
                        printf "%-22s %5s %6s %6s  %s\n", $1, $2, $3, $4, $5;
                }
        }'
        echo "" # Added for spacing
}


#       --- Main Display and Input handling function ---
display_all() {
        echo -ne "${HOME_CURSOR}"
        draw_header

        echo -e "${YELLOW}${BOLD}System Information:${NC}"
        echo "Hostname: $(hostname)"
        echo "Uptime:   $(uptime -p)"
        echo ""

        display_cpu_usage
        display_memory_usage

        case $CURRENT_VIEW in
                0) display_top_processes ;;
                1) display_disk_usage ;;
        esac
}

handle_input() {
        read -t "$REFRESH_INTERVAL" -n 1 key # FIXED: Used variable instead of hardcoded 0.5
        case $key in
                q|Q)
                        return 1 ;;
                p|P)
                        echo -e "\n${YELLOW} Paused - Press any key to continue...${NC}"
                        read -n 1 -s # -s hides the keypress
                        ;;
                n|N)
                        CURRENT_VIEW=$(((CURRENT_VIEW + 1) % 2))
                        ;;
        esac
        return 0
}


#       --- Main Execution Code
main() {
        trap 'restore_terminal' EXIT INT TERM
        init_terminal

        get_cpu_usage > /dev/null

        while true; do
                display_all
                if ! handle_input; then
                        break
                fi
        done
}

#       --- Run the Main function ---
main