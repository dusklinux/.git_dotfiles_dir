# WiFi Security Audit & Hardening Protocol

Date: {{date}}

Scope: Self-Owned Network Infrastructure

Objective: Identify vulnerabilities in Wireless Access Points (WAP) and harden against unauthorized access.

Tools Required: aircrack-ng suite, wifite, hcxtools, reaver, bully, hashcat, wireshark, macchanger.

## 1. Legal & Ethical Standing

> **WARNING:** The tools listed below (Reaver, Bully, Aircrack) are classified as dual-use technologies. Using them on any network without explicit, written permission from the owner is illegal in most jurisdictions (e.g., CMA in the UK, CFAA in the US).
> 
> - **Rule 1:** Only audit networks you strictly own.
>     
> - **Rule 2:** Notify other users on the network before testing, as de-authentication attacks will disrupt service.
>     

## 2. Preparation: The Wireless Interface

Standard WiFi cards operate in "Managed Mode" (listening only to traffic meant for them). To audit a network, you must enable **Monitor Mode** (listening to all raw radio signals).

### 2.1 Anonymization (Optional but Recommended)

Before engaging, professionals often rotate their MAC address to test if "MAC Filtering" is active or to isolate audit traffic.

```
sudo ifconfig wlan0 down
sudo macchanger -r wlan0
sudo ifconfig wlan0 up
```

### 2.2 Enabling Monitor Mode

The `airmon-ng` tool handles the interaction between the kernel and the wireless driver.

```
# Kill processes that interfere with monitor mode (NetworkManager, wpa_supplicant)
sudo airmon-ng check kill

# Enable monitor mode
sudo airmon-ng start wlan0
```

_Your interface will likely rename to `wlan0mon`._

## 3. Reconnaissance & Enumeration

You cannot secure what you cannot see. The first step is mapping the radio frequency (RF) environment.

### 3.1 Packet Capture (Airodump-ng)

This tool captures raw 802.11 frames.

```
sudo airodump-ng wlan0mon
```

**Diagnostic Indicators:**

- **BSSID:** MAC address of the Access Point (AP).
    
- **PWR:** Signal strength (closer to 0 is stronger).
    
- **Beacons:** Announcement frames sent by the AP.
    
- **ENC:** Encryption type (WEP, WPA, WPA2, WPA3).
    
- **AUTH:** Authentication (MGT, PSK, OPN).
    
- **ESSID:** The name of the network.
    

**Audit Goal:** Identify your target BSSID and the Channel (CH) it is broadcasting on.

## 4. Vulnerability Assessment Vectors

### Vector A: WPS Implementation (Reaver / Bully)

The Vulnerability: Wi-Fi Protected Setup (WPS) allows connection via an 8-digit PIN. The protocol verifies the PIN in halves (4 digits + 3 digits + checksum), reducing the possibilities from 100,000,000 to just 11,000.

The Test:

Use wash (identifies WPS-enabled APs) or the audit mode of wifite.

```
# Check for WPS Lock status
sudo wash -i wlan0mon
```

- **Vulnerable:** If "WPS Locked" is "No". Tools like `reaver` or `bully` would theoretically brute-force this PIN in <10 hours, revealing the WPA passphrase in plaintext.
    
- **Hardened:** If no results appear or "WPS Locked" is "Yes".
    
- **Remediation:** Log into the router and **DISABLE WPS** entirely.
    

### Vector B: WPA/WPA2 Handshakes (Aircrack-ng / Wifite)

The Vulnerability: WPA2 uses a "4-Way Handshake" to authenticate clients. This handshake contains the specialized hash (MIC) required to validate the password. If an attacker captures this handshake, they can take it offline and guess passwords against it at high speed.

The Test:

1. Focus monitoring on your specific channel:
    
    ```
    sudo airodump-ng -c [CHANNEL] --bssid [AP_MAC] -w capture_file wlan0mon
    ```
    
2. Force a reconnection (De-authentication):
    
    - Devices only send the handshake when connecting. To audit this, you simulate a disconnection.
        
    - _Note: This effectively disconnects the device for a few seconds._
        
    
    ```
    sudo aireplay-ng -0 2 -a [AP_MAC] -c [CLIENT_MAC] wlan0mon
    ```
    
3. **Success:** Airodump will display `[ WPA Handshake: ... ]`.
    

### Vector C: PMKID Attack (Hcxtools)

The Vulnerability: Newer routers supporting roaming features store a PMKID in the first frame of the handshake. This allows an attacker to capture the hash without a client device being connected.

The Test:

Use hcxdumptool to request the PMKID directly from the AP.

```
# Passive/Active capture of PMKID
sudo hcxdumptool -i wlan0mon -o hash.pcapng --enable_status=1
```

- **Remediation for Vector B & C:** These attacks cannot be "patched" in WPA2; they are part of the protocol. Security relies entirely on **Password Complexity** (Entropy).
    

## 5. Strength Auditing (Cracking)

Once a handshake or PMKID is captured, the security of the network depends solely on the strength of the password. This is where `hashcat` and `john` apply.

### 5.1 Converting Captures

Tools like `hcxpcapngtool` convert the raw `.pcap` or `.cap` file into a hash format Hashcat understands.

```
hcxpcapngtool -o hash.22000 capture_file.pcap
```

_(Mode 22000 is the modern standard for WPA-PBKDF2-PMKID+EAPOL)._

### 5.2 The Stress Test (Hashcat)

This step determines how long it would take to crack your password.

```
# Dictionary Attack (Using a wordlist)
hashcat -m 22000 hash.22000 wordlist.txt

# Brute Force (Mask Attack - trying all combinations)
hashcat -m 22000 hash.22000 -a 3 ?a?a?a?a?a?a?a?a
```

**Interpretation:**

- If `hashcat` finds the password in minutes: **CRITICAL FAIL**. Your password is too common or too short.
    
- If `hashcat` estimates thousands of years: **PASS**.
    

## 6. Diagnostic Monitoring (Wireshark)

Use `wireshark` to verify that your encryption is actually encrypting data.

1. Open the `.pcap` file captured during Reconnaissance.
    
2. Go to **Edit > Preferences > Protocols > IEEE 802.11**.
    
3. Ensure "Decryption" is NOT enabled (unless you put your key in).
    
4. Look at "Data" frames.
    
    - **Secure:** The payload should be garbled/illegible "Cipher Data".
        
    - **Insecure:** If you see "HTTP", "Telnet", or plain text strings in the data pane, the network is Open (OPN) or encryption is broken.
        

## 7. Hardening Checklist (The "PhD" Conclusion)

To render the tools above ineffective, implement this configuration:

1. **Protocol:** **WPA3-Personal (SAE)**.
    
    - _Why:_ WPA3 uses "Simultaneous Authentication of Equals" (Dragonfly), which renders the Handshake Capture (Vector B) and PMKID (Vector C) useless. Offline dictionary attacks are impossible on WPA3.
        
2. **Legacy Fallback:** If WPA3 is unavailable, use **WPA2-AES**.
    
    - _Never_ use TKIP or WPA/WEP.
        
3. **WPS:** **DISABLED**.
    
    - _Why:_ Completely neutralizes Reaver and Bully (Vector A).
        
4. **Password Entropy:**
    
    - Minimum **20 characters**.
        
    - Mix of unrelated words (e.g., `Coffee-Planet-Jump-72!`).
        
    - _Why:_ Defeats Hashcat (Step 5). Even the fastest supercomputers cannot brute-force a 20-char complex password.
        
5. **Management Frames:** Enable **PMF (Protected Management Frames)** on your router (sometimes called 802.11w).
    
    - _Why:_ Protects against the De-authentication attacks used to force handshakes.
        

**End of Audit Protocol**