Of course. Here is a revised and enhanced version of your guide for setting up a Wi-Fi hotspot on Arch Linux, formatted for clarity and aesthetic appeal within Obsidian.

***

# Creating a Wi-Fi Hotspot with NetworkManager

This guide provides a comprehensive, step-by-step walkthrough for creating, managing, and troubleshooting a Wi-Fi hotspot on Arch Linux using `NetworkManager`'s command-line tool, `nmcli`.

> [!NOTE] Prerequisite: NetworkManager
> This guide assumes you are using `NetworkManager` to manage your network connections. If it's not active, you may need to enable and start the service first.
> ```bash
> sudo systemctl enable --now NetworkManager.service
> ```

---

## Phase 1: Pre-flight Checks

Before creating the hotspot, you must verify that your hardware is capable and identify the correct network interfaces to use.

### Step 1: Verify Wi-Fi Card Support

First, confirm that your wireless card supports **Access Point (AP)** mode. Most modern cards do.

Run the following command to inspect your Wi-Fi card's capabilities:
```bash
iw list
```
In the output, look for the `Supported interface modes` section. You must see `AP` listed.

```plaintext
Supported interface modes:
     * IBSS
     * managed
     * AP  <-- THIS IS WHAT YOU NEED
     * AP/VLAN
     * monitor
     * P2P-client
     * P2P-GO
```
> [!SUCCESS]
> If `AP` is present, your hardware is ready. If not, your Wi-Fi card does not support hosting a hotspot.

### Step 2: Identify Your Network Interfaces

You need to know the names of two interfaces:
1.  **The Wi-Fi Interface:** The device that will broadcast the hotspot (e.g., `wlo1`).
2.  **The Internet Source:** The device that is connected to the internet (e.g., `eth0` for wired, or another Wi-Fi card).

Use `nmcli` to list all network devices and their status.
```bash
nmcli device
```
Alternatively, `ip a` provides a more detailed view.
```bash
ip a
```
> [!TIP]
> Note the name of your primary Wi-Fi interface from the `DEVICE` column (e.g., `wlo1`, `wlan0`, `wlp3s0`). You will need it for the next step.

---

## Phase 2: Hotspot Creation & Management

Once the prerequisites are met, you can create and manage the hotspot with a few simple commands.

### Step 3: Create the Hotspot

You can create and activate the hotspot with a single `nmcli` command. This command automatically creates a new `NetworkManager` connection profile and shares your existing internet connection.

**Command Template:**
```bash
nmcli device wifi hotspot ifname <WIFI_INTERFACE> ssid "<HOTSPOT_NAME>" password "<PASSWORD>"
```

**Example:**
Here, we create a hotspot named "MyArchHotspot" with the password "supersecretpassword" on the `wlo1` interface.

```bash
nmcli device wifi hotspot ifname wlo1 ssid "MyArchHotspot" password "supersecretpassword"
```

**Command Breakdown:**

| Parameter | Description |
| :--- | :--- |
| `ifname wlo1` | Specifies the Wi-Fi device that will broadcast the hotspot. |
| `ssid "MyArchHotspot"` | Sets the public name (SSID) of your new Wi-Fi network. |
| `password "..."` | Sets the password for your hotspot. It must be at least 8 characters long. |

> [!SUCCESS]
> Upon success, the command will print `Device '<WIFI_INTERFACE>' successfully activated with '<UUID>'`. Your hotspot is now live and broadcasting.

### Step 4: Managing the Hotspot

After creation, the hotspot exists as a saved `NetworkManager` profile. You can easily turn it on or off without re-entering the details.

#### Toggling the Hotspot On & Off

1.  **Find the connection name.** It is usually the same as your SSID.
    ```bash
    nmcli connection show
    ```

2.  **Turn the hotspot OFF.**
    ```bash
    nmcli connection down "MyArchHotspot"
    ```

3.  **Turn the hotspot ON** again at any time.
    ```bash
    nmcli connection up "MyArchHotspot"
    ```

#### Viewing the Hotspot Password

If you forget the password you set, you can retrieve it with this command:
```bash
nmcli device wifi show-password
```

#### Permanently Deleting the Hotspot

If you no longer need the hotspot profile, you can delete it completely.

> [!WARNING]
> This action is irreversible. You will have to recreate the hotspot from Step 3 if you need it again.

```bash
nmcli connection delete "MyArchHotspot"
```
