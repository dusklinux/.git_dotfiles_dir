This note is my documentation: 

official documentation [[WiFi Security Testing Official]]

[[Gemini  guide]]

Monitor Mode: Normally, your Wi-Fi card only listens to traffic addressed specifically to it. To see all the Wi-Fi traffic in the air around you, including data not meant for you, the card must be put into a special "monitor mode."

The Handshake: For WPA2, the critical piece of data is the 4-Way Handshake. This is a four-packet exchange that happens every time a device connects to the router. This handshake proves the device knows the password without ever sending the password itself. We can capture this handshake and then try to crack it offline.

Dictionary Attack: This is the most common method. We take the captured handshake and use a program (aircrack-ng) to try and replicate it with every password from a long list (a "dictionary" or "wordlist"). If our guess generates the same handshake, we've found the password. The attack's success depends entirely on the password being in your wordlist.

tools to be used `airmon-ng, airodump-ng, aireplay-ng, aircrack-ng` `--help` to see all commands or `man` followed by the tool name to see it's manual

2.4 GHz band channels `1, 6, 11`

5 GHz band Channels `36, 40, 44, 48, 52, 56, 60, 64, 100, 104, 108, 112, 116, 120, 124, 128, 132, 136, 140, 144, 149, 153, 157, 161, 165`

1. ### Packages required

```bash
sudo pacman -S --needed reaver bully
```

```bash
paru -S --needed aircrack-ng-git
```

or

```bash
sudo pacman -S --needed aircrack-ng
```

2. THEN CHECK THE SECURITY IE WPA2/WPA3, BSSID, CHANNEL, SIGNAL, SSID

```bash
nmcli device wifi list
```

for gui, install this 
```bash
sudo pacman -S --needed reaver bully john wireshark-cli wifite hcxtools hcxdumptool cowpatty macchanger hashcat
```

```bash
paru -S pyrit
```

and then run 

```bash
sudo wifite --kill
```

---
---

1. Identify your wireless card and put it into monitor mode.

Identify your interface:

```bash
iw dev
```

This command will list your wireless devices. Look for an interface name, typically something like wlan0

Check if your wifi card supports monitor mode 

```bash
iw list
```

> [!NOTE]- it'll list a LOT OF INFO, BUT CHECK the `supported interface modes` section. 
> Supported interface modes:
> 		* IBSS
> 		* managed
> 		* AP
> 		* AP/VLAN
> 		* monitor
> 		* P2P-client
> 		* P2P-GO
> 		* P2P-device

---

2. Check for conflicts

The aircrack-ng suite works best when network managers aren't trying to control the wireless card simultaneously. It's a good practice to check for and stop conflicting processes.

```bash
sudo airmon-ng check kill
```

This will stop services like NetworkManager and wpa_supplicant. Don't worry, we'll restart them later.

---

3. Start Monitor Mode: Now, enable monitor mode on your interface.

```bash
sudo airmon-ng start wlan0
```

(Replace wlan0 with your actual interface name). 

This command will create a new virtual interface, usually named `wlan0mon` (as in `wlan0` - `mon`itor), which is now in monitor mode.

check the name with 

```bash
iwconfig
```

---

4. Scan for Networks

Use airodump-ng to see all the wireless networks in your vicinity. This will help you find the MAC address (BSSID) and channel of your network.

you have to use the `--band` flag for 5 GHz only (band a) or 2.4 GHz only (band b) or you can also do a specific channel number with `--channel`
or you can filter it by  `--bssid`  you can also pass multiple --bssid options

default
```bash
sudo airodump-ng wlan0mon
```

for 2.4 GHz only (band b)
```bash
sudo airodump-ng --band b wlan0mon
```

for 5 GHz only (band a) not sure if my card supports this. 
```bash
sudo airodump-ng --band a wlan0mon
```

> [!NOTE]- You'll see a table that updates in real-time. Here’s what the columns mean:
> BSSID: The MAC address of the Access Point (AP). This is its unique hardware identifier.
> 
> PWR: The signal power. Higher negative numbers (e.g., -30) are stronger than lower ones (e.g., -80).
> 
> CH: The channel the network is operating on (1-14 for 2.4GHz, 36+ for 5GHz).
> 
> ENC: The encryption standard used. You'll see WPA2, WPA3, etc.
> 
> AUTH: The authentication protocol. For home networks, this is usually PSK (Pre-Shared Key). and SAE for Phone hotspots
> 
> ESSID: The public name of the Wi-Fi network (e.g., "MyHomeWiFi").

Press Ctrl+C to stop scanning once you've identified your network's BSSID and CH.

---

5. The WPA2 Handshake Attack: Capture the Handshake

This is the classic attack against WPA2-PSK networks. It will not work against a network in WPA3-only mode.
Now, focus airodump-ng on your specific network to capture the crucial 4-way handshake.
`<BSSID>: The MAC address of the router ie access point.`
`<CHANNEL>: The channel the router is on.`

```bash
sudo airodump-ng --bssid <BSSID> --channel <CHANNEL> --write path/to/handshakecapture wlan0mon
```

> [!NOTE]- Explination of the command
> --bssid: Tells airodump-ng to only listen to this specific access point.
> 
> --channel: Sets your card to listen on the correct channel, which is crucial.
> 
> --write path/to/handshakecapture This tells airodump-ng to save the captured packets into files prefixed with handshakecapture. The most important one will be handshapkecapture-01.cap

Let this run. In the top right corner, you'll see a message "`WPA handshake: BSSID ...`" once it's captured successfully. It'll also say `EAPOL` under `Notes` To get a handshake, a device must connect to the network. If no devices are connecting, you can force one to reconnect.

---

6. (Optional) Force a Deauthentication

If you're waiting too long for a handshake, you can speed up the process by using aireplay-ng to kick a device off the network. The device will then automatically try to reconnect, creating the handshake you need to capture.

First, in the airodump-ng window from Step 5, look at the bottom section. It lists connected clients ("STATION"). Pick the MAC address of a device that's connected to the network.

```bash
# -a is the AP, -c is the client to kick
sudo aireplay-ng --deauth 5 -a <BSSID> -c <CLIENT_MAC> wlan0mon
```

> [!NOTE]- Explanation of the command
> --deauth 5: Sends 5 deauthentication packets. This is usually enough.
> 
> -a <BSSID>: Specifies the target access point.
> 
> -c <CLIENT_MAC>: Specifies the client device to disconnect.

Switch back to your airodump-ng window. You should see the "WPA handshake: < BSSID>" message appear almost immediately. You can now press Ctrl+C in both terminals. You should have a .cap file containing the handshake.

---

7. Crack the Password

This is where the actual cracking happens. You need a wordlist for this. A famous one is rockyou.txt, but for a strong password, you'd likely need to create a custom, more powerful wordlist. On many security-focused Linux distros, you can find rockyou.txt in /usr/share/wordlists/. If not, you can find it online (e.g., in the SecLists collection on GitHub).

```bash
aircrack-ng -w /path/to/your/wordlist.txt handshakecapture-01.cap
```

> [!NOTE]- Explanation of the command
> -w /path/to/your/wordlist.txt: Specifies the dictionary file.
> 
> handshakecapture-01.cap: The capture file containing the handshake.

Aircrack-ng will now test every password in the list. If the password is in the wordlist, it will display "KEY FOUND! [ password ]". If it runs through the whole list and finds nothing, your password is not in that wordlist, and the attack has failed.

Security Lesson: The strength of your WPA2 password is its length and complexity relative to the attacker's wordlist. A long, random password not found in any standard dictionary makes this attack computationally infeasible.

---

## Testing WPA3 and Transition Mode

As mentioned, you cannot perform the offline dictionary attack above against a network running purely in WPA3 mode. However, many routers run in a WPA2/WPA3 transition mode to support older devices. This is a potential weakness.

An attacker can perform a downgrade attack. They can specifically jam the WPA3 authentication process, forcing a WPA3-capable client to fall back and connect using the more vulnerable WPA2 protocol. Once the client connects via WPA2, the attacker can use the exact same handshake capture and cracking method described in steps 5 through 7.

How to Test for This:
- Look at the airodump-ng output from Step 4.
- Find your network's row. In the ENC column, if it says `WPA2 WPA3`, your network is in transition mode and is vulnerable to a downgrade attack.

> [!NOTE]- The Fix
> Go into your router's administration page and change the Wi-Fi security setting from "WPA2/WPA3-Personal" to "WPA3-Personal" only. Be aware that any older devices in your home that do not support WPA3 will no longer be able to connect.

---

## Testing WPS (Wi-Fi Protected Setup)

WPS is a feature designed for convenience, but its initial design contained a major security flaw that is still exploitable on many older or unpatched routers.

The Flaw: A WPS PIN is 8 digits. Brute-forcing 108 (100 million) combinations would take too long. However, the PIN is validated in two halves: the first 4 digits, and then the next 3. The 8th digit is a checksum. This reduces the number of possibilities to 104+103=11,000, which is very easy to brute-force.

1. Scan for WPS-Enabled Networks

Use the wash tool to see which nearby networks have WPS enabled.

```bash
sudo wash -i wlan0mon
```

Look for your network in the list. If the WPS Locked column says No, it may be vulnerable. If it says Yes, the router has a brute-force protection mechanism that will lock WPS after a few failed attempts, making this attack much harder.

2. The WPS PIN Attack

The classic tool for this is reaver, but a more modern and often more effective fork is bully.

```bash
sudo bully wlan0mon -b <YOUR_BSSID> -c <YOUR_CHANNEL> -v
```

> [!NOTE]- Explanation of the command
> -b <YOUR_BSSID>: Your router's MAC address.
> 
> -c <YOUR_CHANNEL>: Your router's channel.
> 
> -v: Verbose mode, to see the progress.

Bully will begin trying every possible PIN. This can take several hours, but if it succeeds, it will recover the 8-digit WPS PIN. With the PIN, it can then recover your actual WPA2 Wi-Fi password, regardless of its length or complexity.

> [!NOTE]- The Fix
> This is the easiest fix of all. Log in to your router's administration page and disable WPS entirely. It's an outdated feature with significant security risks.

## Cleanup and Final Security Recommendations 🛡️

Once you are done testing, you need to return your system to normal.

Stop Monitor Mode:

```bash
sudo airmon-ng stop wlan0mon
```

Restart Network Services:

```bash
sudo systemctl restart NetworkManager.service
```

Your Wi-Fi should now connect and work as usual.


Your Security Checklist:

✅ Use WPA3-Only Mode: If all your devices support it, use WPA3-only mode. This is the single most effective defense against the attacks described here.

✅ Create a Strong Passphrase: If you must use WPA2, use a password that is at least 20 characters long and is a random mix of upper/lowercase letters, numbers, and symbols. A passphrase like Correct-Horse-Battery-Staple-!9*k is far stronger than P@ssword123.

✅ Disable WPS: Turn it off in your router settings. Period.

✅ Update Router Firmware: Check for and install firmware updates for your router regularly. These often contain important security patches.

✅ Change Admin Credentials: Change the default username and password (admin/password) for your router's settings page.

Make sure your wifi network is Stong! 