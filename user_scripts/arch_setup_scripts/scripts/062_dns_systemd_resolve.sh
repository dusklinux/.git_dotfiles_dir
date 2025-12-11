#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# ARCH LINUX SYSTEMD-RESOLVED CONFIGURATOR
# Context: Hyprland / UWSM / Arch
# -----------------------------------------------------------------------------
set -euo pipefail

# Ensure subshells inherit error trapping (Bash 4.4+)
shopt -s inherit_errexit 2>/dev/null || true

# ---[ USER CONFIGURATION ]---
# Paste your exact resolved.conf content between the 'EOF' markers.
# We add '|| true' because 'read' returns exit code 1 on EOF, which would 
# otherwise kill the script due to 'set -e'.

read -r -d '' RESOLVED_CONFIG <<'EOF' || true
# This file was created by a dusk script.
[Resolve]
# ===
#custom configured
DNS=9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net 1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com
FallbackDNS=9.9.9.9#dns.quad9.net 1.1.1.1#cloudflare-dns.com
#Domains=~.
DNSSEC=allow-downgrade
DNSOverTLS=opportunistic

#comment if you want to see stuff on your local network like yoru printer. 
#MulticastDNS=resolve
# OR
#this announces your setup to the the local network. 
MulticastDNS=yes

LLMNR=no

#===
#  This file is part of systemd.
#
#  systemd is free software; you can redistribute it and/or modify it under the
#  terms of the GNU Lesser General Public License as published by the Free
#  Software Foundation; either version 2.1 of the License, or (at your option)
#  any later version.
#
# Entries in this file show the compile time defaults. Local configuration
# should be created by either modifying this file (or a copy of it placed in
# /etc/ if the original file is shipped in /usr/), or by creating "drop-ins" in
# the /etc/systemd/resolved.conf.d/ directory. The latter is generally
# recommended. Defaults can be restored by simply deleting the main
# configuration file and all drop-ins located in /etc/.
#
# Use 'systemd-analyze cat-config systemd/resolved.conf' to display the full config.
#
# See resolved.conf(5) for details.

#[Resolve]
# Some examples of DNS servers which may be used for DNS= and FallbackDNS=:
# Cloudflare: 1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com 2606:4700:4700::1111#cloudflare-dns.com 2606:4700:4700::1001#cloudflare-dns.com
# Google:     8.8.8.8#dns.google 8.8.4.4#dns.google 2001:4860:4860::8888#dns.google 2001:4860:4860::8844#dns.google
# Quad9:      9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net 2620:fe::fe#dns.quad9.net 2620:fe::9#dns.quad9.net
#
# Using DNS= configures global DNS servers and does not suppress link-specific
# configuration. Parallel requests will be sent to per-link DNS servers
# configured automatically by systemd-networkd.service(8), NetworkManager(8), or
# similar management services, or configured manually via resolvectl(1). See
# resolved.conf(5) and systemd-resolved(8) for more details.
#DNS=
#FallbackDNS=9.9.9.9#dns.quad9.net 2620:fe::9#dns.quad9.net 1.1.1.1#cloudflare-dns.com 2606:4700:4700::1111#cloudflare-dns.com 8.8.8.8#dns.google 2001:4860:4860::8888#dns.google
#Domains=
#DNSSEC=no
#DNSOverTLS=no
#MulticastDNS=yes
#LLMNR=yes
#Cache=yes
#CacheFromLocalhost=no
#DNSStubListener=yes
#DNSStubListenerExtra=
#ReadEtcHosts=yes
#ResolveUnicastSingleLabel=no
#StaleRetentionSec=0
#RefuseRecordTypes=
EOF
readonly RESOLVED_CONFIG

# ---[ PREAMBLE ]---

# Modern ANSI Colors
readonly C_RESET=$'\e[0m'
readonly C_GREEN=$'\e[1;32m'
readonly C_BLUE=$'\e[1;34m'
readonly C_RED=$'\e[1;31m'
readonly C_YELLOW=$'\e[1;33m'

# Logging Helpers (using %s to prevent format injection)
log_info()    { printf "%s[INFO]%s %s\n" "$C_BLUE" "$C_RESET" "${1:-}"; }
log_success() { printf "%s[OK]%s %s\n" "$C_GREEN" "$C_RESET" "${1:-}"; }
log_warn()    { printf "%s[WARN]%s %s\n" "$C_YELLOW" "$C_RESET" "${1:-}" >&2; }
log_error()   { printf "%s[ERROR]%s %s\n" "$C_RED" "$C_RESET" "${1:-}" >&2; }

# Error Trap
trap 'log_error "Script failed on line $LINENO. Exiting."; exit 1' ERR

# ---[ ROOT ESCALATION ]---

if [[ $EUID -ne 0 ]]; then
    log_info "Root privileges required. Elevating..."
    exec sudo "$0" "$@"
fi

# ---[ MAIN LOGIC ]---

main() {
    local target_conf="/etc/systemd/resolved.conf"
    local stub_resolv="/run/systemd/resolve/stub-resolv.conf"
    local etc_resolv="/etc/resolv.conf"

    # 1. Dependency Check
    if ! command -v systemctl &>/dev/null; then
        log_error "systemd is required but not found."
        exit 1
    fi

    # 2. Write Configuration
    log_info "Writing configuration to $target_conf..."
    # Writing directly, no backups as requested
    printf "%s\n" "$RESOLVED_CONFIG" > "$target_conf"
    log_success "Configuration written."

    # 3. Handle Symlink
    log_info "Linking $etc_resolv -> $stub_resolv..."
    # -s: symbolic, -f: force (overwrites existing file)
    ln -sf "$stub_resolv" "$etc_resolv"
    log_success "Symlink updated."

    # 4. Service Management
    log_info "Restarting systemd-resolved..."
    
    # Enable ensures it starts on boot.
    # Restart forces the new config to load immediately.
    systemctl enable systemd-resolved
    systemctl restart systemd-resolved
    
    # 5. Wait for Stub File (Race Condition Protection)
    # The stub file is created dynamically by the service. We wait briefly to ensure it exists.
    local timeout=50 # 5 seconds (50 * 0.1s)
    local count=0
    while [[ ! -f "$stub_resolv" ]]; do
        if (( count++ >= timeout )); then
            log_warn "Timed out waiting for stub file at $stub_resolv."
            log_warn "DNS might take a moment to initialize."
            break
        fi
        sleep 0.1
    done

    # 6. Verification
    if systemctl is-active --quiet systemd-resolved; then
        log_success "Service is active."
    else
        log_error "Service failed to start."
        systemctl status systemd-resolved --no-pager -n 5
        exit 1
    fi

    printf "\n%s---[ DNS Status ]---%s\n" "$C_BLUE" "$C_RESET"
    resolvectl status
}

main "$@"
