# Performance Tuning with TuneD

**TuneD** is a background service that automatically optimizes your Linux system settings based on how you use your computer. Since we are setting up a KVM Hypervisor (to run Virtual Machines), we need to tell the system to prioritize virtualization performance over power saving or standard desktop behavior.

> [!DANGER] CRITICAL WARNING: TLP USERS
> 
> Do you have TLP (Linux Advanced Power Management) installed to save battery life?
> 
> **TuneD and TLP conflict with one another.** Running both simultaneously will cause system instability and conflicting power settings.
> 
> - If you have TLP installed and want to keep it: **SKIP THIS ENTIRE NOTE.**
>     
> - If you prefer performance for your Virtual Machines over battery life: Uninstall TLP before proceeding.
>     

## 1. Installation

First, we need to install the TuneD package from the official repositories.

```bash
sudo pacman -Syu --needed tuned
```

## 2. Enable the Service

Once installed, we must enable the service so it starts automatically when you turn on your computer, and start it immediately for this session.

```bash
sudo systemctl enable --now tuned
```

## 3. Check Current Status

By default, TuneD usually picks a "balanced" profile. Let's verify what is currently running.

```bash
tuned-adm active
```

_Expected Output: `Current active profile: balanced` (or similar)_

## 4. Selecting the KVM Host Profile

We need to switch the profile to **`virtual-host`**. This profile optimizes the kernel to handle the heavy I/O (Input/Output) and CPU scheduling requirements of running KVM Virtual Machines.

```bash
tuned-adm list
```

> [!INFO]- Reference: All Available Profiles
> 
> You don't need to memorize these, but here is a list of profiles TuneD offers for different scenarios:
> 
> ```
> - accelerator-performance       - Throughput performance based tuning with disabled higher latency STOP states
> - atomic-guest                  - Optimize virtual guests based on the Atomic variant
> - atomic-host                   - Optimize bare metal systems running the Atomic variant
> - aws                           - Optimize for aws ec2 instances
> - balanced                      - General non-specialized tuned profile
> - balanced-battery              - Balanced profile biased towards power savings changes for battery
> - cpu-partitioning              - Optimize for CPU partitioning
> - cpu-partitioning-powersave    - Optimize for CPU partitioning with additional powersave
> - default                       - Legacy default tuned profile
> - desktop                       - Optimize for the desktop use-case
> - desktop-powersave             - Optmize for the desktop use-case with power saving
> - enterprise-storage            - Legacy profile for RHEL6, for RHEL7, please use throughput-performance profile
> - hpc-compute                   - Optimize for HPC compute workloads
> - intel-sst                     - Configure for Intel Speed Select Base Frequency
> - laptop-ac-powersave           - Optimize for laptop with power savings
> - laptop-battery-powersave      - Optimize laptop profile with more aggressive power saving
> - latency-performance           - Optimize for deterministic performance at the cost of increased power consumption
> - mssql                         - Optimize for Microsoft SQL Server
> - network-latency               - Optimize for deterministic performance at the cost of increased power consumption, focused on low latency network performance
> - network-throughput            - Optimize for streaming network throughput, generally only necessary on older CPUs or 40G+ networks
> - openshift                     - Optimize systems running OpenShift (parent profile)
> - openshift-control-plane       - Optimize systems running OpenShift control plane
> - openshift-node                - Optimize systems running OpenShift nodes
> - optimize-serial-console       - Optimize for serial console use.
> - oracle                        - Optimize for Oracle RDBMS
> - postgresql                    - Optimize for PostgreSQL server
> - powersave                     - Optimize for low power consumption
> - realtime                      - Optimize for realtime workloads
> - realtime-virtual-guest        - Optimize for realtime workloads running within a KVM guest
> - realtime-virtual-host         - Optimize for KVM guests running realtime workloads
> - sap-hana                      - Optimize for SAP HANA
> - sap-hana-kvm-guest            - Optimize for running SAP HANA on KVM inside a virtual guest
> - sap-netweaver                 - Optimize for SAP NetWeaver
> - server-powersave              - Optimize for server power savings
> - spectrumscale-ece             - Optimized for Spectrum Scale Erasure Code Edition Servers
> - spindown-disk                 - Optimize for power saving by spinning-down rotational disks
> - throughput-performance        - Broadly applicable tuning that provides excellent performance across a variety of common server workloads
> - virtual-guest                 - Optimize for running inside a virtual guest
> - virtual-host                  - Optimize for running KVM guests
> ```

**Apply the Virtual Host profile:**

```bash
sudo tuned-adm profile virtual-host
```

## 5. Verification

Finally, let's confirm the switch was successful and that there are no errors in the configuration.

**Check the active profile:**

```bash
tuned-adm active
```

_It should now say: `Current active profile: virtual-host`_

**Verify system settings:**

```bash
sudo tuned-adm verify
```

_If everything is correct, this command will return `Verification succeeded`._