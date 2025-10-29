
Before installing the base system, it's crucial to configure the pacman mirror list. This ensures that you download packages from the fastest and most up-to-date servers available, significantly speeding up the installation process. The `reflector` utility, which is included in the live installation environment, automates this process.

> [!TIP] Why Synchronize Mirrors?
> An optimized mirror list points your package manager (`pacman`) to the geographically closest and best-performing servers. This minimizes download times and reduces the chance of encountering outdated or unavailable packages.

## Automated Mirror Selection with `reflector`

The following command uses `reflector` to find the 20 most recently synchronized mirrors in India, sort them by download speed, and save the result to the official mirror list file.

1.  **Run the `reflector` command:**

    ```bash
    reflector --country India --age 24 --sort rate --save /etc/pacman.d/mirrorlist
    ```

2.  **Understanding the Command:**
    The flags used in this command customize the mirror selection process:

| Flag | Description |
| :--- | :--- |
| `--country India` | Restricts the server search to mirrors located in India. You can change this to your country for better performance. |
| `--age 24` | Selects only mirrors that have been synchronized within the last 24 hours, ensuring they are up-to-date. |
| `--sort rate` | Sorts the filtered mirrors by their download speed, placing the fastest ones at the top of the list. |
| `--save <path>` | Overwrites the specified file with the new list of mirrors. |

## Optional: Verify the Mirror List

After `reflector` finishes, you can inspect the new mirror list to ensure it was generated correctly.

1.  **Open the mirror list file:**

    ```bash
    vim /etc/pacman.d/mirrorlist
    ```

    > [!NOTE]
    > You should see a list of servers, commented with their location (which should be India, based on the command above) and sorted with the fastest mirrors at the top.
