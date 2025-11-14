#!/bin/bash

# --- CONFIGURATION ---
# Set your preferred terminal emulator here.
# Examples: "kitty", "alacritty", "foot", "gnome-terminal"
TERMINAL="kitty"
# ---------------------

# Check if ollama service is running
if ! pgrep -x "ollama" > /dev/null; then
    # If not running, display a message and attempt to start it.
    # rofi -e "Ollama service is not running. Attempting to start..." &
    
    # Use pkexec for a graphical password prompt to start the systemd service.
    # This is the standard way to request admin privileges from a desktop session.
    pkexec systemctl start ollama
    
    # Give the service a moment to initialize before checking again.
    sleep 2

    # Check one more time. If it's still not running, then exit with an error.
    if ! pgrep -x "ollama" > /dev/null; then
        rofi -e "Failed to start the Ollama service. Please check system logs."
        exit 1
    fi
fi

# Get the list of models, remove the header, and extract just the model names
MODELS=$(ollama list | awk 'NR>1 {print $1}')

# Check if any models are installed
if [ -z "$MODELS" ]; then
    rofi -e "No Ollama models found. Please run 'ollama pull <model_name>'."
    exit 1
fi

# Use rofi to present the models and get the user's choice
# -dmenu reads from stdin, -p sets the prompt
SELECTED_MODEL=$(echo "$MODELS" | rofi -dmenu -p "Select Ollama Model")

# If a model was selected (i.e., the user didn't press escape)
if [ -n "$SELECTED_MODEL" ]; then
    # Launch the terminal, set a custom title, and run ollama with the chosen model
    $TERMINAL --title "Ollama Chat: $SELECTED_MODEL" ollama run "$SELECTED_MODEL"
fi
