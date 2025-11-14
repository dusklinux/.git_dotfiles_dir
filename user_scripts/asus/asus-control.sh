#!/bin/bash

# asus-control.sh (v21.0 Definitive)
# A definitive, user-friendly script to manage Asus laptop features.
# This script must be run with root privileges (e.g., sudo ./asus-control.sh).

# --- Helper Functions ---
run() {
    # Execute a command quietly:
    # - set RUST_LOG=error to suppress Rust/tracing INFO logs from asusctl and libraries
    # - capture stdout+stderr, preserve exit status, then filter common noisy trace lines
    local cmd="$1"
    local output
    # Run command with env override; use bash -lc so complex commands still work
    output=$(bash -lc "RUST_LOG=error RUST_BACKTRACE=0 $cmd" 2>&1)
    local status=$?
    # Filter noisy tracing lines but keep useful command output. Adjust regexes if needed.
      printf "%s\n" "$output" | sed -E \
        -e '/^\[[A-Z]+ .*\]/d' \
        -e '/^\[[A-Z]+/d' \
        -e '/tracing::span/d' \
        -e '/zbus::/d' \
        -e '/read_socket/d' \
        -e '/write_command/d' \
        -e '/read_command/d' \
        -e '/receive_secondary_responses/d' \
        -e '/Starting version [0-9.]+/d'
    return $status
}

show_status() {
    echo "--------------------------------- CURRENT STATUS ---------------------------------"
    PROFILE=$(run "asusctl profile -p" | sed 's/Active profile is //')
    echo "Performance Profile : $PROFILE"
    echo "Fan Curves for '$PROFILE' profile:"
    CPU_STATUS=$(run "asusctl fan-curve -g" | grep "CPU:")
    GPU_STATUS=$(run "asusctl fan-curve -g" | grep "GPU:")
    echo "  - $CPU_STATUS"
    echo "  - $GPU_STATUS"
    echo "--------------------------------------------------------------------------------"
    echo
}

rgb_to_hex() {
    local r g b; IFS=',' read -r r g b <<< "$1"
    if ! [[ "$r" =~ ^[0-9]+$ && "$g" =~ ^[0-9]+$ && "$b" =~ ^[0-9]+$ && "$r" -le 255 && "$g" -le 255 && "$b" -le 255 ]]; then
        echo "Invalid RGB format." >&2; return 1
    fi
    printf "%02x%02x%02x\n" "$r" "$g" "$b"
}

apply_and_enable_curves() {
    local profile_orig=$1 cpu_curve=$2 gpu_curve=$3
    local profile=${profile_orig,,}
    echo "--- Applying Fan Curves for '$profile_orig' profile ---"
    echo "Step 1: Setting CPU curve data..."
    run "asusctl fan-curve -m \"$profile\" -f cpu -D \"$cpu_curve\""
    sleep 1
    echo "Step 2: Setting GPU curve data..."
    run "asusctl fan-curve -m \"$profile\" -f gpu -D \"$gpu_curve\""
    sleep 1
    echo "Step 3: Enabling custom fan curves for the profile..."
    if run "asusctl fan-curve -e true -m \"$profile\""; then
        echo "SUCCESS: Custom fan curves have been enabled."
    else
        echo "Error: Failed to enable custom curves for the profile."
    fi
}

# --- Menus ---
manage_fan_curves() {
    while true; do
        clear; local profile; profile=$(run "asusctl profile -p" | sed 's/Active profile is //')
        echo "--- Fan Curve Management for '$profile' profile ---"; show_status
        echo -e "1. Return to Profile Default\n2. Set Max Speed Curves\n3. Generate Custom Curve (Wizard)\n4. Enter Curves Manually\n5. Select a Preset Curve\nb. Back"
        read -p "Enter your choice: " choice
        case $choice in
            1)
                echo "Disabling custom fan curves for '$profile'...";
                if run "asusctl fan-curve -m \"${profile,,}\" -e false"; then echo "Success."; else echo "Error."; fi
                read -n 1 -s -r -p "Press any key to continue..."
                ;;
            2)
                local max_curve="37c:100%,55c:100%,59c:100%,62c:100%,65c:100%,67c:100%,70c:100%,72c:100%"
                apply_and_enable_curves "$profile" "$max_curve" "$max_curve"
                read -n 1 -s -r -p "Press any key to continue..."
                ;;
            3)
                clear; echo "--- Interactive Fan Curve Generator ---"
                echo -e "\nThis wizard will help you create an 8-point custom fan curve."
                echo "You will provide a starting point and the increments for temperature and fan speed."
                echo -e "\n- Starting Temperature: The temperature (in Celsius) for the first point."
                echo "- Starting Fan Speed %%: The fan speed percentage for the first point."
                echo "- Temp Increment: The number of degrees to add for each subsequent point."
                echo -e "- Fan %% Increment: The fan speed percentage to add for each subsequent point."
                echo -e "\nThe script will generate 8 points based on your input."
                echo -e "Both temperature and fan speed will be automatically capped at 100.\n"
                read -p "Enter starting temperature (e.g., 30): " st; read -p "Enter starting fan speed % (e.g., 10): " sf
                read -p "Enter temp increment per point (e.g., 10): " ti; read -p "Enter fan % increment per point (e.g., 15): " fi
                if ! [[ "$st" =~ ^[0-9]+$ && "$sf" =~ ^[0-9]+$ && "$ti" =~ ^[0-9]+$ && "$fi" =~ ^[0-9]+$ ]]; then
                    echo "Invalid input."; read -n 1 -s -r; continue
                fi
                declare -a points; for i in {0..7}; do
                    ct=$((st + i * ti)); [ $ct -gt 100 ] && ct=100; cf=$((sf + i * fi)); [ $cf -gt 100 ] && cf=100
                    points+=("${ct}c:${cf}%")
                done
                local final_curve; final_curve=$(IFS=,; echo "${points[*]}")
                echo -e "\nGenerated Curve: $final_curve\n"
                read -p "Apply this curve to CPU and GPU? (y/n): " confirm
                if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then apply_and_enable_curves "$profile" "$final_curve" "$final_curve"
                else echo "Aborted."; fi
                read -n 1 -s -r -p "Press any key to continue..."
                ;;
            4)
                echo "Enter CPU fan curve string: "; read cpu_curve
                echo "Enter GPU fan curve string: "; read gpu_curve
                apply_and_enable_curves "$profile" "$cpu_curve" "$gpu_curve"
                read -n 1 -s -r -p "Press any key to continue..."
                ;;
            5)
                while true; do
                    clear; echo "--- Select a Preset Fan Curve ---"
                    echo -e "1. Slow\n2. Medium\n3. Fast\nb. Back"
                    read -p "Enter your choice: " preset_choice
                    local preset_curve=""
                    case $preset_choice in
                        1) preset_curve="50c:0%,60c:20%,70c:40%,80c:60%,90c:80%,100c:100%,100c:100%,100c:100%";;
                        2) preset_curve="40c:10%,50c:25%,60c:40%,70c:55%,80c:70%,90c:85%,100c:100%,100c:100%";;
                        3) preset_curve="30c:10%,40c:25%,50c:40%,60c:55%,70c:70%,80c:85%,90c:100%,100c:100%";;
                        b) break;;
                        *) echo "Invalid choice."; read -n 1 -s -r; continue;;
                    esac
                    if [[ -n "$preset_curve" ]]; then
                        apply_and_enable_curves "$profile" "$preset_curve" "$preset_curve"
                        read -n 1 -s -r -p "Press any key to continue..."
                        break
                    fi
                done
                ;;
            b) break ;;
            *) echo "Invalid choice." ;;
        esac
    done
}
manage_keyboard() {
    declare -A colors=( ["Red"]="FF0000" ["Green"]="00FF00" ["Blue"]="0000FF" ["White"]="FFFFFF" ["Cyan"]="00FFFF" ["Magenta"]="FF00FF" ["Yellow"]="FFFF00" ["Orange"]="FFA500" ["Purple"]="800080" ["Pink"]="FFC0CB" )
    declare -a color_names=("Red" "Green" "Blue" "White" "Cyan" "Magenta" "Yellow" "Orange" "Purple" "Pink")
    while true; do
        clear; echo "--- Keyboard Aura Management ---"; show_status
        echo "Select a color:"; for i in "${!color_names[@]}"; do printf "%2d. %-7s\n" "$((i+1))" "${color_names[$i]}"; done
        echo " c. Custom Hex Color"; echo " r. Custom RGB Color"; echo " b. Back"
        read -p "Enter choice: " choice; local color_hex=""
        case $choice in
            [1-9]|10) color_name="${color_names[$((choice-1))]}"; color_hex="${colors[$color_name]}" ;;
            c) read -p "Enter 6-digit hex (e.g., FF0000): " color_hex ;;
            r) read -p "Enter RGB value (e.g., 255,0,0): " rgb_val; color_hex=$(rgb_to_hex "$rgb_val") ;;
            b) break ;;
            *) echo "Invalid choice."; continue ;;
        esac
        if [[ -n "$color_hex" ]]; then
            echo "Setting keyboard color to #$color_hex..."; if run "asusctl aura static -c \"$color_hex\"" >/dev/null 2>&1; then echo "Success."; else echo "Failed."; fi
        fi; read -n 1 -s -r -p "Press any key to continue..."
    done
}
manage_profile() {
    while true; do
        clear; echo "--- Profile Management ---"; show_status
        mapfile -t profiles < <(run "asusctl profile -l"); echo "Select a new profile:"
        for i in "${!profiles[@]}"; do echo "$((i+1)). ${profiles[$i]}"; done; echo "b. Back"
        read -p "Enter choice [1-${#profiles[@]}]: " choice
        if [[ "$choice" == "b" ]]; then break; fi
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#profiles[@]}" ]; then
            selected_profile="${profiles[$((choice-1))]}"; echo "Setting profile to '$selected_profile'..."
            run "asusctl profile -P \"$selected_profile\""
        else echo "Invalid choice."; fi
        read -n 1 -s -r -p "Press any key to continue..."
    done
}
main_menu() {
    if [ "$EUID" -ne 0 ]; then
      echo "Error: This script must be run with root privileges."; echo "Please run as: sudo $0"; exit 1
    fi
    while true; do
        clear; echo "--- Asus Control Center (v21.0 Definitive) ---"; show_status
        echo -e "1. Manage Performance Profile\n2. Manage Fan Curves\n3. Manage Keyboard Aura\nq. Quit"
        read -p "Enter your choice: " choice
        case $choice in
            1) manage_profile ;;
            2) manage_fan_curves ;;
            3) manage_keyboard ;;
            q) echo "Exiting."; break ;;
            *) echo "Invalid choice."; read -n 1 -s -r ;;
        esac
    done
}
main_menu
