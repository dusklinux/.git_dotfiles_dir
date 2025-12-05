```ini
#new dusk
#most power saving settings, turbo boost, CPU_MAX_PERF_ON_*, CPU_HWP_DYN_BOOST_

# ----------------------------------------------------------------------------
# /etc/tlp.conf - TLP user configuration (version 1.9.0-beta.1_2b55255)
# See full explanation: https://linrunner.de/tlp/settings
#
# Copyright (c) 2025 Thomas Koch <linrunner at gmx.net> and others.
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Settings are read in the following order:
#
# 1. Intrinsic defaults
# 2. /etc/tlp.d/*.conf - Drop-in customization snippets
# 3. /etc/tlp.conf     - User configuration (this file)
#
# Power Profiles: a part of TLP's parameters is divided into two or three
# groups:
# - performance: parameters ending in _AC are used when AC power is
#   connected or when the command 'tlp performance' is run.
# - balanced: parameters ending in _BAT are used when operating
#   on battery power or when the command 'tlp balanced' is run.
# - power-saver: parameters ending in _SAV are used when the command
#   'tlp power-saver' is run. If there is no _SAV parameter available
#   for a feature, the _BAT parameter will be used instead.
# - Any remaining parameters not divided apply to all power profiles.
#
# Please note:
# - If parameters are specified more than once, the last occurrence takes
#   precedence. This also means that any parameters defined here will take
#   precedence over any drop-ins.
# - You can however, append values to a parameter already defined as intrinsic
#   default or in a previously read file: use PARAMETER+="add values".
# - Important: all parameters are disabled here. Remove the leading '#' if you
#   want to enable a feature without a default or if you want to set a value
#   other than the default.
# - Parameters must always be specified for all power profiles, i.e. in the
#   AC, BAT and SAV category (where applicable). If you omit one of them,
#   the missing profile will receive its value from another profile, since
#   a change will only occur if different values are defined.
# - To completely disable a parameter, use PARAMETER="".
# Legend for defaults:
# - Default *: intrinsic default that is effective when the parameter is
#   missing or the line has a leading #'.
# - Default <none>: do nothing or use kernel/hardware defaults.
#
# ----------------------------------------------------------------------------
# tlp - Parameters for power saving

# Set to 0 to disable, 1 to enable TLP.
# Default: 1

# TLP_ENABLE=1

# Set to 1 to deactivate all intrinsic defaults of TLP. This means that
# TLP only applies settings that have been explicitly activated i.e.
# parameters without a leading '#'.
# Notes:
# - Helpful if one wants to use only selected features of TLP
# - After activation, use tlp-stat -c to display your effective configuration

#TLP_DISABLE_DEFAULTS=1

# Control how warnings about invalid settings are issued:
#   0=disabled
#   1=background tasks (boot, resume, change of power source) report to syslog
#   2=shell commands report to the terminal (stderr)
#   3=combination of 1 and 2
# Default: 3

#TLP_WARN_LEVEL=3

# Colorize error, warning, notice and success messages. Colors are specified
# with ANSI codes:
#   1=bold black, 90=grey, 91=red, 92=green, 93=yellow, 94=blue, 95=magenta,
#   96=cyan, 97=white.
# Other colors are possible, refer to:
#   https://en.wikipedia.org/wiki/ANSI_escape_code#3-bit_and_4-bit
# Colors must be specified in the order
#   "<error> <warning> <notice> <success>".
# By default, errors are shown in red, warnings in yellow, notices in bold
# and success in green.
# Default: "91 93 1 92"

#TLP_MSG_COLORS="91 93 1 92"

# Control automatic switching of the power profile when connecting or removing
# the charger, when booting the system or when executing 'tlp start':
#   0=disabled - never switch, use TLP_DEFAULT_MODE if configured
#   1=auto  - always switch, select performance on AC and
#             balanced on battery power.
#   2=smart - do not switch if the following profiles were active previously:
#             power-saver or balanced on AC resp.
#             power-saver or performance on battery power.
# Note: the same applies if the charger was connected/removed during suspend.
# Default: 2

#TLP_AUTO_SWITCH=2

# Power profile to use when automatic switching is disabled
# (TLP_AUTO_SWITCH=0), profile is locked (TLP_PERSISTENT_DEFAULT=1)
# or no power supply is detected:
#   PRF=performance, BAL=balanced, SAV=power-saver.
# Note: legacy values AC and BAT continue to work. They are mapped to
# PRF and BAL, respectively.
# Default: <none>

TLP_DEFAULT_MODE=SAV

# Lock power profile:
#   0=profile depends on automatic switching,
#   1=profile is locked to TLP_DEFAULT_MODE (TLP_AUTO_SWITCH is ignored).
# Default: 0

#TLP_PERSISTENT_DEFAULT=0

# Power supply classes to ignore when determining power profile:
#  AC, USB, BAT.
# Separate multiple classes with spaces.
# Note: try on laptops where operation mode AC/BAT is incorrectly detected.
# Default: <none>

#TLP_PS_IGNORE="BAT"

# Seconds laptop mode has to wait after the disk goes idle before doing a
# sync. Non-zero value enables, zero disables laptop mode.
# Default: 0 (AC), 2 (BAT)

#DISK_IDLE_SECS_ON_AC=0
#DISK_IDLE_SECS_ON_BAT=2

# Dirty page values (timeouts in secs).
# Default: 15 (AC), 60 (BAT)

#MAX_LOST_WORK_SECS_ON_AC=15
#MAX_LOST_WORK_SECS_ON_BAT=60

# Select a CPU scaling driver operation mode.
# Intel CPU with intel_pstate driver:
#   active, passive.
# AMD Zen 2 or newer CPU with amd-pstate driver as of kernel 6.3/6.4(*):
#   active, passive, guided(*).
# Default: <none>
# command to see if intel pstate intel_pstate is available for each core of your cpu cores, (leave this to active for both for bat and ac, because that way the cpu manages it's own frequency depending on the workload as opposed to offloading it to a generic kernal setting,the cpu's own governar is MUCH MORE optimized and tuned for your specific cpu so DON'T CHANGE THIS)  
#cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_driver

CPU_DRIVER_OPMODE_ON_AC=active
CPU_DRIVER_OPMODE_ON_BAT=active
CPU_DRIVER_OPMODE_ON_SAV=active

# Select a CPU frequency scaling governor.
# Intel CPU with intel_pstate driver or
# AMD CPU with amd-pstate driver in active mode ('amd-pstate-epp'):
#   performance, powersave(*).
# Intel CPU with intel_pstate driver in passive mode ('intel_cpufreq') or
# AMD CPU with amd-pstate driver in passive or guided mode ('amd-pstate') or
# Intel, AMD and other CPU brands with acpi-cpufreq driver:
#   conservative, ondemand(*), userspace, powersave, performance, schedutil(*)
# Use tlp-stat -p to show the active driver and available governors.
# Important:
#   Governors marked (*) above are power efficient for *almost all* workloads
#   and therefore kernel and most distributions have chosen them as defaults.
#   You should have done your research about advantages/disadvantages *before*
#   changing the governor.
# Default: <none>
#Intel cpu's have two settings performance and powersave, powersave will be more aggressvie at scaling down frequency but will still hit the hightest frequencies when needed with this enabled, DO NOT USE CUSTOM CPU SCALING FREQ,command to check yourr's -  
#cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_available_governors 

CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_SCALING_GOVERNOR_ON_BAT=powersave
CPU_SCALING_GOVERNOR_ON_SAV=powersave

# Set the min/max frequency available for the scaling governor.
# Possible values depend on your CPU. For available frequencies see
# the output of tlp-stat -p.
# Notes:
# - Min/max frequencies must always be specified for both AC *and* BAT
# - Not recommended for use with the intel_pstate driver, use
#   CPU_MIN/MAX_PERF_ON_AC/BAT below instead
# Default: <none>

#CPU_SCALING_MIN_FREQ_ON_AC=0
#CPU_SCALING_MAX_FREQ_ON_AC=0
#CPU_SCALING_MIN_FREQ_ON_BAT=0
#CPU_SCALING_MAX_FREQ_ON_BAT=0
#CPU_SCALING_MIN_FREQ_ON_SAV=0
#CPU_SCALING_MAX_FREQ_ON_SAV=0

# Set CPU energy/performance policies EPP and EPB:
#   performance, balance_performance, default, balance_power, power.
# Values are given in order of increasing power saving.
# Requires:
# * Intel CPU
#   EPP: Intel Core i 6th gen. or newer CPU with intel_pstate driver
#   EPB: Intel Core i 2nd gen. or newer CPU with intel_pstate driver
#   EPP and EPB are mutually exclusive: when EPP is available, Intel CPUs
#   will not honor EPB. Only the matching feature will be applied by TLP.
# * AMD Zen 2 or newer CPU
#   EPP: amd-pstate driver in active mode ('amd-pstate-epp') as of kernel 6.3
# Default: balance_performance (AC), balance_power (BAT), power (SAV)
#commands to check available options for this setting first comand is for checking all availabe options and the second one is for the currently set option 
#cat /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_available_preferences
#cat /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference
#options available for 12700H (power being the most efficient)
#Available for asus tuf: default performance balance_performance balance_power power

CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance
CPU_ENERGY_PERF_POLICY_ON_BAT=power
CPU_ENERGY_PERF_POLICY_ON_SAV=power

# Set Intel CPU P-state performance: 0..100 (%).
# Limit the max/min P-state to control the power dissipation of the CPU.
# Values are stated as a percentage of the available performance.
# Requires Intel Core i 2nd gen. or newer CPU with intel_pstate driver.
# Default: <none>
#The CPU_MIN_PERF_ON_* and CPU_MAX_PERF_ON_* parameters map directly to the min_perf_pct and max_perf_pct controls in /sys/devices/system/cpu/intel_pstate/, defining the allowed performance range as a percentage of the CPU’s maximum. For AC power you’ll typically want CPU_MIN_PERF_ON_AC=0 (so the CPU can drop into its deepest idle states) and CPU_MAX_PERF_ON_AC=100 (so it can boost up to its full turbo frequency). On battery you can preserve runtime by keeping CPU_MIN_PERF_ON_BAT=0 but capping CPU_MAX_PERF_ON_BAT=30, which restricts the CPU to 30 % of its peak performance; if you find 30 % too slow when unplugged, simply raise that to something like 50–70 % to suit your workload.

CPU_MIN_PERF_ON_AC=0
CPU_MAX_PERF_ON_AC=100
CPU_MIN_PERF_ON_BAT=0
CPU_MAX_PERF_ON_BAT=70
CPU_MIN_PERF_ON_SAV=0
CPU_MAX_PERF_ON_SAV=40

# Set the CPU "turbo boost" (Intel) or "core performance boost" (AMD) feature:
#   0=disable, 1=allow.
# Allows to raise the maximum frequency/P-state of some cores if the
# CPU chip is not fully utilized and below it's intended thermal budget.
# Note: a value of 1 does *not* activate boosting, it just allows it.
# Default: <none>

CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=1
CPU_BOOST_ON_SAV=0

# Set CPU dynamic boost feature:
#   0=disable, 1=enable.
# Improve performance by increasing minimum P-state limit dynamically
# whenever a task previously waiting on I/O is selected to run.
# Requires Intel Core i  6th gen. or newer CPU with intel_pstate driver
# in active mode.
# Note: AMD CPUs currently have no tunable for this.
# Default: <none>
# A feature that temporarily raises the CPU’s minimum performance level when a thread that’s been waiting on I/O (disk, network, etc.) becomes runnable. In plain English:
#CPU_HWP_DYN_BOOST_ON_AC=1 means “when on mains power, let the CPU automatically bump its baseline P‑state up for a short burst whenever a previously blocked task wakes up,” reducing latency and improving responsiveness.
#CPU_HWP_DYN_BOOST_ON_BAT=0 means “when on battery, disable that boost so you don’t sacrifice extra power for this brief performance kick.”
#This only works on Intel 6th‑gen (Skylake) or newer CPUs when the intel_pstate driver is in active mode.

CPU_HWP_DYN_BOOST_ON_AC=1
CPU_HWP_DYN_BOOST_ON_BAT=1
CPU_HWP_DYN_BOOST_ON_SAV=0

# Kernel NMI Watchdog:
#   0=disable (default, saves power), 1=enable (for kernel debugging only).
# Default: 0

#NMI_WATCHDOG=0

# Select platform profile:
#   performance, balanced, low-power.
# Controls system operating characteristics around power/performance levels,
# thermal and fan speed. Values are given in order of increasing power saving.
# Note: check the output of tlp-stat -p to determine availability on your
# hardware and additional profiles such as: balanced-performance, quiet, cool.
# Default: performance (AC), balanced (BAT), low-power (SAV)
# vendor based highl level power profile, command to see all the availabel profiles available on your pc.
# cat /sys/firmware/acpi/platform_profile_choices
# my asus tuf f15 has the following : quiet balanced performance

PLATFORM_PROFILE_ON_AC=quiet
PLATFORM_PROFILE_ON_BAT=quiet
PLATFORM_PROFILE_ON_SAV=quiet

# System suspend mode:
#   s2idle: Idle standby - a pure software, light-weight, system sleep state,
#   deep: Suspend to RAM - the whole system is put into a low-power state,
#     except for memory, usually resulting in higher savings than s2idle.
# CAUTION: changing suspend mode may lead to system instability and even
# data loss. As for the availability of different modes on your system,
# check the output of tlp-stat -s. If unsure, stick with the system default
# by not enabling this.
# Default: <none>
#s2idle: (Suspend-to-Idle) This is a software-based sleep state. The CPU is put into a deep idle state, but the system is not fully powered down. It offers a very fast resume time but consumes more power than deep suspend. 
#deep: (Suspend-to-RAM) This is the traditional suspend mode. The system state is saved to RAM, and most hardware components are powered off. It offers better power savings than s2idle but has a slightly longer resume time.
#see which modes your hardware supports with 
#cat /sys/power/mem_sleep
#my hw supports s2idle deep, the one currently active will be in [] but Asus laptops have bug where deep sleep causes the device to reset after 1 minute of waking up from deep sleep, so set to s2idle. 

MEM_SLEEP_ON_AC=s2idle
MEM_SLEEP_ON_BAT=s2idle

# Define disk devices on which the following DISK/AHCI_RUNTIME parameters act.
# Separate multiple devices with spaces.
# Devices can be specified by disk ID also (lookup with: tlp diskid).
# Default: "nvme0n1 sda"
#make sure to add or change this if you addmore ssds or change an exisiting ssd down the line.
#command: sudo tlp diskid
#block devices for my asus tuf f15 are, use these IDs in your configuration, which is a more robust method
#nvme0n1: nvme-INTEL_SSDPEKNU512GZ_BTKA151410KY512A
#nvme1n1: nvme-Samsung_SSD_980_1TB_S649NL0T857112D

DISK_DEVICES="nvme-INTEL_SSDPEKNU512GZ_BTKA151410KY512A nvme-Samsung_SSD_980_1TB_S649NL0T857112D"

# Disk advanced power management level: 1..254, 255 (max saving, min, off).
# Levels 1..127 may spin down the disk; 255 allowable on most drives.
# Separate values for multiple disks with spaces. Use the special value 'keep'
# to keep the hardware default for the particular disk.
# Default: 254 (AC), 128 (BAT)
# this is a legacy feature for HDD not SSD so leave this commented out. 
# if by a chance you have a spinning hardrive and you want to check if it supports Advanced power Managemet this is the command to run 
# sudo hdparm -I /dev/sda | grep "Advanced power management"
# to check your current hdd's parameters 
#sudo hdparm -B /dev/sda

#DISK_APM_LEVEL_ON_AC="254 254"
#DISK_APM_LEVEL_ON_BAT="128 128"

# Exclude disk classes from advanced power management (APM):
#   sata, ata, usb, ieee1394.
# Separate multiple classes with spaces.
# CAUTION: USB and IEEE1394 disks may fail to mount or data may get corrupted
# with APM enabled. Be careful and make sure you have backups of all affected
# media before removing 'usb' or 'ieee1394' from the denylist!
# Default: "usb ieee1394"

#DISK_APM_CLASS_DENYLIST="usb ieee1394"

# Hard disk spin down timeout:
#   0:        spin down disabled
#   1..240:   timeouts from 5s to 20min (in units of 5s)
#   241..251: timeouts from 30min to 5.5 hours (in units of 30min)
# See 'man hdparm' for details.
# Separate values for multiple disks with spaces. Use the special value 'keep'
# to keep the hardware default for the particular disk.
# Default: <none>

#DISK_SPINDOWN_TIMEOUT_ON_AC="0 0"
#DISK_SPINDOWN_TIMEOUT_ON_BAT="0 0"

# Select I/O scheduler for the disk devices.
# Multi queue (blk-mq) schedulers:
#   mq-deadline(*), none, kyber, bfq
# Single queue schedulers:
#   deadline(*), cfq, bfq, noop
# (*) recommended.
# Separate values for multiple disks with spaces. Use the special value 'keep'
# to keep the kernel default scheduler for the particular disk.
# Notes:
# - Multi queue (blk-mq) may need kernel boot option 'scsi_mod.use_blk_mq=1'
#   and 'modprobe mq-deadline-iosched|kyber|bfq' on kernels < 5.0
# - Single queue schedulers are legacy now and were removed together with
#   the old block layer in kernel 5.0
# Default: keep
#check all suported options for your block drive one by one with the folowing commaand make sure to change the block name with your block name before running the command : cat /sys/block/nvme0n1/queue/scheduler
#here are the options availabe on my drive samsung 980 and intel nvme 
#none mq-deadline [kyber] bfq
#setting it to none is teh best for nvme/ssd becuase it lets teh controller handle i/o and doesnt' require the kernal to engage and result in overhead and cpu cycles. the order of the values entered should coralate with the placement of each block drive above under "DISK_DEVICES" (ONLY RELEVENT IF YOU HAVE multiple drives.)

DISK_IOSCHED="none none"

# AHCI link power management (ALPM) for SATA disks:
#   min_power, med_power_with_dipm(*), medium_power, max_performance.
# (*) recommended.
# Multiple values separated with spaces are tried sequentially until success.
# Default: med_power_with_dipm (AC & BAT)

#SATA_LINKPWR_ON_AC="med_power_with_dipm"
#SATA_LINKPWR_ON_BAT="med_power_with_dipm"

# Exclude SATA links from AHCI link power management (ALPM).
# SATA links are specified by their host. Refer to the output of
# tlp-stat -d to determine the host; the format is "hostX".
# Separate multiple hosts with spaces.
# Default: <none>

#SATA_LINKPWR_DENYLIST="host1"

# Runtime Power Management for NVMe, SATA, ATA and USB disks
# as well as SATA ports:
#   on=disable, auto=enable.
# Note: SATA controllers are PCIe bus devices and handled by RUNTIME_PM
# further down.

# Default: on (AC), auto (BAT)
# this allow for power saving of the controller that manages power saving of other controllers for block devices to go into power saving mode when all the block drives are idle. 

AHCI_RUNTIME_PM_ON_AC=auto
AHCI_RUNTIME_PM_ON_BAT=auto

# Seconds of inactivity before disk is suspended.
# Note: effective only when AHCI_RUNTIME_PM_ON_AC/BAT is activated.
# Default: 15

AHCI_RUNTIME_PM_TIMEOUT=5

# Power off optical drive in UltraBay/MediaBay: 0=disable, 1=enable.
# Drive can be powered on again by releasing (and reinserting) the eject lever
# or by pressing the disc eject button on newer models.
# Note: an UltraBay/MediaBay hard disk is never powered off.
# Default: 0

#BAY_POWEROFF_ON_AC=0
#BAY_POWEROFF_ON_BAT=0

# Optical drive device to power off
# Default: sr0

#BAY_DEVICE="sr0"

# Set the min/max/turbo frequency for the Intel GPU.
# Possible values depend on your hardware. For available frequencies see
# the output of tlp-stat -g.
# Default: <none>
#to check your igpu's min and max values with: sudo tlp-stat -g : here are the results for asus tuf f15 12700H
#/sys/class/drm/card1/gt_min_freq_mhz         =   100 [MHz]
#/sys/class/drm/card1/gt_max_freq_mhz         =   600 [MHz]
#/sys/class/drm/card1/gt_boost_freq_mhz       =   800 [MHz]
#/sys/class/drm/card1/gt_RPn_freq_mhz         =   100 [MHz] (GPU min)
#/sys/class/drm/card1/gt_RP0_freq_mhz         =  1400 [MHz] (GPU max)

INTEL_GPU_MIN_FREQ_ON_AC=100
INTEL_GPU_MIN_FREQ_ON_BAT=100
INTEL_GPU_MAX_FREQ_ON_AC=800
INTEL_GPU_MAX_FREQ_ON_BAT=200
INTEL_GPU_BOOST_FREQ_ON_AC=1400
INTEL_GPU_BOOST_FREQ_ON_BAT=400

# AMD GPU power management.
# Performance level (DPM): auto, low, high; auto is recommended.
# Note: requires amdgpu or radeon driver.
# Default: auto

#RADEON_DPM_PERF_LEVEL_ON_AC=auto
#RADEON_DPM_PERF_LEVEL_ON_BAT=auto

# Dynamic power management method (DPM): balanced, battery, performance.
# Note: radeon driver only.
# Default: <none>

#RADEON_DPM_STATE_ON_AC=performance
#RADEON_DPM_STATE_ON_BAT=battery

# Display panel adaptive backlight modulation (ABM) level: 0(off), 1..4.
# Values 1..4 control the maximum brightness reduction allowed by the ABM
# algorithm, where 1 represents the least and 4 the most power saving.
# Notes:
# - Requires AMD Vega or newer GPU with amdgpu driver as of kernel 6.9
# - Savings are made at the expense of color balance
# Default: 0 (AC), 1 (BAT), 3 (SAV)

#AMDGPU_ABM_LEVEL_ON_AC=0
#AMDGPU_ABM_LEVEL_ON_BAT=1
#AMDGPU_ABM_LEVEL_ON_SAV=3

# Wi-Fi power saving mode: on=enable, off=disable.
# Default: off (AC), on (BAT)
#saves quite a bit of power when idiling. but may cause occational wifi connectivity issues. but it's a worth wile trade off given how much power it saves. 

WIFI_PWR_ON_AC=on
WIFI_PWR_ON_BAT=on

# Disable Wake-on-LAN: Y/N.
# Default: Y

#WOL_DISABLE=Y

# Enable audio power saving for Intel HDA, AC97 devices (timeout in secs).
# A value of 0 disables, >= 1 enables power saving.
# Note: 1 is recommended for Linux desktop environments with PulseAudio,
# systems without PulseAudio may require 10.
# Default: 1
#how long to wait in seconds until the audio ocntroller is put to rest, after no audio is playing.change this to 10 if you hear audio crackling or pops 

#SOUND_POWER_SAVE_ON_AC=1
#SOUND_POWER_SAVE_ON_BAT=1

# Disable controller too (HDA only): Y/N.
# Note: effective only when SOUND_POWER_SAVE_ON_AC/BAT is activated.
# Default: Y
#the audio subsystem has both a controller and a codec. The SOUND_POWER_SAVE_ON_AC/BAT parameter puts the codec to sleep. This parameter, SOUND_POWER_SAVE_CONTROLLER, takes the power saving a step further by allowing the controller on the PCIe bus to be powered down as well

#SOUND_POWER_SAVE_CONTROLLER=Y

# PCIe Active State Power Management (ASPM):
#   default(*), performance, powersave, powersupersave.
# (*) keeps BIOS ASPM defaults (recommended)
# Default: <none>
#CHANGE WITH CAUTION MAY CAUSE INSTIBILITY (TESTED ON MY ASUS PC TO NOT HAVE ISSUES. WITH powersupersave)
#ASPM is a power management protocol built into the PCIe standard. It allows a PCIe link between two devices (e.g., between the root complex in the CPU and an NVMe SSD) to be placed into a low-power state when it is not actively transmitting data. This happens at the physical layer of the PCIe link and is independent of the device's own internal power states. ASPM defines several link states:
#L0: The normal, fully active operational state.
#L0s: A low-power "standby" state with a very fast recovery time (sub-microsecond). It offers modest power savings.
#L1: A deeper sleep state with greater power savings but a longer recovery time (tens of microseconds).
#L1 Sub-states (L1.1, L1.2): Even lower power states that require coordination with the system's reference clock and main power rails, offering the greatest savings but also the longest latency to return to L0.
#The Linux kernel can manage ASPM via different policies:
#default: The kernel respects the policy configured by the system BIOS/UEFI. This is often the safest and most reliable option, as the platform vendor has presumably validated the BIOS settings for that specific hardware.
#performance: Disables ASPM entirely, keeping all PCIe links in the high-performance L0 state.
#powersave: Aggressively enables ASPM on all possible links, prioritizing power savings over latency.
#powersupersave: An even more aggressive version of powersave that attempts to enable the deeper L1 sub-states where supported.
#command to output the currenly set option : 
#cat /sys/module/pcie_aspm/parameters/policy

PCIE_ASPM_ON_AC=powersupersave
PCIE_ASPM_ON_BAT=powersupersave

# Runtime Power Management for PCIe bus devices: on=disable, auto=enable.
# Default: on (AC), auto (BAT)
#While ASPM manages the power state of the link, Runtime Power Management (RPM) manages the power state of the device at the end of the link. RPM allows the kernel to put an entire device into a low-power D-state (e.g., D3cold, where it is almost completely powered off) when it is idle.
#This is a global setting that TLP applies to PCIe devices

RUNTIME_PM_ON_AC=auto
RUNTIME_PM_ON_BAT=auto

# Exclude listed PCIe device adresses from Runtime PM.
# Note: this preserves the kernel driver default, to force a certain state
# use RUNTIME_PM_ENABLE/DISABLE instead.
# Separate multiple addresses with spaces.
# Use lspci to get the adresses (1st column).
# Default: <none>

#RUNTIME_PM_DENYLIST="11:22.3 44:55.6"

# Exclude PCIe devices assigned to the listed drivers from Runtime PM.
# Note: this preserves the kernel driver default, to force a certain state
# use RUNTIME_PM_ENABLE/DISABLE instead.
# Separate multiple drivers with spaces.
# Default: "mei_me nouveau radeon xhci_hcd", use "" to disable completely.

#RUNTIME_PM_DRIVER_DENYLIST="mei_me nouveau radeon xhci_hcd"

# Permanently enable/disable Runtime PM for listed PCIe device addresses
# (independent of the power source). This has priority over all preceding
# Runtime PM settings. Separate multiple addresses with spaces.
# Use lspci to get the adresses (1st column).
# Default: <none>

#RUNTIME_PM_ENABLE="11:22.3"
#RUNTIME_PM_DISABLE="44:55.6"

# Set to 0 to disable, 1 to enable USB autosuspend feature.
# Default: 1

#USB_AUTOSUSPEND=1

# Exclude listed devices from USB autosuspend (separate with spaces).
# Use lsusb to get the ids.
# Note: input devices (usbhid) and libsane-supported scanners are excluded
# automatically.
# Default: <none>

#USB_DENYLIST="1111:2222 3333:4444"

# Exclude audio devices from USB autosuspend:
#   0=do not exclude, 1=exclude.
# Default: 1

#USB_EXCLUDE_AUDIO=1

# Exclude bluetooth devices from USB autosuspend:
#   0=do not exclude, 1=exclude.
# Default: 0

#USB_EXCLUDE_BTUSB=0

# Exclude phone devices from USB autosuspend:
#   0=do not exclude, 1=exclude (enable charging).
# Default: 0

#USB_EXCLUDE_PHONE=0

# Exclude printers from USB autosuspend:
#   0=do not exclude, 1=exclude.
# Default: 1

#USB_EXCLUDE_PRINTER=1

# Exclude WWAN devices from USB autosuspend:
#   0=do not exclude, 1=exclude.
# Default: 0

#USB_EXCLUDE_WWAN=0

# Allow USB autosuspend for listed devices even if already denylisted or
# excluded above (separate with spaces). Use lsusb to get the ids.
# Default: 0

#USB_ALLOWLIST="1111:2222 3333:4444"

# Restore radio device state (Bluetooth, WiFi, WWAN) from previous shutdown
# on system startup: 0=disable, 1=enable.
# Note: the parameters DEVICES_TO_DISABLE/ENABLE_ON_STARTUP/SHUTDOWN below
# are ignored when this is enabled.
# Default: 0

#RESTORE_DEVICE_STATE_ON_STARTUP=0

# Radio devices to disable on startup: bluetooth, nfc, wifi, wwan.
# Separate multiple devices with spaces.
# Default: <none>

#DEVICES_TO_DISABLE_ON_STARTUP="bluetooth"

# Radio devices to enable on startup: bluetooth, nfc, wifi, wwan.
# Separate multiple devices with spaces.
# Default: <none>

DEVICES_TO_ENABLE_ON_STARTUP="wifi"

# Radio devices to enable on AC: bluetooth, nfc, wifi, wwan.
# Default: <none>

#DEVICES_TO_ENABLE_ON_AC="bluetooth nfc wifi wwan"

# Radio devices to disable on battery: bluetooth, nfc, wifi, wwan.
# Default: <none>

#DEVICES_TO_DISABLE_ON_BAT="bluetooth nfc wifi wwan"

# Radio devices to disable on battery when not in use (not connected):
#   bluetooth, nfc, wifi, wwan.
# Default: <none>

DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE="bluetooth"

# Battery Care -- Charge thresholds
# Charging starts when the charger is connected and the charge level
# is below the start threshold. Charging stops when the charge level
# is above the stop threshold.
# Required hardware: Lenovo ThinkPads and other laptop brands are driven
#   via specific plugins:
# - Use the tlp-stat -b command to see if a plugin for your hardware is
#   active and to look up vendor-specific threshold values. Some
#   laptops support only 1 (on)/0 (off) instead of a percentage level.
# - If your hardware supports a start *and* a stop threshold, you must
#   specify both, otherwise TLP will refuse to apply the single threshold.
# - If your hardware supports only a stop threshold, set the start
#   value to 0.
# - The names of the batteries shown by tlp-stat -b don't have to match
#   the _BAT0 or _BAT1 parameter qualifiers. Please refer to [2]
#   to see which qualifier applies to which battery.
# For further explanation and all vendor specific details refer to
# [1] https://linrunner.de/tlp/settings/battery.html
# [2] https://linrunner.de/tlp/settings/bc-vendors.html

# BAT0: Main battery
# Default: <none>

# Battery charge level below which charging will begin.
#START_CHARGE_THRESH_BAT0=75
# Battery charge level above which charging will stop.
#STOP_CHARGE_THRESH_BAT0=80

# BAT1: Secondary battery (primary on some laptops)
# Default: <none>

# Battery charge level below which charging will begin.
START_CHARGE_THRESH_BAT1=0
# Battery charge level above which charging will stop.
STOP_CHARGE_THRESH_BAT1=75

# Restore charge thresholds when AC is unplugged: 0=disable, 1=enable.
# Default: 0

#RESTORE_THRESHOLDS_ON_BAT=1

# ----------------------------------------------------------------------------
# tlp-rdw - Radio Device Wizard
# Note: requires installation of the optional package tlp-rdw.

# Possible devices: bluetooth, wifi, wwan.
# Separate multiple radio devices with spaces.
# Default: <none> (for all parameters below)

# Radio devices to disable on connect.

#DEVICES_TO_DISABLE_ON_LAN_CONNECT="wifi wwan"
#DEVICES_TO_DISABLE_ON_WIFI_CONNECT="wwan"
#DEVICES_TO_DISABLE_ON_WWAN_CONNECT="wifi"

# Radio devices to enable on disconnect.

#DEVICES_TO_ENABLE_ON_LAN_DISCONNECT="wifi wwan"
#DEVICES_TO_ENABLE_ON_WIFI_DISCONNECT=""
#DEVICES_TO_ENABLE_ON_WWAN_DISCONNECT=""

# Radio devices to enable/disable when docked.
# Note: not all docks can be recognized, especially USB-C docks. If a LAN
# cable is connected to the dock, use DEVICES_TO_DISABLE_ON_LAN_CONNECT
# and DEVICES_TO_ENABLE_ON_LAN_DISCONNECT instead.

#DEVICES_TO_ENABLE_ON_DOCK=""
#DEVICES_TO_DISABLE_ON_DOCK=""

# Radio devices to enable/disable when undocked.

#DEVICES_TO_ENABLE_ON_UNDOCK="wifi"
#DEVICES_TO_DISABLE_ON_UNDOCK=""
```