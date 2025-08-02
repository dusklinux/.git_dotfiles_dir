
# Verifying GPU Acceleration on Arch Linux

A critical step in any Arch Linux setup is confirming that your system is correctly using the Graphics Processing Unit (GPU) for rendering. This process, known as **Direct Rendering**, offloads graphics tasks from the CPU to the dedicated GPU hardware, resulting in a smooth, responsive desktop experience and optimal performance in graphical applications.

This guide provides the commands and context needed to verify and troubleshoot GPU acceleration.

> [!NOTE] Related Guides
> For a complete setup, this guide should be used in conjunction with the driver installation and configuration notes:
> *   **NVIDIA Setup:** [[Nvidia RAW]]
> *   **NVIDIA Packages:** [[Nvidia Packages]]
> *   **Intel Setup:** [[CPU]]

---

## 1. Prerequisite: Installing Verification Tools

The primary tool for checking the graphics stack, `glxinfo`, is not installed by default. You must first install the package that provides it.

*   **Install `mesa-utils`:** This package contains essential OpenGL utilities, including `glxinfo` and `glxgears`.

    ```bash
    sudo pacman -S --needed mesa-utils
    ```

---

## 2. Checking Direct Rendering Status

With the necessary tools installed, you can now check if direct rendering is enabled.

### The Command

Execute the following command in your terminal. It queries the GLX (OpenGL Extension to the X Window System) information and filters it to show the single line relevant to direct rendering.

```bash
glxinfo | grep "direct rendering"
```

### Interpreting the Output

The output of this command is straightforward and will tell you immediately if your GPU is being used correctly.

*   **✅ Correct Output (Success):**
    If your drivers are loaded and working, you will see:
    ```
    direct rendering: Yes
    ```
    This confirms that applications can render directly to the graphics hardware, which is the desired state.

*   **❌ Incorrect Output (Problem):**
    If there is a configuration issue, you will see:
    ```
    direct rendering: No
    ```
    This indicates that rendering is falling back to the CPU (software rendering), which will cause poor performance, screen tearing, and high CPU usage in graphical tasks.

---

## 3. Troubleshooting "Direct Rendering: No"

If you see `direct rendering: No`, it points to a problem with your GPU driver configuration. Here is a checklist to diagnose the issue.

| Step | Action | Description |
| :--- | :--- | :--- |
| **1. Verify Drivers** | Check driver installation. | Ensure you have installed the correct drivers for your hardware. See [[Nvidia Packages]] for NVIDIA or the Intel section in [[CPU]] for integrated graphics. For AMD, ensure the `mesa` package is installed. |
| **2. Check Kernel Modules** | Use `lsmod` to see loaded modules. | Check if the correct kernel module is loaded. For NVIDIA, you should see `nvidia`. For Intel, `i915`. For AMD, `amdgpu`. <br> `lsmod \| grep -E "nvidia\|i915\|amdgpu"` |
| **3. Review Xorg Logs** | Inspect the Xorg log file. | Errors during the X server startup are logged here. Look for lines containing `(EE)` for errors. <br> `grep "(EE)" ~/.local/share/xorg/Xorg.0.log` |
| **4. User Permissions** | Check user group membership. | Your user must be a member of the `video` group to have the necessary permissions to access the GPU hardware directly. <br> `groups $USER` |

---

## 4. Simple Visual Confirmation with `glxgears`

While not a benchmark, `glxgears` provides a simple, visual way to see 3D acceleration in action.

> [!WARNING] Not a Benchmark Tool
> The `glxgears` utility is only a basic test to confirm that 3D rendering is functional. The FPS (Frames Per Second) it reports is not a meaningful measure of your GPU's overall performance.

*   **Run the Test:**
    ```bash
    glxgears
    ```
    If a window appears with three rotating gears, your system is capable of 3D rendering. You can close the window to stop the test. If the command fails or the animation is extremely slow, it further confirms a driver or configuration issue.

