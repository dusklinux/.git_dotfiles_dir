NVIDIA

	Installing the NVIDIA Driver and blacklisting/Handling Nouveau
	make sure any previously proprietary driver is removoved if you installed them. 
	3050 Ti is supported by the main nvidia package. However, to handle kernel updates automatically, it's strongly recommended to use the DKMS version.
	make sure your kernal-headers are installed first.
sudo pacman -S --needed linux-headers linux-lts-headers (ltsheaders only if that kernal is also instlaled.)
	install nvidia-dkms and other stuff
sudo pacman -S --needed nvidia-dkms nvidia-utils nvidia-settings
	(it'll install the following packages and dependencies Packages (7) dkms-3.1.8-1  egl-gbm-1.1.2.1-1  egl-x11-1.0.1-1  libxnvctrl-570.144-1  nvidia-dkms-570.144-3  nvidia-settings-570.144-1  nvidia-utils-570.144-3)
	nvidia-dkms: Installs the driver source and uses DKMS to automatically rebuild the kernel module when you update your kernel.
	nvidia-utils: Provides essential libraries and utilities like nvidia-smi.
	nvidia-settings: A graphical tool for configuration (some features might be limited under Wayland).
	Blacklist Nouveau: The nvidia-dkms package should automatically install a file (/usr/lib/modprobe.d/nvidia.conf or similar) that blacklists the open-source nouveau driver. You can verify this:
grep nouveau /usr/lib/modprobe.d/nvidia*.conf
	If it shows a line like blacklist nouveau, you're set. If not, or to be absolutely sure, create a file:
sudo nano /etc/modprobe.d/blacklist-nouveau.conf
	Add the following line:
blacklist nouveau
	Enable NVIDIA Kernel Mode Setting (KMS): This is crucial for Wayland and a smooth graphical boot. You need to add nvidia_drm.modeset=1 to your kernel parameters.
	How to add kernel parameters: This depends on your bootloader (e.g., GRUB, systemd-boot).
GRUB: Edit /etc/default/grub. Find the line starting with GRUB_CMDLINE_LINUX_DEFAULT= and add nvidia_drm.modeset=1 inside the quotes, separated by spaces from other options (e.g., GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet nvidia_drm.modeset=1"). Then, run sudo grub-mkconfig -o /boot/grub/grub.cfg.
systemd-boot: Edit the relevant entry file in /boot/loader/entries/ (e.g., linux..xyz.conf). Append nvidia_drm.modeset=1 to the options line.
	Rebuild the Initramfs: After installing drivers and potentially modifying modprobe files or kernel parameters, you need to regenerate the initial RAM disk image:
sudo mkinitcpio -P
	Reboot: A reboot is necessary for the new driver, blacklisting, and KMS setting to take effect.
sudo reboot

 envycontrol: Another popular tool for Optimus laptops.
Install it (check Arch Wiki/AUR: yay -S envycontrol).
Check current status: sudo envycontrol -q
Switch to Integrated: sudo envycontrol -s integrated (Reboot required)
Switch to Hybrid: sudo envycontrol -s hybrid (Reboot required)
Switch to NVIDIA: sudo envycontrol -s nvidia (Reboot required)


(Advanced/Fallback) acpi_call: Manually turns off the GPU via ACPI calls. This is more complex and requires finding the specific command for your laptop model. Use this only if BIOS options and tools like supergfxctl/envycontrol fail. See the NVIDIA Optimus Arch Wiki page for details. Requires acpi_call-dkms.
Using Hybrid Mode (PRIME Render Offload):

4. Wayland Considerations (Hyprland/GNOME)
nvidia_drm.modeset=1: Essential, as configured in step 1.
PRIME Render Offload: This is the standard way to use the dGPU under Wayland in Hybrid mode. prime-run works well.
Hyprland: Check the Hyprland Wiki NVIDIA page for any specific environment variables or settings recommended (e.g., WLR_NO_HARDWARE_CURSORS=1 might sometimes help, or specific LIBVA_DRIVER_NAME settings if using hardware video acceleration).
--------------------
one can list all the PCI display controllers available
lspci -d ::03xx

hyprland which gpu being used from hyprland wiki multiple gpus
	to see which card is which (Do not use the card1 symlink indicated here. It is dynamically assigned at boot and is subject to frequent change)
ls -l /dev/dri/by-path

telling hyprland to use a certain GPU
	After determining which “card” belongs to which GPU, we can now tell Hyprland which GPUs to use by setting the AQ_DRM_DEVICES environment variable.
	
If you would like to use another GPU, or the wrong GPU is picked by default, set AQ_DRM_DEVICES to a :-separated list of card paths, e.g.

env = AQ_DRM_DEVICES,/dev/dri/card0:/dev/dri/card1

Here, we tell Hyprland which GPUs it’s allowed to use, in order of priority. For example, card0 will be the primary renderer, but if it isn’t available for whatever reason, then card1 is primary.

Do note that if you have an external monitor connected to, for example card1, that card must be included in AQ_DRM_DEVICES for the monitor to work, though it doesn’t have to be the primary renderer.

You should now be able to use an integrated GPU for lighter GPU loads, including Hyprland, or default to your dGPU if you prefer.

uwsm users are advised to export the AQ_DRM_DEVICES variable inside ~/.config/uwsm/env-hyprland, instead. This method ensures that the variable is properly exported to the systemd environment without conflicting with other compositors or desktop environments.

export AQ_DRM_DEVICES="/dev/dri/card0:/dev/dri/card1"

(how to tell which one is which: The lspci output shows the PCI address (0000:00:02.0 for Intel, 0000:01:00.0 for NVIDIA). The ls -l /dev/dri/by-path output links these exact PCI addresses (e.g., pci-0000:00:02.0) to the device files (/dev/dri/cardX, /dev/dri/renderDX). You match the PCI address from lspci to the path in /dev/dri/by-path.)
	
	to export for uwsm users like me
nvim ~/.bash_profile

	add this line but note which card is for which gpu card1 or card0 and then just enter that card without brackets. (Use the arrow keys to navigate, type the line, then press Ctrl + X to exit, Y to confirm saving, and Enter to confirm the filename).
export AQ_DRM_DEVICES=/dev/dri/<card>
---------
nvidia-smi #(NVIDIA System Management Interface) reports GPU load, memory usage, temperature and the list of processes using the GPU

nvidia-smi -q -d POWER #to Get specific power information, including limits.

sudo nvidia-smi -pl 90 #set the power limit to 90 watts
Set a Power Limit: You can temporarily cap the GPU's maximum power draw in watts. This is useful for reducing heat or noise. This change is not persistent and will be reset on reboot

	Control Persistence Mode: This is a crucial setting. 
sudo nvidia-smi -pm 0 #Disabled (Default/Good for Laptops): When no applications are using the GPU, the driver is allowed to be unloaded, which is required for the RTD3 sleep state to engage. This is what you want for power savings.

sudo nvidia-smi -pm 1 #Enabled: This forces the NVIDIA driver to stay loaded in the kernel at all times, even with no GPU clients. This prevents the GPU from entering the RTD3 sleep state. Its main use is for developers using CUDA who need to reduce driver load latency between computations. For general use, ensure this is disabled.

-------------
System-Wide Power Features
nvidia-powerd #Dynamic Boost, Your laptop supports Dynamic Boost, a feature that intelligently shifts the power budget between the CPU and GPU to maximize performance. If a game is GPU-bound, it allocates more power to the GPU; if a task is CPU-bound, it allocates more to the CPU. This is managed by a background service (daemon)

sudo systemctl enable --now nvidia-powerd.service #Enable and start the nvidia-powerd service:
------------------
Deep, Persistent Kernel Control
#This is where you control the fundamental, persistent behavior of the driver. These settings are applied when the kernel module is first loaded at boot. You configure this by creating a .conf file in /etc/modprobe.d/

sudo nvim /etc/modprobe.d/nvidia-power.conf #Create a configuration file. The name doesn't matter, but it must end in .conf
Add <options> lines to this file.
Rebuild your initial ramdisk (initramfs) for the changes to be included at early boot.
Reboot.

NVreg_DynamicPowerManagement #The Most Important Kernel Parameter: This parameter controls the RTD3 sleep state.
 
File: /etc/modprobe.d/nvidia-power.conf
Recommended Content:
# Enable Fine-Grained Runtime D3 Power Management
options nvidia "NVreg_DynamicPowerManagement=0x02"

explination: 
0x00: Disabled. The GPU will never power off. High power consumption.
0x01: Coarse-Grained. The GPU powers down only when there are zero applications using it.
0x02: Fine-Grained. The GPU can power down even when an application (like a web browser or window manager) is running, as long as the GPU itself has been idle for a short period. This is the setting you want for maximum battery life.
0x03: Default. On your Ampere-generation GPU, this defaults to 0x02. Setting it explicitly to 0x02 is clearer and safer across driver updates.
--------------------------

Automating Power Management with udev

You need to tell the system that it is allowed to automatically manage the GPU's power state. You do this with a udev rule, which is a set of rules the system follows when devices are connected or discovered.
RESEARCH IT..


--------------------------
dmesg or journalctl -k) for lines mentioning “nvidia” or “nouveau”. These logs often appear in dmesg as the NVIDIA kernel driver starts or fails.


lsmod | grep -i nvidia #to show all nvidia related modules lodaded in the ram. this is checked though /proc/modules (it's a virtual file and a repreisentation of all the kernal modules currently loaded into memory)

/etc/modprobe.d/ #this is the path to .conf files where modules are blacklisted from loading during boot. need to remake initramfs after changing this. by running <sudo mkinitcpio -P>

sudo dmesg | grep -i nvidia #shows all the logs for nvidia since boot. 

lspci | grep VGA #to find out the pcie bus and currently usable grapchics cards . 
lspci | grep -E 'VGA|3D' #same thing as above command

ls -l /dev/dri/by-path/*-card #VERY IMPORTANT TO CHECK, THIS CHANGES, AND SO DOES PCIE BUS SO CHECK BOTH EVERYTIME. this shows you the card0/card1/card2 and there corrosponding gpu's to see which card is which gpu
ls -l /dev/dri/by-path/ #same as above but shows the renderer as well. 


lspci -k | grep -EA3 'VGA|3D|Display' #to check which particular driver/ module your graphics cards are using, eg mesa, i915, nouveau, nvidia
or
lspci -nnk | grep -EA3 '\[03(00|01|02|80)\]' #does the same thing as the above command but this is more robust sometimes for checking which driver your gpus are using.


lsmod | grep -E "bbswitch|nouveau|nvidia|mesa|intel|prime" #this checks all the modules that the kernal has loaded. you can add more things to this or remove the ones you don't need.  

vulkaninfo --summary #to check which gpu's are currently loaded and can be used. On systems with multiple GPUs vulkaninfo --summary quickly shows all Vulkan-capable devices and their assigned "GPU number,"

journalctl -k | grep -E -i "bbswitch|nouveau|nvidia|01:00.0" #to check kernal logs for specified keywords/errors

journalctl | grep -E -i "bbswitch|nouveau|nvidia|01:00.0" #to check all logs for specified keywords/errros


	LOADING NVIDIA MODULE INTO THE KERNAL
	
depmod to update the dependecy list for modules. so it know all the right depeendencys for a module before loading it. 

sudo modprobe <module_name> #Load a module, and -v flag for Loading a module verbosely, showing what it's doing.

sudo modprobe -r <module_name> #Unload a module

Important: You generally cannot unload a module if it's currently in use by a process or another loaded module. modprobe -r will attempt to unload its dependencies too, but if it's in use, it will fail. You can check lsmod to see if a module has any Used by count greater than 0

modinfo <module_name> #to know information about a module

sudo cat /sys/module/nvidia_drm/parameters/modeset #to check if nvidia-drm.modeset=1 is set or not should say Y or N yes or no

---------------
	to check the PM runtime (power managermetn runtime for a specific pci bus eg nvidia)
	first find out the pci bus number for the device with lspci

sudo lspci

	then introduce backward slash in the pci bus number right before the colon and enter the following command
	this is for nvidia gpu from the lspci - 0000:01:00.0

0000\:01\:00.0	

	then type out the full command with the addes backward slashes, the second one is to check the power state, the third is to check some auto thing 
	
sudo cat /sys/bus/pci/devices/0000\:01\:00.0/power/runtime_status
sudo cat /sys/bus/pci/devices/0000:01:00.0/power_state
sudo cat /sys/bus/pci/devices/0000:01:00.0/power/control

ls -l /usr/lib/systemd/system/nvidia-*.service #to check all exisitng services related to nvidia on the system. 

-------------

	HARDWARE DECODERS FOR ALL GPUs

vainfo #displays information about your system's VA-API (Video Acceleration API) capabilities. It tells you which video codecs your hardware can accelerate for decoding and encoding.

nvtop #displays GPU utilization, memory usage (VRAM), temperature, power draw, and processes running on the GPU in a user-friendly, curses-based interface.leverages the NVIDIA Management Library (NVML) to retrieve real-time GPU statistics.

nvidia-smi #its built on top of the NVIDIA Management Library (NVML). It directly queries NVML for a wide range of GPU attributes, including usage, memory, temperature, power, clock speeds, and active processes

sudo intel_gpu_top #directly queries the Intel graphics driver (i915 kernel module) to get detailed performance counters and engine utilization statistics.

sudo btop #collects information from various system files and kernel interfaces (e.g., /proc, /sys) to gather data on CPU usage, memory allocation, disk I/O, network traffic, and running processes.

----------------------
THIS IS A VERY IMPORTANT PART OF POWERMANAGEMETN FOR THE NVIDIA GPU

sudo nvim /proc/driver/nvidia/gpus/0000:01:00.0/power

#/proc/driver/nvidia/gpus/0000:01:00.0/power: This is the full path to a special file that acts as a direct interface to your NVIDIA driver's power management features.

The /proc directory is not a real directory on your hard drive or SSD. It's a virtual filesystem created in memory by the Linux kernel when your system boots. Think of it like a live dashboard or control panel for the kernel.

The power file is an interface provided by the NVIDIA kernel driver to view and control some of its power management features. When you open this file, you are directly interacting with the driver.

This file is primarily used to inspect the current power state of the GPU and, in some cases, to manually set a specific power limit or performance level. It's a low-level tool often used for:
Debugging: System administrators and developers might use it to diagnose power-related issues with the GPU.
Fine-tuning: Advanced users might use it to manually cap the GPU's power consumption to reduce heat or fan noise, especially on laptops.
Understanding Power States: Reading the file provides detailed information about the GPU's current power management state, supported power levels, and more.

When you cat (read) the /proc/driver/nvidia/gpus/0000:01:00.0/power file, the NVIDIA kernel driver intercepts this request. It doesn't fetch data from a disk. Instead, it queries the GPU's firmware and its own internal state to gather real-time power management information and then formats it as text for you to see.

When you use echo or a text editor like nvim to write a value to this file, the kernel driver again intercepts it. It parses the string you sent (e.g., "power_limit=100") and translates it into a command that is sent directly to the GPU's power management controller. This changes the hardware's behavior in real-time.

Is it Safe to Modify Values? Caution is Advised.

Modifying values in this file is a powerful but potentially risky operation.

    Is it safe? Generally, yes, if you know what you are doing and use valid parameters. The NVIDIA driver is designed to reject invalid or dangerous values. For example, setting a power limit far outside the Min and Max range shown in the file will likely fail.
    What are the risks?
        Instability: Setting an inappropriate power limit (either too low or too high, if the driver even allows it) could cause system instability, graphics artifacts, or application crashes. For instance, setting a power limit that is too low might prevent the GPU from reaching the necessary performance level to run a demanding application, leading to a crash.
        Performance Loss: Limiting the power will directly limit the GPU's performance.
        Not Persistent: Any changes made to files in /proc are temporary and will be reset upon reboot. This is actually a safety feature. If you make a change that destabilizes your system, a simple reboot will fix it.

DON'T CHANGE VALUES ABOVE IN TEH FILE, USE NVIDIA-SMI INSTEAD!!!

nvidia-smi (NVIDIA System Management Interface)

This is the preferred and standard command-line tool for managing and monitoring your NVIDIA GPU. It provides most of the functionality of the /proc interface and much more in a safer, more structured way.

To see power information with nvidia-smi:
Shell

nvidia-smi

To set a persistent power limit (e.g., to 100 watts):
Shell

sudo nvidia-smi -pl 100

nvidia-smi is the recommended tool for tasks like setting power limits, monitoring temperature and usage, and changing GPU clock speeds. It's more robust and provides clearer feedback than writing directly to /proc files.

	DIFFRENECT BETWEEN nvidia-smi and editing it driectly. 

nvidia-smi
High-level command-line utility
General monitoring, setting power limits, clock speeds, and other settings.
Recommended and safer. Has built-in error checking and clear syntax.
Yes. Can set persistent configurations.
The car's official diagnostic and tuning computer.
Use this for all your GPU management tasks.

sudo nvim /proc/.../power
Low-level kernel interface
Debugging, deep system inspection, specific low-level tweaks.
Use with caution. Changes are temporary. Mistakes can cause instability until reboot.
No. Changes are lost on reboot.
A mechanic directly adjusting a single screw on the engine.
Use it to learn and observe. Avoid writing to it unless you have a very specific goal.


Performance Levels (P-States): These are the GPU's active states. They range from P0 (maximum performance, maximum power draw) down to P8 or P12 (idle, minimum power draw while still being on). The NVIDIA driver automatically and rapidly switches between these P-states based on the current workload. You generally do not need to, and should not, manage these manually.
Runtime D3 (RTD3) Sleep State: This is the off state. On a hybrid graphics laptop like yours, the driver can completely power off the NVIDIA GPU when it's not in use, resulting in massive power savings. This is the most important power management feature for a laptop. When the GPU is in this state, it is often referred to as being in D3cold

If your GPU is correctly powered down (in RTD3), nvtop will show "No GPU to monitor." This is good news—it means you're saving power. When you launch a GPU-intensive application, nvtop will instantly show its stats.
----------------------
Display Power Management Signaling (DPMS) #
Direct Rendering Manager (DRM)
Kernal Module Setting (KMS)
