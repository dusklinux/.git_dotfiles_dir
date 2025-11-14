### Managing Swap on a Running System

These commands are for managing swap after you have booted into your installed Arch Linux system.

#### Checking Swap Status

To verify that your swap is active and see its usage, you can use one of two commands:

*   **List active swap devices:**
    ```bash
    swapon --show
    ```
    **Example Output:**

| NAME | TYPE | SIZE | USED | PRIO |
|---|---|---|---|---|
| /dev/sda3 | partition | 8G | 0B | -2 |

*   **View total memory and swap usage:**
    ```bash
    free -h
    ```
    **Example Output:**

| total | used | free | shared | buff/cache | available |
|---|---|---|---|---|---|---|
| Mem: | 15Gi | 2.1Gi | 8.2Gi | 123Mi | 5.1Gi | 12Gi |
| Swap: | 8.0Gi | 0B | 8.0Gi | | | |

#### Temporarily Activating/Deactivating Swap

You can manually enable or disable swap spaces for the current session without rebooting.

*   **To activate a specific swap partition:**
    ```bash
    sudo swapon /dev/sdXN
    ```

*   **To deactivate a specific swap partition:**
    ```bash
    sudo swapoff /dev/sdXN
    ```

*   **To deactivate all active swap spaces:**
    ```bash
    sudo swapoff -a
    ```

#### Permanently Disabling Swap

To prevent a swap partition from being activated at boot, you must perform two actions:

1.  **Remove the entry from `/etc/fstab`:** Edit `/etc/fstab` and delete or comment out (by adding a `#` at the beginning) the line corresponding to your swap partition.
2.  **Mask the systemd unit (optional but recommended):** This prevents `systemd` from auto-detecting and activating the swap partition in some cases.
    *   First, find the corresponding `.swap` unit:
        ```bash
        systemctl --type swap
        ```
    *   Then, mask the unit found in the previous command:
        ```bash
        sudo systemctl mask dev-sda3.swap
        ```
        *(Replace `dev-sda3.swap` with the actual unit name.)*
