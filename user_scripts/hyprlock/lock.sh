#!/bin/bash

# Cache the current wallpaper path
WALLPAPER=$(swww query | grep -oP 'image: \K.*' | head -1)

# Copy wallpaper to cache location (hyprlock reads static path)
cp "$WALLPAPER" ~/.cache/current_wallpaper

# Launch hyprlock
hyprlock
