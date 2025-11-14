
# Mastering Kernel Modules on Arch Linux

This guide provides a comprehensive overview of managing Linux kernel modules on Arch Linux. Understanding these commands is a foundational skill for any system administrator, allowing for effective hardware management, driver installation, and system troubleshooting.

> [!INFO] What are Kernel Modules?
> Think of the Linux kernel as a core engine. By itself, it's powerful but limited. **Kernel Modules** are like optional, high-performance components (e.g., drivers for your GPU, Wi-Fi card, USB devices, or support for new filesystems) that can be loaded into or unloaded from the running kernel on demand. This modular approach keeps the core kernel lean and allows for immense flexibility.

---

## Part 1: Inspecting Loaded Modules

Before making any changes, it's crucial to see what's currently running.

### `lsmod`: The Kernel's Roll Call 🧾

The `lsmod` command provides a snapshot of all kernel modules currently loaded into memory. It's your primary tool for verifying which drivers are active.

```bash
# List all currently loaded kernel modules
lsmod

# Filter the list to check for a specific module (e.g., the Intel Wireless driver)
lsmod | grep iwlwifi

# Filter for the NVIDIA driver
lsmod | grep nvidia
```

#### How It Works
`lsmod` doesn't perform complex operations. It simply reads and formats the information from the virtual file `/proc/modules`, which is a direct window into the kernel's live list of loaded modules.

#### Understanding the Output
The output of `lsmod` typically has three columns:
1.  **Module**: The name of the kernel module.
2.  **Size**: The amount of memory the module occupies.
3.  **Used by**: A count of how many other modules or processes are currently using this module, followed by a list of the dependent modules.

> [!TIP] The "Used by" Column is Key
> A module with a "Used by" count greater than 0 cannot be unloaded until its dependencies are released. This is critical for troubleshooting why a module fails to unload.

---

## Part 2: The Modern Toolkit: Managing Modules with `modprobe`

`modprobe` is the intelligent, high-level utility for managing kernel modules. It is the recommended and safest tool for everyday use because it automatically handles dependencies.

### Loading Modules with `modprobe`

This command loads a module and, crucially, all other modules it depends on.

```bash
# Load the 'nvidia' module
sudo modprobe nvidia

# Load a module verbosely to see exactly what commands are being run
sudo modprobe -v nvidia
```

### Unloading Modules with `modprobe -r`

This command unloads a module. It will also attempt to unload any dependencies that are no longer in use.

```bash
# Unload (remove) the 'nvidia' module
sudo modprobe -r nvidia
```

> [!note] you can also use these, they do the same thing
> To unload—remove—a module, use any of:
> rmmod module_name
> modprobe -r module_name
> modprobe --remove module_name

> [!WARNING] Cannot Unload a Module in Use
> You cannot unload a module if it's currently being used by a process (like a running display server) or another loaded module. `modprobe -r` will fail with an error in this case. You must stop the processes using the module before it can be removed.

### Inspecting Modules with `modinfo`

Before loading a module, you can inspect it to get detailed information. This is invaluable for verification and troubleshooting.

```bash
# Display all available information about the 'nvidia' module
modinfo nvidia
```

**Information provided by `modinfo` includes:**
*   `filename`: The full path to the module file (`.ko.zst`).
*   `license`: The software license of the module.
*   `description`: A brief description of the module's purpose.
*   `author`: The author of the module.
*   `depends`: A list of other modules it requires to function.
*   `parm`: A list of parameters (options) you can set when loading the module.

---

## Part 3: The Low-Level Tools & Dependency Management

These tools are the building blocks that `modprobe` uses. While you should prefer `modprobe`, understanding them is essential for deep system knowledge.

> [!DANGER] Use `modprobe` Instead of `insmod` and `rmmod`
> The original note correctly warns against using `insmod` and `rmmod` directly for general use. These are low-level, "unsafe" tools because they **do not understand dependencies**.
>
> *   Using `insmod` to load a module that requires another module will fail unless you manually load the dependency first.
> *   Using `rmmod` on a module that another module depends on can destabilize your system.
>
> **`modprobe` is the superior tool because it intelligently reads the dependency map and handles the entire chain of modules for you.**

### `depmod`: Building the Module Dependency Map

The `depmod` command creates a map of module dependencies. It scans all module directories and generates the `modules.dep` file, which `modprobe` uses to resolve dependencies.

```bash
# Manually regenerate the module dependency map
sudo depmod
```

> [!NOTE] When is `depmod` Used?
> As your note states, you rarely need to run `sudo depmod` manually. The system handles it automatically in these situations:
>
> *   **After Kernel Updates:** `pacman` hooks run `depmod` for the new kernel version.
> *   **After Driver Installation:** Installing a package with kernel modules (like `nvidia-dkms`) triggers `depmod` to integrate the new modules.
>
> Its purpose is to ensure that when you ask to load Module A, which needs Module B, the system knows to load Module B first.

---

## Part 4: Command Reference Cheat Sheet

Here is a quick reference table for all the commands discussed.

| Command | Description | When to Use |
| :--- | :--- | :--- |
| `lsmod` | Lists all currently loaded kernel modules. | To check if a driver is active. |
| `sudo modprobe <module>` | **Loads** a module and its dependencies. | **Recommended method** for loading drivers. |
| `sudo modprobe -r <module>` | **Unloads** a module and its unused dependencies. | **Recommended method** for unloading drivers. |
| `modinfo <module>` | Displays detailed information about a module. | To verify a driver's details before loading it. |
| `sudo depmod` | Rebuilds the module dependency map. | Rarely needed manually; run by system on updates. |
| `sudo insmod <path/to/module.ko>` | Loads a single module file (no dependency handling). | For debugging or loading out-of-tree modules. **Use with caution.** |
| `sudo rmmod <module>` | Unloads a single module (no dependency handling). | For simple unloading when you are certain of no dependencies. **Use with caution.** |

### Practical Application Example

For a complex, real-world application of these principles, see the detailed guide on installing the proprietary NVIDIA driver: [[Nvidia]].

