#!/bin/bash
# ------------------------------------------------------------------------------
# 🧮 ROFI CALCULATOR (QALCULATE)
# Optimized for: Arch Linux / Hyprland / Wayland
# Dependencies: rofi, libqalculate (qalc), wl-copy
# ------------------------------------------------------------------------------

# 1. Kill existing instance (Toggle behavior)
# If you map this to a keybind, pressing it again closes the calc.
if pgrep -x "rofi" >/dev/null; then
    pkill rofi
    exit 0
fi

# 2. Dependency Check
if ! command -v rofi &> /dev/null || ! command -v qalc &> /dev/null || ! command -v wl-copy &> /dev/null; then
    notify-send "Error" "Missing dependencies: rofi, libqalculate, or wl-copy" -u critical
    exit 1
fi


# 3. Main Loop
# Initialize variables to avoid empty display on first run
last_equation=""
last_result=""

while true; do
    # Dynamic message: Instructions on first run, Result on subsequent runs
    # We use Pango markup (<b>, <span>) to make the result stand out.
    if [ -z "$last_result" ]; then
        display_mesg="<i>Type an equation (e.g., 50*5) and hit Enter</i>"
    else
        display_mesg="<b>$last_equation</b> = <span color='#a6e3a1'>$last_result</span>"
    fi

    # Run Rofi
    # -lines 0: Hides the list view since we only need the input bar
    # -no-show-icons: Crucial to prevent broken icon lookups for numbers
    current_input=$(rofi -dmenu \
        -i \
        -lines 0 \
        -theme ~/.config/rofi/config.rasi \
        -no-show-icons \
        -p " Calc" \
        -mesg "$display_mesg")
    
    # Exit code handling (Esc or Cancel)
    if [ $? -ne 0 ]; then
        exit 0
    fi

    # 4. Calculation Logic
    if [ -n "$current_input" ]; then
        # Perform calculation using qalc
        # -t: Terse mode (returns only the result, no extra text)
        calculation=$(qalc -t "$current_input")
        
        # Update variables for next loop
        last_equation="$current_input"
        last_result="$calculation"

        # Copy to clipboard automatically
        echo -n "$last_result" | wl-copy
    fi
done
