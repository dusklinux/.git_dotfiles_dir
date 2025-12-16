# Advanced WiFi Hardening Toolkit Additions

Date: {{date}}

Scope: Supplemental Tools for Advanced Auditing

Relation: Complements the standard aircrack-ng suite.

## 1. Bettercap (The Modern Standard)

Why you need it:

Most tutorials reference aircrack-ng, but bettercap is the modern replacement. It handles scanning, de-authentication, and handshake capture in a single, scriptable tool. It also supports Bluetooth (BLE) and other frequencies if you have the hardware.

**Key Command:**

```
# Start bettercap with the WiFi interface
sudo bettercap -iface wlan0mon

```

**Inside Bettercap:**

- `wifi.recon on` : Starts mapping the area.
    
- `wifi.show` : Shows a clean table of all targets.
    
- `wifi.deauth [MAC]` : Surgical de-authentication (harder to detect).
    

## 2. Kismet (Passive Wireless Mapper)

Why you need it:

Tools like wifite are "active"—they send packets that can be detected by Intrusion Detection Systems (IDS). Kismet is completely passive. It puts the card in listening mode and logs everything without transmitting a single byte.

**The "Ghost" Audit:**

- Use Kismet to map your facility from the outside.
    
- If you can see your internal network from the street using Kismet, your signal strength is too high (Bleeding Signal).
    
- **Hardening Action:** Lower the Transmit Power (Tx Power) on your router until the signal dies at your physical perimeter.
    

**Key Command:**

```
sudo kismet -c wlan0mon

```

_(Access the UI at `http://localhost:2501` in your browser while it runs)._

## 3. Pixiewps (The Speed Force)

Why you need it:

You installed reaver and bully to audit WPS.

- **Standard Reaver:** Brute forces the PIN (11,000 guesses). Time: 4-10 Hours.
    
- **Pixie Dust (Pixiewps):** Exploits the entropy (randomness) of the router's random number generator. Time: **< 30 Seconds**.
    

Integration:

You typically don't run pixiewps manually. wifite and reaver will automatically detect if it is installed and use it to instant-crack vulnerable routers.

- **Hardening Action:** If `pixiewps` works on your router, a standard firmware update often won't fix it. You MUST disable WPS entirely.
    

## 4. MDK4 (Stress Testing / Denial of Service)

Why you need it:

Hardening isn't just about passwords; it's about availability. MDK4 tests if your router can withstand "Beacon Flooding" or "Authentication Flooding".

The Test (Beacon Flood):

This creates thousands of "fake" WiFi networks with random names.

```
# Flood the airwaves with fake APs (BE CAREFUL - This disrupts local WiFi)
sudo mdk4 wlan0mon b

```

- **Diagnostic:** If your legitimate devices disconnect or can no longer find your real network amidst the noise, your router struggles with signal-to-noise ratio handling.
    
- **Hardening:** Enable "Management Frame Protection" (802.11w) and look for routers with "Airtime Fairness" features.
    

## Summary of the Full Stack

| Tool | Category | Primary Function |

| Aircrack-ng | Suite | The base engine for capture and cracking. |

| Reaver / Bully | WPS | Attacks the 8-digit PIN mechanism. |

| Pixiewps | WPS | Drastically speeds up WPS attacks (offline). |

| Wifite | Automation | "Lazy" script that runs all attacks in sequence. |

| Bettercap | Modern | Real-time analysis, UI, and surgical attacks. |

| Kismet | Passive | Invisible mapping and signal leakage detection. |

| Hashcat | Cracking | The fastest GPU-based password cracker. |

| MDK4 | Stress | Testing router stability under load. |