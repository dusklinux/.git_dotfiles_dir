#!/bin/bash

# =============================================================================
# SYSBENCH ULTIMATE DASHBOARD (v13.2 - Fixed Input Logic)
# =============================================================================
# Fixes:
# - INPUT LOOP: Invalid menu options now prompt again instead of defaulting.
# - CTRL+C: Now immediately exits the script instead of running the test.
# - DEFAULTING: Only pressing 'Enter' triggers the default option.
# =============================================================================

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' 

# FIX: Added 'exit 1' to the trap so it actually stops the script
trap 'echo -e "\n${YELLOW}Benchmark stopped by user.${NC}"; exit 1' INT

# --- Global Config ---
ACTIVE_THREADS=$(nproc)
TASKSET_CMD=""
RunTime=10

check_deps() {
    local missing_deps=0
    for cmd in sysbench taskset lscpu awk; do
        if ! command -v $cmd &> /dev/null; then
            echo -e "${RED}Error: Required command '$cmd' is missing.${NC}"
            missing_deps=1
        fi
    done
    if [ $missing_deps -eq 1 ]; then
        echo -e "Arch: ${YELLOW}sudo pacman -S sysbench util-linux gawk${NC}"
        exit 1
    fi
}

print_header() {
    clear
    echo -e "${CYAN}============================================================${NC}"
    echo -e "${BOLD} SYSBENCH ULTIMATE DASHBOARD v13.2 ${NC}"
    echo -e "${CYAN}============================================================${NC}"
    local cpu_model=$(lscpu | grep "Model name" | cut -d: -f2 | xargs)
    echo -e "System: ${BOLD}$cpu_model${NC}"
    echo -e "Logical Cores: ${BOLD}$(nproc)${NC}"
    echo -e "${CYAN}------------------------------------------------------------${NC}"
}

# --- Helper: Calculate Threads from Range String ---
calc_threads() {
    local input=$1
    local count=0
    local list=$(echo "$input" | tr ',' ' ')
    
    for item in $list; do
        if [[ "$item" == *"-"* ]]; then
            local start=${item%-*}
            local end=${item#*-}
            count=$((count + end - start + 1))
        else
            count=$((count + 1))
        fi
    done
    echo "$count"
}

# --- Core Selection Logic ---
select_cores() {
    while true; do
        echo -e "\n${YELLOW}--- Core Selection ---${NC}"
        echo -e "1) ${GREEN}All Cores${NC} (Default)"
        echo -e "2) ${GREEN}Core 0 Only${NC} (P-Core Test)"
        echo -e "3) ${GREEN}Last Core Only${NC} (E-Core Test)"
        echo -e "4) ${GREEN}Custom Range${NC} (e.g., 0-3 or 0,2,4)"
        echo -e "q) ${RED}Cancel${NC}"
        echo -n "Select option [1]: "
        read core_opt

        # FIX: Handle empty input (Enter key) explicitly as default
        if [[ -z "$core_opt" ]]; then core_opt="1"; fi

        case $core_opt in
            q|Q) return 1 ;;
            1) 
                TASKSET_CMD="" 
                ACTIVE_THREADS=$(nproc)
                echo -e "${BLUE}>> Using All Cores (Threads: $ACTIVE_THREADS)${NC}"
                return 0
                ;;
            2) 
                TASKSET_CMD="taskset -c 0" 
                ACTIVE_THREADS=1
                echo -e "${BLUE}>> Pinned to Core 0 (Threads: 1)${NC}"
                return 0
                ;;
            3) 
                local last_core=$(($(nproc) - 1))
                TASKSET_CMD="taskset -c $last_core"
                ACTIVE_THREADS=1
                echo -e "${BLUE}>> Pinned to Core $last_core (Threads: 1)${NC}"
                return 0
                ;;
            4) 
                echo -n "Enter core list (e.g., 0-3 or 0,2,4): "
                read core_range
                
                if ! taskset -c "$core_range" true 2>/dev/null; then
                    echo -e "${RED}Error: Invalid core list format.${NC}"
                    # Do not return 1 here, just loop again to let user retry
                    continue 
                fi

                TASKSET_CMD="taskset -c $core_range"
                ACTIVE_THREADS=$(calc_threads "$core_range")
                echo -e "${BLUE}>> Logic: Detected $ACTIVE_THREADS Cores from '$core_range'${NC}"
                return 0
                ;;
            *) 
                # FIX: Invalid input now triggers a loop, NOT the default
                echo -e "${RED}Invalid option. Please select 1-4 or q.${NC}"
                ;;
        esac
    done
}

select_duration() {
    while true; do
        echo -e "\n${YELLOW}--- Duration Selection ---${NC}"
        echo -e "1) ${GREEN}10 Seconds${NC} (Default)"
        echo -e "2) ${GREEN}1 Minute${NC} (Stability)"
        echo -e "3) ${GREEN}Custom Time${NC}"
        echo -n "Select option [1]: "
        read time_opt

        if [[ -z "$time_opt" ]]; then time_opt="1"; fi

        case $time_opt in
            1) RunTime=10; echo -e "${BLUE}>> Duration: 10s${NC}"; return 0 ;;
            2) RunTime=60; echo -e "${BLUE}>> Duration: 60s${NC}"; return 0 ;;
            3) 
                echo -n "Enter seconds: "
                read custom_time
                # Ensure custom time is an integer
                if [[ "$custom_time" =~ ^[0-9]+$ ]]; then
                    RunTime=$custom_time
                    echo -e "${BLUE}>> Duration: ${RunTime}s${NC}"
                    return 0
                else
                    echo -e "${RED}Invalid time format.${NC}"
                fi
                ;;
            *) echo -e "${RED}Invalid option.${NC}" ;;
        esac
    done
}

# --- 1. CPU Benchmark ---
menu_cpu() {
    print_header
    echo -e "${BOLD}CPU BENCHMARK${NC}"
    echo -e "Calculating Primes up to 50,000."
    
    # If user hits 'q' in core selection, return to Main Menu
    if ! select_cores; then return; fi
    if ! select_duration; then return; fi

    echo -e "\n${YELLOW}Starting Benchmark...${NC}"
    sleep 1
    
    $TASKSET_CMD sysbench cpu \
        --cpu-max-prime=50000 \
        --threads=$ACTIVE_THREADS \
        --time=$RunTime \
        --events=0 \
        --report-interval=1 run
        
    read -p "Press Enter to return..."
}

# --- 2. Memory Benchmark ---
menu_memory() {
    print_header
    echo -e "${BOLD}MEMORY BENCHMARK${NC}"
    
    local oper="read"
    local block_size="1M"
    local access_mode="seq"
    local valid_mode=0

    while [ $valid_mode -eq 0 ]; do
        echo "1) Sequential Read (Large Blocks - Max Bandwidth)"
        echo "2) Random Read (Small Blocks - Latency/IOPS)"
        echo "3) Sequential Write"
        echo -e "q) ${RED}Back${NC}"
        echo -n "Select Mode [1]: "
        read mem_opt
        
        if [[ -z "$mem_opt" ]]; then mem_opt="1"; fi

        case $mem_opt in
            q|Q) return ;;
            1) 
                echo -e "${BLUE}>> Mode: Sequential Read (1M Blocks)${NC}"
                valid_mode=1 
                ;;
            2) 
                block_size="4K"
                access_mode="rnd"
                echo -e "${BLUE}>> Mode: Random Access (4K Blocks)${NC}"
                valid_mode=1
                ;;
            3) 
                oper="write" 
                echo -e "${BLUE}>> Mode: Sequential Write (1M Blocks)${NC}"
                valid_mode=1
                ;;
            *) echo -e "${RED}Invalid option.${NC}" ;;
        esac
    done

    if ! select_cores; then return; fi
    if ! select_duration; then return; fi

    echo -e "\n${YELLOW}Starting Benchmark...${NC}"
    
    $TASKSET_CMD sysbench memory \
        --memory-block-size=$block_size \
        --memory-access-mode=$access_mode \
        --memory-total-size=500T \
        --memory-oper=$oper \
        --threads=$ACTIVE_THREADS \
        --time=$RunTime \
        --events=0 \
        --report-interval=1 run
        
    read -p "Press Enter to return..."
}

# --- 3. Threads Benchmark ---
menu_threads() {
    print_header
    echo -e "${BOLD}THREADS (SCHEDULER) BENCHMARK${NC}"
    if ! select_cores; then return; fi
    if ! select_duration; then return; fi

    echo -e "\n${YELLOW}Starting Benchmark...${NC}"
    $TASKSET_CMD sysbench threads \
        --thread-locks=1 \
        --threads=$ACTIVE_THREADS \
        --time=$RunTime \
        --events=0 \
        --report-interval=1 run
        
    read -p "Press Enter to return..."
}

# --- Main Loop ---
check_deps
while true; do
    print_header
    echo "1) CPU Speedometer"
    echo "2) RAM Speedometer (Bandwidth/Latency)"
    echo "3) Scheduler Latency"
    echo "q) Quit"
    echo -e "${CYAN}------------------------------------------------------------${NC}"
    echo -n "Select: "
    read choice

    case $choice in
        1) menu_cpu ;;
        2) menu_memory ;;
        3) menu_threads ;;
        q|Q) echo -e "${YELLOW}Exiting.${NC}"; exit 0 ;;
        *) ;;
    esac
done
