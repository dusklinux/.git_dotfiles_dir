# Fix: Prevent double-launch of GNOME apps (Nautilus)

> **Goal:** Add a small per-user launcher script and patch Nautilus's desktop entry so selecting Nautilus from `drun` (e.g. rofi) opens **one** window only.

This note contains **copy-pasteable commands** in code blocks. Paste each block into your terminal and run it. The commands act in your **home directory only** (no root required). Tested pattern: Nautilus desktop file = `org.gnome.Nautilus.desktop`.

---

## Quick overview

1. Create a single generic launcher script at `~/.local/bin/safe-launcher`. (one-time)
    
2. Copy the Nautilus `.desktop` into `~/.local/share/applications/` and back it up.
    
3. Replace the `Exec=` line to call the launcher with the DBus name and binary path.
    
4. Test and verify.
    

> [!note]  
> This is **per-user** and **reversible**. We do not modify system files in `/usr/share/applications`. If something goes wrong you can restore the backup.

---

# 1 — Create the safe launcher (one-time)

Create `~/.local/bin/safe-launcher` and make it executable. 
**Just run this in the terminal. **

```bash
mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/safe-launcher" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

DBUS_NAME="$1"; shift
BIN="$1"; shift
APP_ARGS=("$@")

HAS_OWNER_RAW=$(gdbus call --session --dest org.freedesktop.DBus \
  --object-path /org/freedesktop/DBus \
  --method org.freedesktop.DBus.NameHasOwner "$DBUS_NAME" 2>/dev/null || echo "(false,)")

if echo "$HAS_OWNER_RAW" | grep -q "true"; then
  gdbus call --session --dest "$DBUS_NAME" --object-path /org/gnome/"${DBUS_NAME##*.}" \
    --method org.freedesktop.Application.Activate >/dev/null 2>&1 || true
  exit 0
else
  exec "$BIN" "${APP_ARGS[@]}"
fi
EOF

chmod +x "$HOME/.local/bin/safe-launcher"
```

> [!tip]  
> The launcher accepts: `safe-launcher DBUS_NAME BINARY_PATH [args...]`. We will call it with `org.gnome.Nautilus /usr/bin/nautilus %U`.

---

# 2 — Copy and backup Nautilus desktop file

Copy the system desktop file into your user applications directory and create a backup copy.

```bash
mkdir -p "$HOME/.local/share/applications"
cp /usr/share/applications/org.gnome.Nautilus.desktop "$HOME/.local/share/applications/" \
  2>/dev/null || { echo "ERROR: system Nautilus desktop file not found"; exit 1; }

# backup the copied desktop file
cp "$HOME/.local/share/applications/org.gnome.Nautilus.desktop" \
   "$HOME/.local/share/applications/org.gnome.Nautilus.desktop.bak" 2>/dev/null || true

# show file that was copied
ls -l "$HOME/.local/share/applications/org.gnome.Nautilus.desktop" || true
```

> [!warning]  
> If `cp` returns an error it's likely the desktop file has a different name on your system. Run the following command and use the name shown.
> ```bash
> ls /usr/share/applications | grep -i nautilus
> ```


---

# 3 — Patch the Exec line to call the launcher

This replaces the first `Exec=` line in your **local** copy so the launcher is used. It preserves `%U` so URIs/files still pass through.

```bash
sed -i "0,/^Exec=/s|^Exec=.*|Exec=$HOME/.local/bin/safe-launcher org.gnome.Nautilus /usr/bin/nautilus %U|" \
  "$HOME/.local/share/applications/org.gnome.Nautilus.desktop"

# confirm the Exec line change
grep -n "^Exec=" "$HOME/.local/share/applications/org.gnome.Nautilus.desktop" || true
```

> [!note]  
> This only changes the _user copy_ in `~/.local/share/applications`. System updates won't overwrite your user copy.

---

# 4 — Optional: update desktop database

Not strictly required, but you can refresh the desktop database cache.

```bash
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
```

---

# 5 — Test it

Kill any running Nautilus and launch it via your launcher (rofi `drun` or your app menu). You should see only **one** Nautilus window.

```bash
pkill -f nautilus || true
sleep 0.3
# Now open Nautilus from rofi/drun or your menu - no terminal command needed

# If you want to roughly simulate launching the desktop entry from terminal
# (gtk-launch may or may not be installed):
gtk-launch org.gnome.Nautilus || true

# Confirm processes (should show one Nautilus process)
pgrep -a nautilus || true
```

> [!success]  
> If you now open Nautilus from `drun` it should create a single window. If it still opens two windows, copy the output of `pgrep -a nautilus` and `journalctl --user -n 100 --no-pager` and keep the files — you can troubleshoot further.

---

# 6 — Revert quickly (if needed)

If you want to roll back to the original behavior, restore the `.bak` and remove the launcher (optional):

```bash
# restore desktop file from backup (if present)
if [ -f "$HOME/.local/share/applications/org.gnome.Nautilus.desktop.bak" ]; then
  mv "$HOME/.local/share/applications/org.gnome.Nautilus.desktop.bak" \
     "$HOME/.local/share/applications/org.gnome.Nautilus.desktop" || true
fi

# remove launcher (optional)
# rm -f "$HOME/.local/bin/safe-launcher"
```

---

# 7 — Repeat for other GNOME apps (template)

If you want to fix other GNOME apps, use this template. Replace `DESKTOP_FILE`, `DBUS_NAME`, and `BINARY` with the correct values.

```bash
# Example variables - edit for each app
DESKTOP_FILE="org.gnome.gedit.desktop"    # change as needed
DBUS_NAME="org.gnome.gedit"               # change as needed
BINARY="/usr/bin/gedit"                   # change as needed

# copy & backup
mkdir -p "$HOME/.local/share/applications"
cp "/usr/share/applications/$DESKTOP_FILE" "$HOME/.local/share/applications/" 2>/dev/null || { echo "Desktop file not found: $DESKTOP_FILE"; exit 1; }
cp "$HOME/.local/share/applications/$DESKTOP_FILE" "$HOME/.local/share/applications/${DESKTOP_FILE}.bak" 2>/dev/null || true

# patch Exec line
sed -i "0,/^Exec=/s|^Exec=.*|Exec=$HOME/.local/bin/safe-launcher $DBUS_NAME $BINARY %U|" "$HOME/.local/share/applications/$DESKTOP_FILE"
```

> [!tip]  
> If you're unsure of the DBus name for an app: run `dbus-monitor --session "type='method_call',interface='org.freedesktop.Application'"` once while launching the app from `drun` to see the `destination=` value (DBus name). You already captured `org.gnome.Nautilus` earlier.

---

# 8 — Troubleshooting quick tips

- If `Exec` change had no effect, confirm your launcher reads user desktop files (`~/.local/share/applications`). Some cached launchers may need a restart/log-out.
    
- If you still get duplicates: check `journalctl --user -f` while reproducing to see dbus/systemd lines like `dbus-:1.2-org.gnome.Nautilus@...`.
    
- If an app is a Flatpak, use `flatpak run <app-id>` as the binary path instead of `/usr/bin/...`.
    

---

# Final notes

- This method is conservative: **per-user**, **reversible**, and **does not remove** system-level portal packages.
    
- Keep the `.bak` files until you are comfortable with the change.
    
