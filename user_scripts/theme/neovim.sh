#!/bin/bash

# NvChad Theme Switcher Script
# Runs silently as part of a master theming sequence.
# Edits ~/.config/nvim/lua/chadrc.lua based on user_set_theme.txt and all_themes/<theme>/nvim.txt.
# Targets M.ui.theme for theme setting (per NvChad config merge with nvconfig.lua).
# Adds M.ui table if missing; replaces theme line within it if present.
# Reloads running Neovim instance if possible.
# Clears base46 and lazy caches to ensure theme applies on restart.
# Robust: Handles missing files gracefully, backs up config, proceeds on errors.
# Silent: Minimal stderr output only on failures; no stdout.
# Assumes built-in themes; for custom, manual setup in custom/themes/ required (not handled here).

set -u  # Treat unset variables as error
set -o pipefail  # Fail on pipe errors

# Paths
HOME_DIR="$HOME"
THEMING_DIR="$HOME_DIR/.config/theming"
USER_THEME_FILE="$THEMING_DIR/user_set_theme.txt"
CHADRC_FILE="$HOME_DIR/.config/nvim/lua/chadrc.lua"
BASE46_CACHE_DIR="$HOME_DIR/.local/share/nvim/nvchad/base46"
LAZY_CACHE_DIR="$HOME_DIR/.local/share/nvim/lazy"
BACKUP_SUFFIX=".bak.$(date +%Y%m%d_%H%M%S)"

# Built-in themes (partial list; extend if needed)
BUILTIN_THEMES=("onedark" "gruvbox" "tokyonight" "everforest" "everforest_light" "catppuccin" "github_dark" "rose-pine")

# Function to log errors silently (to stderr only if verbose or critical)
log_error() {
    echo "NvChad theme switcher: $1" >&2
}

# Step 1: Read user theme directory name (trim whitespace/newlines)
if [[ -f "$USER_THEME_FILE" ]]; then
    THEME_DIR=$(tr -d ' \n\t\r' < "$USER_THEME_FILE")
    if [[ -z "$THEME_DIR" ]]; then
        log_error "Empty user_set_theme.txt; skipping NvChad edit."
        exit 0
    fi
else
    log_error "user_set_theme.txt not found; skipping NvChad edit."
    exit 0
fi

# Step 2: Construct and check nvim.txt path
NVIM_SNIPPET="$THEMING_DIR/all_themes/$THEME_DIR/nvim.txt"
if [[ ! -f "$NVIM_SNIPPET" ]]; then
    log_error "nvim.txt not found for theme '$THEME_DIR'; skipping NvChad edit."
    exit 0
fi

# Step 3: Extract the theme name from nvim.txt (just the value, e.g., "dark-brown")
# Robust: Grep for theme\s*=\s*"([^"]*)", capture the quoted value.
THEME_NAME=$(grep -oP 'theme\s*=\s*"\K[^"]+' "$NVIM_SNIPPET" 2>/dev/null | head -n1)
if [[ -z "$THEME_NAME" ]]; then
    log_error "No valid theme name extracted from nvim.txt for '$THEME_DIR'; skipping."
    exit 0
fi

# Check if custom theme; warn/log if not built-in (user must add custom/themes/${THEME_NAME}.lua manually)
if [[ ! " ${BUILTIN_THEMES[@]} " =~ " ${THEME_NAME} " ]]; then
    log_error "Theme '$THEME_NAME' not built-in; ensure ~/.config/nvim/lua/custom/themes/${THEME_NAME}.lua exists for custom support."
fi

# Prepare the theme line: "  theme = \"${THEME_NAME}\","
THEME_LINE="  theme = \"${THEME_NAME}\","

# Step 4: Check and backup chadrc.lua
if [[ ! -f "$CHADRC_FILE" ]]; then
    log_error "chadrc.lua not found; NvChad may not be installed. Skipping edit."
    exit 0
fi

# Create backup
cp "$CHADRC_FILE" "$CHADRC_FILE$BACKUP_SUFFIX" 2>/dev/null || log_error "Backup failed; proceeding without backup."

# Step 5: Edit chadrc.lua to set/replace in M.ui table
# Use awk for precision: If M.ui exists, replace its theme line; else, insert M.ui = { theme_line } before return M
if awk -v theme_line="$THEME_LINE" '
    /M\.ui\s*=/ { in_ui = 1; print; next }
    in_ui && /^[[:space:]]*theme[[:space:]]*=[[:space:]]*"[^"]*"/ { print "  " theme_line; in_ui = 0; next }
    in_ui && /}/ { in_ui = 0 }
    in_ui { print; next }
    !in_ui { print }
    /return M/ { if (!found_ui) print "M.ui = {\n" theme_line "\n}\n"; found_ui = 1 }
    { print }
' "$CHADRC_FILE" > "$CHADRC_FILE.tmp" 2>/dev/null && mv "$CHADRC_FILE.tmp" "$CHADRC_FILE"; then
    :  # Success: silent
else
    log_error "Failed to edit chadrc.lua (awk error); manual review needed. Backup: $CHADRC_FILE$BACKUP_SUFFIX"
    # Fallback: Simple sed to add/replace any theme line (less precise, but better than nothing)
    sed -i.bak "/^[[:space:]]*theme[[:space:]]*=[[:space:]]*\"[^\"]*\"/c\\$THEME_LINE" "$CHADRC_FILE" 2>/dev/null || \
    log_error "Fallback sed also failed; theme unchanged."
fi

# Step 6: Clear caches to force rebuild on next startup
rm -rf "$BASE46_CACHE_DIR" 2>/dev/null || true
rm -rf "$LAZY_CACHE_DIR"/state.json "$LAZY_CACHE_DIR"/lock.json 2>/dev/null || log_error "Failed to clear lazy state; manual :Lazy sync may be needed."

# Step 7: Reload running Neovim instances (silent, best-effort)
mapfile -t NVIM_PIDS < <(pgrep -f nvim 2>/dev/null || true)
if [[ ${#NVIM_PIDS[@]} -gt 0 ]]; then
    for PID in "${NVIM_PIDS[@]}"; do
        SERVER_ADDR="/tmp/nvim.${PID}/0"
        if [[ -S "$SERVER_ADDR" ]]; then
            nvim --server "$SERVER_ADDR" --remote-send ':lua require("chadrc").reload()<CR>' >/dev/null 2>&1 || true
            nvim --server "$SERVER_ADDR" --remote-send ':lua require("base46").load_all_highlights()<CR>' >/dev/null 2>&1 || true
            # Additional: Sync lazy if possible (but remote-send may not handle it well; best on restart)
            nvim --server "$SERVER_ADDR" --remote-send ':Lazy sync<CR>' >/dev/null 2>&1 || true
        fi
    done
fi

# Step 8: Exit successfully (always, per requirements)
exit 0
