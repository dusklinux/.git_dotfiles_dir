# Check if asusctl is installed (silent check)
if command -v asusctl >/dev/null 2>&1; then
    
    # Execute all asusctl commands in a silent block
    {
        # 1. Set active profile to Quiet (-P)
        # 2. Set battery default to Quiet (-b)
        # 3. Set AC default to Quiet (-a)
        # 4. Turn off keyboard backlight (-k off)
        asusctl profile -P Quiet && \
        asusctl profile -b Quiet && \
        asusctl profile -a Quiet && \
        asusctl -k off
    } >/dev/null 2>&1 || true

else
    # Case: asusctl not installed
    # Per your latest request for total silence, I have commented this out.
    # Uncomment the line below if your parent script specifically relies on this string:
    # printf "Not Dusk's laptop so asus setting not applied.\n"
    : # bash no-op
fi
