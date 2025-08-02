
`Reflector` is a script that automates the process of selecting the fastest and most up-to-date Arch Linux package mirrors. A well-configured mirrorlist is crucial for fast and reliable package management with `pacman`.

> [!NOTE] Execution Environment
> These commands should be executed from within the `chroot` environment, as indicated by step #21 in your [[+ MOC Arch Linux Installation]].

---

### 1. Install Reflector

First, install the `reflector` package using `pacman`.

```bash
pacman -S --needed reflector
```

### 2. Configure and Run Reflector

You have two primary methods for updating your mirrorlist: a one-time manual run (ideal during installation) or setting up an automated service (recommended for long-term maintenance).

#### Method A: Manual One-Time Update

This is the simplest approach for the initial system setup. The command fetches a new list of mirrors based on the flags provided and saves it directly.

1.  **Run the `reflector` command:**

    ```bash
    reflector --country India --age 24 --sort rate --save /etc/pacman.d/mirrorlist
    ```

2.  **Understanding the Flags:**

| Flag | Description |
| :--- | :--- |
| `--country India` | Restricts the mirror selection to servers located in India. |
| `--age 24` | Filters for mirrors that have been synchronized within the last 24 hours. |
| `--sort rate` | Sorts the selected mirrors by their download speed, placing the fastest ones at the top. |
| `--save <path>` | Saves the generated list to the specified file, overwriting the existing one. |

> [!TIP] Finding Country Codes
> To use mirrors from other countries, you can list all available locations with the command:
> ```bash
> reflector --list-countries
> ```

#### Method B: Automated Updates via a Service (Recommended)

This method configures `reflector` to run automatically, ensuring your mirrorlist stays optimized over time.

1.  **Edit the Configuration File:**
    Open the default `reflector` configuration file.

    ```bash
    nvim /etc/xdg/reflector/reflector.conf
    ```

2.  **Set Your Preferred Options:**
    Uncomment and modify the lines to match your requirements. For consistency with your manual command, you would set it up as follows:

    ```ini
    #
    # Reflector configuration file for the reflector service.
    #
    # See "reflector --help" for details.
    #

    # Save the mirrorlist to this file.
    --save /etc/pacman.d/mirrorlist

    # Select mirrors synchronized within the last 24 hours.
    --age 24

    # Sort the mirrors by download speed.
    --sort rate

    # Select mirrors from India.
    --country India
    ```

3.  **Enable the Systemd Timer:**
    The `reflector` package includes a systemd timer that will run the service weekly. This is the preferred way to keep your mirrors updated without running `reflector` on every single network change.

    ```bash
    systemctl enable reflector.timer
    ```

### 3. Verify the New Mirrorlist

After running `reflector` (either manually or by starting the service), you should inspect the new mirrorlist to ensure it was generated correctly.

```bash
cat /etc/pacman.d/mirrorlist
```

You should see a list of servers, primarily from your selected country (`India`), with the fastest mirrors at the top.

> [!WARNING] Synchronize Pacman
> After updating your mirrorlist, it's a good practice to force-synchronize `pacman`'s package databases, especially if the previous list was very outdated.
> ```bash
> pacman -Syyu
> ```

