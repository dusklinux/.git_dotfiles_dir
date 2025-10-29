
This guide details a method for forcing **all** Vulkan-based applications within your user session to use a specific GPU. While the per-application `systemd` override described in [[SwayNC Nvidia fix]] offers surgical precision, this system-wide approach acts as a global switch, perfect for scenarios where maximizing power efficiency is the top priority.

> [!NOTE] The Core Concept: `VK_ICD_FILENAMES`
> This entire method hinges on setting the `VK_ICD_FILENAMES` environment variable. This variable tells the Vulkan loader—the part of your system responsible for finding graphics drivers—exactly which driver to use. By pointing it exclusively to the integrated GPU's driver file (the "ICD" file), we effectively make the discrete GPU invisible to all Vulkan applications.

---

## When to Use This Method

This is a powerful but blunt instrument. It's ideal for:
*   **Maximum Battery Life:** Forcing the iGPU prevents the power-hungry dGPU from ever activating, significantly extending battery life during work or travel.
*   **Reducing Heat and Noise:** Keeping the dGPU idle is the best way to keep your laptop cool and quiet.

> [!WARNING] 
>
> *   **No dGPU Access:** You will **lose all access** to your NVIDIA discrete GPU for Vulkan applications. This includes games, rendering software, and scientific computing tasks.
> *   **PRIME Render Offload Disabled:** Commands like `prime-run` or `__NV_PRIME_RENDER_OFFLOAD=1` will **no longer work** because the system will be unable to find the NVIDIA Vulkan driver.
>
> This is a temporary "mode" for power saving, not a permanent configuration.

---

## Step-by-Step Guide

### Step 1: Identify Your GPU's ICD File

Before you can force a GPU, you need to know the exact path to its driver file. These are typically located in `/usr/share/vulkan/icd.d/`.

1.  **List the available ICD files** on your system with this command:
    ```bash
    ls /usr/share/vulkan/icd.d/
    ```

2.  **Identify the correct file.** The output will show JSON files corresponding to your installed drivers. You are looking for your **integrated GPU's** file.
    *   **Intel iGPU:** `intel_icd.x86_64.json`
    *   **AMD iGPU:** `amd_icd.x86_64.json`
    *   **NVIDIA dGPU:** `nvidia_icd.json`
    * *Intel iGPU (outdated/old)*: `intel_hasvk_icd.x86_64.json`

> [!TIP] For this guide, we will use the Intel iGPU file as the example. If you have an AMD iGPU, simply substitute the correct filename in the following steps.

### Step 2: Set the Environment Variable

The method for setting the environment variable depends on how you launch your Wayland session. Choose the method that matches your setup.

#### Method A: For UWSM Users (Recommended)

The **Universal Wayland Session Manager (UWSM)** provides a dedicated file for session-wide environment variables.

1.  Open the UWSM environment file with a text editor:
    ```bash
    nvim ~/.config/uwsm/env
    ```

2.  Add the following line to the file. The comments are highly recommended to remind you of this setting's purpose.
    ```bash
    # --- VULKAN ICD LOADER OVERRIDE ---
    # Forces all Vulkan applications to use the Intel iGPU for max power saving.
    # WARNING: This breaks PRIME render offload for the NVIDIA dGPU.
    # To disable, comment out this line and log out/in.
    export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/intel_icd.x86_64.json
    ```

#### Method B: For Hyprland Config Users

If you launch Hyprland directly without UWSM, you should set the variable inside your `hyprland.conf`.

1.  Open your Hyprland configuration file:
    ```bash
    nvim ~/.config/hypr/hyprland.conf
    ```

2.  Add the following line, preferably near the top with other environment variables. Note the different syntax.
    ```ini
    # --- VULKAN ICD LOADER OVERRIDE ---
    # Forces all Vulkan applications to use the Intel iGPU for max power saving.
    # WARNING: This breaks PRIME render offload for the NVIDIA dGPU.
    # To disable, comment out this line and reload Hyprland.
    env = VK_ICD_FILENAMES,/usr/share/vulkan/icd.d/intel_icd.x86_64.json
    ```

### Step 3: Apply the Changes

For the new environment variable to take effect across your entire session, you must **log out and log back in**. A full reboot will also work.

### Step 4: Verify the Override (Optional but Recommended)

To confirm the override is active:
1.  Open a terminal and run a Vulkan application, for example `vulkaninfo`.
2.  In a separate terminal, check the NVIDIA GPU status:
    ```bash
    nvidia-smi
    ```
> [!SUCCESS] Verification
> If the override is working, `vulkaninfo` should run successfully (showing details of your Intel/AMD GPU), and the process list in `nvidia-smi` should be **empty**. This proves the dGPU is idle.

---

## Summary: Per-App vs. System-Wide

| Method | Pros | Cons |
| :--- | :--- | :--- |
| **Systemd Override** (Per-App) | ✅ Surgical precision, targets one app<br>✅ Preserves dGPU for other tasks | ❌ Requires a separate file for each app |
| **Environment Variable** (System-Wide) | ✅ Simple, single-line toggle<br>✅ Guarantees maximum power savings | ❌ Disables dGPU for everything<br>❌ Requires logout to enable/disable |

---

## How to Revert the System-Wide Change

Reverting this change is as simple as applying it.

1.  **Edit the same file** you modified in Step 2 (e.g., `~/.config/uwsm/env` or `~/.config/hypr/hyprland.conf`).
2.  **Comment out or delete** the line you added. Adding a `#` at the beginning of the line is the safest way to disable it.

    **For UWSM:**
    ```bash
    # export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/intel_icd.x86_64.json
    ```

    **For Hyprland:**
    ```ini
    # env = VK_ICD_FILENAMES,/usr/share/vulkan/icd.d/intel_icd.x86_64.json
    ```

3.  **Save the file** and **log out and back in**. Your system will return to its normal hybrid graphics behavior, and PRIME render offload will function again.

