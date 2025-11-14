
> [!NOTE]
> This step is only necessary if your system has a dedicated NVIDIA graphics card. If you are using an integrated Intel GPU or an AMD GPU, you can skip this section.

For proper functionality of your NVIDIA GPU, including hardware acceleration, display management, and compatibility with compositors like Hyprland, you must install the proprietary drivers.

### Installation Command

Execute the following command to install the complete set of recommended packages for modern NVIDIA cards.

Nvidia Opensource

```bash
pacman -S --needed nvidia-open-dkms nvidia-utils nvidia-settings opencl-nvidia libva-nvidia-driver nvidia-prime egl-wayland
```

```bash
pacman -S --needed cuda
```

or
Propriotory 

```bash
pacman -S --needed nvidia-dkms nvidia-utils nvidia-settings opencl-nvidia libva-nvidia-driver nvidia-prime egl-wayland
```

> [!TIP] Why `nvidia-dkms` is Recommended
> The `nvidia-dkms` package is strongly preferred over the standard `nvidia` package. DKMS (Dynamic Kernel Module Support) automatically rebuilds the NVIDIA kernel module each time the Linux kernel is updated. This prevents your graphical environment from breaking after a system update, saving you a common and significant troubleshooting step.

### Package Breakdown

This table explains the purpose of each package in the installation command.

| Package | Description |
| :--- | :--- |
| `nvidia-dkms` | The core NVIDIA driver with DKMS support for automatic kernel module updates. |
| `nvidia-utils` | Contains essential command-line utilities like `nvidia-smi` for monitoring your GPU. |
| `nvidia-settings` | A graphical application for configuring your NVIDIA driver settings. |
| `opencl-nvidia` | Provides OpenCL support, enabling GPU-accelerated computing tasks. |
| `libva-nvidia-driver` | Enables VA-API (Video Acceleration API) for hardware-accelerated video decoding. |
| `nvidia-prime` | A utility for managing graphics switching on laptops with both integrated and NVIDIA GPUs (NVIDIA Optimus technology). |
| `egl-wayland` | Provides EGL support required for NVIDIA drivers to function correctly with Wayland compositors. |

> [!WARNING] Legacy NVIDIA Hardware
> The `nvidia-dkms` package supports modern NVIDIA GPUs (Maxwell series / GTX 900 and newer). If you have an older card, you may need a legacy driver. Consult the Arch Wiki for your specific GPU model to see if you require a different package, such as `nvidia-470xx-dkms`.

