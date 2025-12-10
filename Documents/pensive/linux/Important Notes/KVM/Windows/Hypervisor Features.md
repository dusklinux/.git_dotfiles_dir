Hypervisor features

Hypervisors may allow certain CPU / machine features to be toggled on/off.


```ini
<features>
  <pae/>
  <acpi/>
  <apic/>
  <hap/>
  <privnet/>
  <hyperv mode='custom'>
    <relaxed state='on'/>
    <vapic state='on'/>
    <spinlocks state='on' retries='4096'/>
    <vpindex state='on'/>
    <runtime state='on'/>
    <synic state='on'/>
    <stimer state='on'>
      <direct state='on'/>
    </stimer>
    <reset state='on'/>
    <vendor_id state='on' value='KVM Hv'/>
    <frequencies state='on'/>
    <reenlightenment state='on'/>
    <tlbflush state='on'>
      <direct state='on'/>
      <extended state='on'/>
    </tlbflush>
    <ipi state='on'/>
    <evmcs state='on'/>
    <emsr_bitmap state='on'/>
    <xmm_input state='on'/>
  </hyperv>
  <kvm>
    <hidden state='on'/>
    <hint-dedicated state='on'/>
    <poll-control state='on'/>
    <pv-ipi state='off'/>
    <dirty-ring state='on' size='4096'/>
  </kvm>
  <xen>
    <e820_host state='on'/>
    <passthrough state='on' mode='share_pt'/>
  </xen>
  <pvspinlock state='on'/>
  <gic version='2'/>
  <ioapic driver='qemu'/>
  <hpt resizing='required'>
    <maxpagesize unit='MiB'>16</maxpagesize>
  </hpt>
  <vmcoreinfo state='on'/>
  <smm state='on'>
    <tseg unit='MiB'>48</tseg>
  </smm>
  <htm state='on'/>
  <ccf-assist state='on'/>
  <msrs unknown='ignore'/>
  <cfpc value='workaround'/>
  <sbbc value='workaround'/>
  <ibs value='fixed-na'/>
  <tcg>
    <tb-cache unit='MiB'>128</tb-cache>
  </tcg>
  <async-teardown enabled='yes'/>
  <ras state='on'/>
  <ps2 state='on'/>
  <aia value='aplic-imsic'/>
</features>
```

All features are listed within the features element, omitting a togglable feature tag turns it off. The available features can be found by asking for the capabilities XML and domain capabilities XML, but a common set for fully virtualized domains are:

pae

    Physical address extension mode allows 32-bit guests to address more than 4 GB of memory.
acpi

    ACPI is useful for power management, for example, with KVM or HVF guests it is required for graceful shutdown to work.
apic

    APIC allows the use of programmable IRQ management. Since 0.10.2 (QEMU only) there is an optional attribute eoi with values on and off which toggles the availability of EOI (End of Interrupt) for the guest.
hap

    Depending on the state attribute (values on, off) enable or disable use of Hardware Assisted Paging. The default is on if the hypervisor detects availability of Hardware Assisted Paging.
viridian

    Enable Viridian hypervisor extensions for paravirtualizing guest operating systems
privnet

    Always create a private network namespace. This is automatically set if any interface devices are defined. This feature is only relevant for container based virtualization drivers, such as LXC.
hyperv

    Enable various features improving behavior of guests running Microsoft Windows. Since 11.3.0 some of these flags are also available for Xen domains running Microsoft Windows.

    Feature
    	

    Description
    	

    Value
    	

    Since

    relaxed
    	

    Relax constraints on timers
    	

    on, off
    	

    1.0.0 (QEMU 2.0), 11.3.0 (Xen, always on)

    vapic
    	

    Enable virtual APIC
    	

    on, off
    	

    1.1.0 (QEMU 2.0), 11.3.0 (Xen)

    spinlocks
    	

    Enable spinlock support
    	

    on, off; retries - at least 4095
    	

    1.1.0 (QEMU 2.0)

    vpindex
    	

    Virtual processor index
    	

    on, off
    	

    1.3.3 (QEMU 2.5), 11.3.0 (Xen, always on)

    runtime
    	

    Processor time spent on running guest code and on behalf of guest code
    	

    on, off
    	

    1.3.3 (QEMU 2.5)

    synic
    	

    Enable Synthetic Interrupt Controller (SynIC)
    	

    on, off
    	

    1.3.3 (QEMU 2.6), 11.3.0 (Xen)

    stimer
    	

    Enable SynIC timers, optionally with Direct Mode support
    	

    on, off; direct - on,off
    	

    1.3.3 (QEMU 2.6), direct mode 5.7.0 (QEMU 4.1), 11.3.0 (Xen, on/off only)

    reset
    	

    Enable hypervisor reset
    	

    on, off
    	

    1.3.3 (QEMU 2.5)

    vendor_id
    	

    Set hypervisor vendor id
    	

    on, off; value - string, up to 12 characters
    	

    1.3.3 (QEMU 2.5)

    frequencies
    	

    Expose frequency MSRs
    	

    on, off
    	

    4.7.0 (QEMU 2.12), 11.3.0 (Xen)

    reenlightenment
    	

    Enable re-enlightenment notification on migration
    	

    on, off
    	

    4.7.0 (QEMU 3.0)

    tlbflush
    	

    Enable PV TLB flush support
    	

    on, off; direct - on,off; extended - on,off
    	

    4.7.0 (QEMU 3.0), direct and extended modes 11.0.0 (QEMU 7.1.0), 11.3.0 (Xen, on/off only)

    ipi
    	

    Enable PV IPI support
    	

    on, off
    	

    4.10.0 (QEMU 3.1), 11.3.0 (Xen)

    evmcs
    	

    Enable Enlightened VMCS
    	

    on, off
    	

    4.10.0 (QEMU 3.1)

    avic
    	

    Enable use Hyper-V SynIC with hardware APICv/AVIC
    	

    on, off
    	

    8.10.0 (QEMU 6.2)

    emsr_bitmap
    	

    Avoid unnecessary updates to L2 MSR Bitmap upon vmexits.
    	

    on, off
    	

    10.7.0 (QEMU 7.1)

    xmm_input
    	

    Enable XMM Fast Hypercall Input
    	

    on, off
    	

    10.7.0 (QEMU 7.1)

    Since 8.0.0 (QEMU) Since 11.3.0 (Xen), the hypervisor can be configured further by setting the mode attribute to one of the following values:

    custom

        Set exactly the specified features.
    passthrough

        Enable all features currently supported by the hypervisor, even those that libvirt does not understand. Migration of a guest using passthrough is dangerous if the source and destination hosts are not identical in both hardware, QEMU version, microcode version and configuration. If such a migration is attempted then the guest may hang or crash upon resuming execution on the destination host. Depending on hypervisor version the virtual CPU may or may not contain features which may block migration even to an identical host.

    The mode attribute can be omitted and will default to custom.
pvspinlock

    Notify the guest that the host supports paravirtual spinlocks for example by exposing the pvticketlocks mechanism. This feature can be explicitly disabled by using state='off' attribute.
kvm

    Various features to change the behavior of the KVM hypervisor.

    Feature
    	

    Description
    	

    Value
    	

    Since

    hidden
    	

    Hide the KVM hypervisor from standard MSR based discovery
    	

    on, off
    	

    1.2.8 (QEMU 2.1.0)

    hint-dedicated
    	

    Allows a guest to enable optimizations when running on dedicated vCPUs
    	

    on, off
    	

    5.7.0 (QEMU 2.12.0)

    poll-control
    	

    Decrease IO completion latency by introducing a grace period of busy waiting
    	

    on, off
    	

    6.10.0 (QEMU 4.2)

    pv-ipi
    	

    Paravirtualized send IPIs
    	

    on, off
    	

    7.10.0 (QEMU 3.1)

    dirty-ring
    	

    Enable dirty ring feature
    	

    on, off; size - must be power of 2, range [1024,65536]
    	

    8.0.0 (QEMU 6.1)
xen

    Various features to change the behavior of the Xen hypervisor.

    Feature
    	

    Description
    	

    Value
    	

    Since

    e820_host
    	

    Expose the host e820 to the guest (PV only)
    	

    on, off
    	

    6.3.0

    passthrough
    	

    Enable IOMMU mappings allowing PCI passthrough
    	

    on, off; mode - optional string sync_pt or share_pt
    	

    6.3.0
pmu

    Depending on the state attribute (values on, off, default on) enable or disable the performance monitoring unit for the guest. Since 1.2.12
vmport

    Depending on the state attribute (values on, off, default on) enable or disable the emulation of VMware IO port, for vmmouse etc. Since 1.2.16
gic

    Enable for architectures using a General Interrupt Controller instead of APIC in order to handle interrupts. For example, the 'aarch64' architecture uses gic instead of apic. The optional attribute version specifies the GIC version; however, it may not be supported by all hypervisors. Accepted values are 2, 3 and host. Since 1.2.16
smm

    Depending on the state attribute (values on, off, default on) enable or disable System Management Mode. Since 2.1.0

    Optional sub-element tseg can be used to specify the amount of memory dedicated to SMM's extended TSEG. That offers a fourth option size apart from the existing ones (1 MiB, 2 MiB and 8 MiB) that the guest OS (or rather loader) can choose from. The size can be specified as a value of that element, optional attribute unit can be used to specify the unit of the aforementioned value (defaults to 'MiB'). If set to 0 the extended size is not advertised and only the default ones (see above) are available.

    If the VM is booting you should leave this option alone, unless you are very certain you know what you are doing.

    This value is configurable due to the fact that the calculation cannot be done right with the guarantee that it will work correctly. In QEMU, the user-configurable extended TSEG feature was unavailable up to and including pc-q35-2.9. Starting with pc-q35-2.10 the feature is available, with default size 16 MiB. That should suffice for up to roughly 272 vCPUs, 5 GiB guest RAM in total, no hotplug memory range, and 32 GiB of 64-bit PCI MMIO aperture. Or for 48 vCPUs, with 1TB of guest RAM, no hotplug DIMM range, and 32GB of 64-bit PCI MMIO aperture. The values may also vary based on the loader the VM is using.

    Additional size might be needed for significantly higher vCPU counts or increased address space (that can be memory, maxMemory, 64-bit PCI MMIO aperture size; roughly 8 MiB of TSEG per 1 TiB of address space) which can also be rounded up.

    Due to the nature of this setting being similar to "how much RAM should the guest have" users are advised to either consult the documentation of the guest OS or loader (if there is any), or test this by trial-and-error changing the value until the VM boots successfully. Yet another guiding value for users might be the fact that 48 MiB should be enough for pretty large guests (240 vCPUs and 4TB guest RAM), but it is on purpose not set as default as 48 MiB of unavailable RAM might be too much for small guests (e.g. with 512 MiB of RAM).

    See Memory Allocation for more details about the unit attribute. Since 4.5.0 (QEMU only)
ioapic

    Tune the I/O APIC. Possible values for the driver attribute are: kvm (default for KVM domains) and qemu which puts I/O APIC in userspace which is also known as a split I/O APIC mode. Since 3.4.0 (QEMU/KVM only)
hpt

    Configure the HPT (Hash Page Table) of a pSeries guest. Possible values for the resizing attribute are enabled, which causes HPT resizing to be enabled if both the guest and the host support it; disabled, which causes HPT resizing to be disabled regardless of guest and host support; and required, which prevents the guest from starting unless both the guest and the host support HPT resizing. If the attribute is not defined, the hypervisor default will be used. Since 3.10.0 (QEMU/KVM only).

    The optional maxpagesize subelement can be used to limit the usable page size for HPT guests. Common values are 64 KiB, 16 MiB and 16 GiB; when not specified, the hypervisor default will be used. Since 4.5.0 (QEMU/KVM only).
vmcoreinfo

    Enable QEMU vmcoreinfo device to let the guest kernel save debug details. Since 4.4.0 (QEMU only)
htm

    Configure HTM (Hardware Transactional Memory) availability for pSeries guests. Possible values for the state attribute are on and off. If the attribute is not defined, the hypervisor default will be used. Since 4.6.0 (QEMU/KVM only)
nested-hv

    Configure nested HV availability for pSeries guests. This needs to be enabled from the host (L0) in order to be effective; having HV support in the (L1) guest is very desirable if it's planned to run nested (L2) guests inside it, because it will result in those nested guests having much better performance than they would when using KVM PR or TCG. Possible values for the state attribute are on and off. If the attribute is not defined, the hypervisor default will be used. Since 4.10.0 (QEMU/KVM only)
msrs

    Some guests might require ignoring unknown Model Specific Registers (MSRs) reads and writes. It's possible to switch this by setting unknown attribute of msrs to ignore. If the attribute is not defined, or set to fault, unknown reads and writes will not be ignored. Since 5.1.0 (bhyve only)
ccf-assist

    Configure ccf-assist (Count Cache Flush Assist) availability for pSeries guests. Possible values for the state attribute are on and off. If the attribute is not defined, the hypervisor default will be used. Since 5.9.0 (QEMU/KVM only)
cfpc

    Configure cfpc (Cache Flush on Privilege Change) availability for pSeries guests. Possible values for the value attribute are broken (no protection), workaround (software workaround available) and fixed (fixed in hardware). If the attribute is not defined, the hypervisor default will be used. Since 6.3.0 (QEMU/KVM only)
sbbc

    Configure sbbc (Speculation Barrier Bounds Checking) availability for pSeries guests. Possible values for the value attribute are broken (no protection), workaround (software workaround available) and fixed (fixed in hardware). If the attribute is not defined, the hypervisor default will be used. Since 6.3.0 (QEMU/KVM only)
ibs

    Configure ibs (Indirect Branch Speculation) availability for pSeries guests. Possible values for the value attribute are broken (no protection), workaround (count cache flush), fixed-ibs (fixed by serializing indirect branches), fixed-ccd (fixed by disabling the cache count) and fixed-na (fixed in hardware - no longer applicable). If the attribute is not defined, the hypervisor default will be used. Since 6.3.0 (QEMU/KVM only)
tcg

    Various features to change the behavior of the TCG accelerator.

    Feature
    	

    Description
    	

    Value
    	

    Since

    tb-cache
    	

    The size of translation block cache size
    	

    an integer (a multiple of MiB)
    	

    8.0.0
async-teardown

    Depending on the enabled attribute (values yes, no) enable or disable QEMU asynchronous teardown to improve memory reclaiming on a guest. Since 9.6.0 (QEMU only)
ras

    Report host memory errors to a guest using ACPI and guest external abort exceptions when enabled (on). If the attribute is not defined, the hypervisor default will be used. Since 10.4.0 (QEMU/KVM and ARM virt guests only)
ps2

    Depending on the state attribute (values on, off) enable or disable the emulation of a PS/2 controller used by ps2 bus input devices. If the attribute is not defined, the hypervisor default will be used. Since 10.7.0 (QEMU only)
aia

    Configure aia (Advanced Interrupt Architecture) for RISC-V 'virt' guests. Possible values for the value attribute are aplic (one emulated APLIC device present per socket), aplic-imsic (one APLIC and one IMSIC device present per core), or none (no support for AIA). If the attribute is not defined, the hypervisor default will be used. Since 11.1.0 (QEMU/KVM and RISC-V guests only)
