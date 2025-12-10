# KVM Kernel Modules Setup

> [!ABSTRACT] What are we doing?
> 
> Before installing any software, we need to ensure your computer's operating system (the Kernel) is allowed to act as a Hypervisor. We do this by checking for specific "modules" that bridge your hardware to the software.

## 1. Verify Existing Modules

First, we need to check if your system has already loaded the necessary KVM modules automatically.

Open your terminal and run the following command. This asks the system to list all running modules (`lsmod`) and filters the text (`grep`) to show only lines containing "kvm".

```bash
lsmod | grep kvm
```

### Understanding the Output

Scenario A: Success

If the modules are loaded correctly, you will see output similar to the block below. Look for kvm and kvm_intel. or amd related KVM modules. 

> [!SUCCESS] Expected Output
> 
> ```
> kvm_intel             364544  0
> kvm                  1155072  1 kvm_intel
> irqbypass             16384   1 kvm
> ```
> 
> _If you see this, you can skip to the next note!_

Scenario B: No Output

If the command returns nothing (a blank line), the modules are not loaded. Please proceed to step 2.

## 2. Load the Kernel Modules manually

If the verification step returned nothing, we need to load the module manually for your current session.

> [!NOTE] Hardware Specific
> 
> The commands below are specifically for Intel processors.

Run this command to load the module immediately:

```bash
sudo modprobe kvm_intel
```

## 3. Configure Auto-load on Boot

Loading the module with `modprobe` only lasts until you turn off your computer. To ensure KVM works every time you turn on your machine, we need to add a configuration file that tells the system to load it automatically.

We will create a specific config file inside `/etc/modules-load.d/`.

**Run the following command:**

```bash
echo kvm_intel | sudo tee /etc/modules-load.d/kvm.conf
```

> [!info] What did this command do?
> 
> It created a text file named kvm.conf and wrote the text kvm_intel inside it. When your computer boots, it reads this file and loads the module for you.

## 4. Apply Changes

To ensure everything is locked in and working correctly, reboot your system now.

```bash
systemctl reboot
```