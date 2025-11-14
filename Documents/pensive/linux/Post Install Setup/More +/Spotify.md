# Installing & Patching Spotify on Arch Linux

This guide outlines the process for installing the Spotify client on an Arch Linux system using an AUR helper and applying the SpotX patch to enhance its functionality.

> [!NOTE] Prerequisite: AUR Helper
> This guide assumes you have an AUR (Arch User Repository) helper installed, such as `paru` or `yay`. If you do not have one, please refer to the [[Installing an AUR Helper]] guide first.

---

### Step 1: Install the Spotify Client

The first step is to install the official Spotify client from the Arch User Repository. We will use `paru` for this example, but you can substitute it with your preferred AUR helper.

```bash
paru -S spotify
```

This command searches the AUR for the `spotify` package, resolves its dependencies, and builds and installs it on your system.

---

### Step 2: Apply the SpotX Patch

Once Spotify is installed, you can apply the **SpotX** patch. This is a popular community script that modifies the client to block audio, video, and banner ads, and may unlock other minor features.

This command only needs to be run once.

> [!WARNING] Security Advisory: Executing Remote Scripts
> The following command downloads a shell script from the internet and executes it directly with `bash`. While SpotX is a well-known project, you should always exercise caution. It is best practice to first inspect the script's contents before running it.
> You can view the script here: `https://spotx-official.github.io/run.sh`

To proceed with the patch, run the following command in your terminal:

```bash
bash <(curl -sSL https://spotx-official.github.io/run.sh)
```

After the script completes, your Spotify installation will be patched. You can now launch Spotify and enjoy the ad-free experience.

### Command Summary

For quick reference, here is a summary of the commands used in this guide.

| Step | Command | Description |
| :--- | :--- | :--- |
| 1. Install | `paru -S spotify` | Installs the official Spotify client from the AUR. |
| 2. Patch | `bash <(curl -sSL https://spotx-official.github.io/run.sh)` | Downloads and applies the SpotX patch to block ads. |

