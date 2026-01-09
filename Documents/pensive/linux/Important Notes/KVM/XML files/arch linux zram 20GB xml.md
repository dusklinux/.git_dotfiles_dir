> [!NOTE] xml arch linux zram bridged 20gb
> ```ini
> <domain type="kvm">
>   <name>archlinux</name>
>   <uuid>6c5386d1-872e-41d7-bafc-24759542a5e6</uuid>
>   <metadata>
>     <libosinfo:libosinfo xmlns:libosinfo="http://libosinfo.org/xmlns/libvirt/domain/1.0">
>       <libosinfo:os id="http://archlinux.org/archlinux/rolling"/>
>     </libosinfo:libosinfo>
>   </metadata>
>   <memory>6168576</memory>
>   <currentMemory>6168576</currentMemory>
>   <memoryBacking>
>     <source type="memfd"/>
>     <access mode="shared"/>
>   </memoryBacking>
>   <vcpu>6</vcpu>
>   <os firmware="efi">
>     <type arch="x86_64" machine="q35">hvm</type>
>     <boot dev="hd"/>
>   </os>
>   <features>
>     <acpi/>
>     <apic/>
>     <vmport state="off"/>
>   </features>
>   <cpu mode="host-passthrough"/>
>   <clock offset="utc">
>     <timer name="rtc" tickpolicy="catchup"/>
>     <timer name="pit" tickpolicy="delay"/>
>     <timer name="hpet" present="no"/>
>   </clock>
>   <pm>
>     <suspend-to-mem enabled="no"/>
>     <suspend-to-disk enabled="no"/>
>   </pm>
>   <devices>
>     <emulator>/usr/bin/qemu-system-x86_64</emulator>
>     <disk type="file" device="disk">
>       <driver name="qemu" type="qcow2" cache="none" discard="unmap"/>
>       <source file="/mnt/zram1/archlinux.qcow2"/>
>       <target dev="vda" bus="virtio"/>
>     </disk>
>     <disk type="file" device="cdrom">
>       <driver name="qemu" type="raw"/>
>       <source file="/mnt/zram1/archlinux.iso"/>
>       <target dev="sda" bus="sata"/>
>       <readonly/>
>     </disk>
>     <controller type="usb" model="qemu-xhci" ports="15"/>
>     <controller type="pci" model="pcie-root"/>
>     <controller type="pci" model="pcie-root-port"/>
>     <controller type="pci" model="pcie-root-port"/>
>     <controller type="pci" model="pcie-root-port"/>
>     <controller type="pci" model="pcie-root-port"/>
>     <controller type="pci" model="pcie-root-port"/>
>     <controller type="pci" model="pcie-root-port"/>
>     <controller type="pci" model="pcie-root-port"/>
>     <controller type="pci" model="pcie-root-port"/>
>     <controller type="pci" model="pcie-root-port"/>
>     <controller type="pci" model="pcie-root-port"/>
>     <controller type="pci" model="pcie-root-port"/>
>     <controller type="pci" model="pcie-root-port"/>
>     <controller type="pci" model="pcie-root-port"/>
>     <controller type="pci" model="pcie-root-port"/>
>     <interface type="bridge">
>       <source bridge="virbr0"/>
>       <mac address="52:54:00:48:16:46"/>
>       <model type="virtio"/>
>     </interface>
>     <console type="pty"/>
>     <channel type="unix">
>       <source mode="bind"/>
>       <target type="virtio" name="org.qemu.guest_agent.0"/>
>     </channel>
>     <channel type="spicevmc">
>       <target type="virtio" name="com.redhat.spice.0"/>
>     </channel>
>     <input type="tablet" bus="usb"/>
>     <graphics type="spice" port="-1" tlsPort="-1" autoport="yes">
>       <image compression="off"/>
>     </graphics>
>     <sound model="ich9"/>
>     <video>
>       <model type="virtio"/>
>     </video>
>     <redirdev bus="usb" type="spicevmc"/>
>     <redirdev bus="usb" type="spicevmc"/>
>     <memballoon model="virtio"/>
>     <rng model="virtio">
>       <backend model="random">/dev/urandom</backend>
>     </rng>
>   </devices>
> </domain>
> ```