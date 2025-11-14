
# Connect to Wi-Fi with `connmanctl`

This guide details the process of establishing a wireless internet connection using `connman`, the ConnMan connection manager. This is an essential step for accessing online repositories during the Arch Linux installation.

### Step 1: Start the Connman Service

First, ensure the `connman` service is running.

```bash
systemctl start connman.service
```

> [!TIP]
> To have ConnMan manage your network automatically on future boots, you can enable the service:
> ```bash
> systemctl enable connman.service
> ```

### Step 2: Launch the `connmanctl` Interactive Shell

Enter the `connmanctl` interactive prompt to manage network connections.

```bash
connmanctl
```

Your command prompt will change to `connmanctl>`, indicating you are inside the utility.

### Step 3: Scan for and List Networks

From the interactive shell, perform the following actions to find your network.

1.  **Enable the Wi-Fi adapter:**
    ```bash
    connmanctl> enable wifi
    ```

2.  **Scan for available networks:**
    ```bash
    connmanctl> scan wifi
    ```

3.  **List the results:**
    ```bash
    connmanctl> services
    ```
    This command displays a list of detected networks. The output will look something like this:
    ```
    *AO MyNetwork           wifi_dc85de81e15a_4d794e6574776f726b_managed_psk
        OtherNet            wifi_dc85de81e15a_4f746865724e6574_managed_psk
    ```

> [!WARNING]
> To connect, you must use the long `service_id` string (e.g., `wifi_dc85de81e15a_...`), not the human-readable SSID (e.g., `MyNetwork`).

### Step 4: Connect to the Network

1.  **Enable the agent** to handle password prompts:
    ```bash
    connmanctl> agent on
    ```

2.  **Initiate the connection** using the `service_id` you identified in the previous step:
    ```bash
    connmanctl> connect <service_id>
    ```
    **Example:**
    ```bash
    connmanctl> connect wifi_dc85de81e15a_4d794e6574776f726b_managed_psk
    ```
    You will be prompted to enter the Wi-Fi password.

### Step 5: Verify and Exit

1.  **Check the connection state:**
    ```bash
    connmanctl> state
    ```
    Look for `State = online` to confirm a successful connection.

2.  **Exit the interactive shell:**
    ```bash
    connmanctl> quit
    ```

### Step 6: Test Internet Connectivity

Finally, ping a reliable server to ensure you have a working internet connection.

```bash
ping -c 3 archlinux.org
```

> [!SUCCESS]
> If you receive replies, your internet connection is configured correctly and you can proceed with the installation.

