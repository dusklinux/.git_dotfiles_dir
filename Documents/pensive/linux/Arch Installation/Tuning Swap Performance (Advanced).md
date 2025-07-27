### Tuning Swap Performance (Advanced)

You can adjust kernel parameters to control how and when the system uses swap.

#### Swappiness

The `vm.swappiness` parameter controls the kernel's preference for swapping memory pages versus dropping file-system cache.
*   **Value:** `0` to `200` (default is `60`).
*   **Low Value (e.g., 10):** The kernel will strongly prefer to drop file cache instead of swapping out application memory. Good for desktops and systems with fast I/O.
*   **High Value (e.g., 200):** The kernel will be more aggressive in swapping application memory to disk.

1.  **Check the current value:**
    ```bash
    sysctl vm.swappiness
    ```

2.  **Set the value temporarily (resets on reboot):**
    ```bash
    sudo sysctl -w vm.swappiness=35
    ```

3.  **Set the value permanently:** Create a configuration file.
    ```bash
    sudo nano /etc/sysctl.d/99-swappiness.conf
    ```
    Add the following content to the file:
    ```
    vm.swappiness=35
    ```

#### Swap Priority

If you use multiple swap devices (e.g., ZRAM and a disk partition), you can assign a priority to each. The system will always use the device with the higher priority first.
*   **Value:** `-1` to `32767`. Higher numbers mean higher priority.

To set priority, add the `pri=<value>` option in `/etc/fstab`.

**Example for a ZRAM + Disk Swap setup:**
```
# /etc/fstab
# Give ZRAM high priority for performance
/dev/zram0                               none      swap      defaults,pri=100   0 0
# Give disk swap low priority for fallback/hibernation
UUID=a1b2c3d4-e5f6-7890-abcd-1234567890ef none      swap      defaults,pri=10    0 0
```
This configuration ensures the system fills the fast ZRAM device before ever touching the slower disk swap, giving you the best of both worlds.