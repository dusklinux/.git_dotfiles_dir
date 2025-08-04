

`NetworkManager` is a powerful service that provides automatic detection and configuration for network devices. This guide covers the essential commands for managing your network connections using its command-line interface, `nmcli`.

## Initial Setup: Enabling the Service

Before you can use `NetworkManager`, you must enable its systemd service to start on boot and then start it for the current session.

1.  **Enable the service to start automatically on boot:**

```bash
sudo systemctl enable NetworkManager.service
```

2.  **Start the service immediately:**

```bash
sudo systemctl start NetworkManager.service
```


> [!TIP] Enable and Start in One Go
> You can combine both steps into a single command using the `--now` flag:
> ```bash
> sudo systemctl enable --now NetworkManager.service
> ```

> [!note] Disable this service, it's uncecessory 
> ```
> sudo systemctl disable NetworkManager-wait-online.service
> ```

## Connecting to a Wi-Fi Network

Follow these steps to connect to a wireless network for the first time.

| Step | Command | Description |
| :--- | :--- | :--- |
| 1. **List Devices** | `nmcli device` | Shows all available network interfaces (e.g., `wlo1` for Wi-Fi, `eno1` for Ethernet). |
| 2. **Scan for Networks** | `nmcli device wifi list` | Scans for and lists all visible Wi-Fi networks, along with their signal strength and security type. |
| 3. **Connect** | `nmcli dev wifi connect <SSID> --ask` | Connects to the specified network SSID. The `--ask` flag will securely prompt you for the password. |

> [!NOTE] Alternative Connection Command
> You can also provide the password directly in the command, but be aware that it will be visible in your shell history.
> ```bash
> nmcli device wifi connect <YOUR_WIFI_SSID> password <YOUR_WIFI_PASSWORD>
> ```

## Managing Saved Connections

Once you have connected to a network, `NetworkManager` saves it as a profile. You can use the following commands to manage these profiles.

| Action | Command | Description |
| :--- | :--- | :--- |
| **Show Connections** | `nmcli connection show` | Lists all saved connection profiles, highlighting the currently active ones. |
| **Connect to Saved** | `nmcli connection up "<SSID>"` | Activates a previously saved connection profile. Use the name from the `NAME` column. |
| **Disconnect** | `nmcli connection down "<SSID>"` | Deactivates a connection. |
| **Delete Saved** | `nmcli connection delete "<SSID>"` | Removes a saved connection profile from `NetworkManager`. |

> [!WARNING]
> When using commands that reference a connection by its name or SSID, make sure to enclose it in quotes (e.g., `"My Home WiFi"`) if it contains spaces or special characters.

