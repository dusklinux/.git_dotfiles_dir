# MPV Media Player: Setup and Integration on Arch Linux

This guide provides a comprehensive walkthrough for installing and configuring the MPV media player on an Arch Linux system running Hyprland. The steps cover enabling hardware video acceleration for smooth playback and integrating media key support via MPRIS.

---

## 1. Installation & Hardware Acceleration

Properly configuring hardware acceleration offloads video decoding from the CPU to the GPU, resulting in significantly lower power consumption and smoother playback, especially for high-resolution content.

### Step 1: Install Core Packages

First, ensure MPV and the necessary hardware acceleration drivers are installed. The `--needed` flag prevents reinstalling packages that are already up-to-date.

```bash
sudo pacman -S --needed mpv libva-utils
```

> [!TIP] Choose the Right Driver for Your GPU
> The `libva` driver you need depends on your graphics card. Install the appropriate package for your hardware:
> - **Intel:** `intel-media-driver`
> - **NVIDIA:** `libva-nvidia-driver` (ensure you have also installed the main [[Nvidia Packages]])
> - **AMD:** `libva-mesa-driver` (this is typically included with the `mesa` package)
>
> For example, an Intel user would run:
> ```bash
> sudo pacman -S --needed mpv libva-utils intel-media-driver
> ```

### Step 2: Configure MPV

Next, create a configuration file to tell MPV to use hardware decoding by default.

1.  Create the directory if it doesn't exist:

```bash
mkdir -p ~/.config/mpv/
```

2.  Open the configuration file in a text editor:

```bash
nvim ~/.config/mpv/mpv.conf
```

3.  Add the following content to the file:

```ini
# enable VA‑API hardware decode for AV1
hwdec=vaapi
hwdec-codecs=av1

# video output opts for Wayland; use gpu-context=x11 if on Xorg
vo=gpu
gpu-context=wayland
```

> [!NOTE] Configuration Explained
> - **`hwdec=vaapi`**: Enables the Video Acceleration API (VA-API), the standard for hardware acceleration on Linux.
> - **`vo=gpu`**: Sets the video output to the modern, high-performance `gpu` backend, which is required for `hwdec` to function.
> - **`gpu-context=wayland`**: Explicitly tells MPV to render within the Wayland context, which is essential for stability and performance in Hyprland.

---

## 2. Media Key Integration (MPRIS)

To control MPV playback using your keyboard's media keys (Play/Pause, Next, Previous) or command-line tools like `playerctl`, you need to enable its MPRIS plugin.

### Step 1: Install the MPRIS Plugin

The plugin is available as a separate package in the official repositories.

```bash
sudo pacman -S --needed mpv-mpris
```

### Step 2: Enable the Plugin

MPV automatically loads scripts from the `~/.config/mpv/scripts/` directory. We will create a symbolic link to the installed plugin file in this directory.

1.  Create the `scripts` directory:

```bash
mkdir -p ~/.config/mpv/scripts
```

2.  Create the symbolic link: (the scripts .so file is in one of these two directories, check which one it is and then run one of the commands below depending on the applicability of it)

either
```bash
ln -nfs /usr/lib/mpv-mpris/mpris.so ~/.config/mpv/scripts/
```

or
```bash
ln -nfs /usr/lib/mpv/scripts/mpris.so ~/.config/mpv/scripts/
```

> [!TIP] Why Use a Symbolic Link?
> By creating a symbolic link (`ln -nfs`) instead of copying the file, the script will be automatically updated whenever the `mpv-mpris` package is upgraded through `pacman`. This ensures you always have the latest version without manual intervention.

### Step 3: Test the Integration

Your media keys should now work seamlessly with MPV.

1.  Open any video file in MPV.
2.  While the video is playing, use your keyboard's dedicated Play/Pause media keys.
3.  Alternatively, open a new terminal and test the controls with `playerctl`:
    ```bash
    # Check the status
    playerctl status
    
    # Pause the video
    playerctl pause
    
    # Play the video
    playerctl play
    ```

If the commands and keys control the MPV window, the setup is successful.
