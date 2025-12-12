#!/bin/bash

# 1. Define the vault location relative to the *current* user's home
#    Bash automatically expands ${HOME} to the current user's home dir.
VAULT_PATH="${HOME}/Documents/pensive"

# 2. Check if the config already exists to avoid overwriting user changes later
OBSIDIAN_CONFIG="${HOME}/.config/obsidian/obsidian.json"

if [[ ! -f "$OBSIDIAN_CONFIG" ]]; then
    
    # Ensure directory exists
    mkdir -p "$(dirname "$OBSIDIAN_CONFIG")"

    # 3. Generate a Vault ID
    #    Option A: Random ID (standard Obsidian behavior)
    #    VAULT_ID=$(head -c 8 /dev/urandom | xxd -p)
    
    #    Option B (Recommended): Deterministic ID based on the path
    #    This is cleaner for mass deployment; the same path always gets the same ID.
    VAULT_ID=$(echo -n "$VAULT_PATH" | md5sum | head -c 16)

    # 4. Generate Timestamp (Obsidian uses Unix millis)
    TIMESTAMP=$(date +%s%3N)

    # 5. Write the JSON using a Here-Doc
    #    We use pure Bash to write the file, injecting the variable.
    cat > "$OBSIDIAN_CONFIG" <<EOF
{
  "vaults": {
    "${VAULT_ID}": {
      "path": "${VAULT_PATH}",
      "ts": ${TIMESTAMP},
      "open": true
    }
  }
}
EOF

    echo ":: Obsidian config generated for user: $USER"
fi
