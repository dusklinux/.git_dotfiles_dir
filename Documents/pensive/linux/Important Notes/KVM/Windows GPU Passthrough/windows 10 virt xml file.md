> [!NOTE] replace the overview xml with this. 
> ```ini
> <domain type="kvm">
>   <name>win10</name>
>   <uuid>5fb07cd7-762b-4d64-97ef-e22a8f32b1fa</uuid>
>   <metadata>
>     <libosinfo:libosinfo xmlns:libosinfo="http://libosinfo.org/xmlns/libvirt/domain/1.0">
>       <libosinfo:os id="http://microsoft.com/win/10"/>
>     </libosinfo:libosinfo>
>   </metadata>
>   <memory>41058304</memory>
>   <currentMemory>41058304</currentMemory>
>   <memoryBacking>
>     <source type="memfd"/>
>     <access mode="shared"/>
>   </memoryBacking>
>   <vcpu current="12">12</vcpu>
>   <os firmware="efi">
>     <type arch="x86_64" machine="q35">hvm</type>
>     <boot dev="hd"/>
>   </os>
>   <features>
>     <acpi/>
>     <apic/>
>     <hyperv>
>       <relaxed state="on"/>
>       <vapic state="on"/>
>       <spinlocks state="on" retries="8191"/>
>       <vpindex state="on"/>
>       <runtime state="on"/>
>       <synic state="on"/>
>       <stimer state="on"/>
>       <frequencies state="on"/>
>       <tlbflush state="on"/>
>       <ipi state="on"/>
>       <evmcs state="on"/>
>       <avic state="on"/>
>     </hyperv>
>     <vmport state="off"/>
>   </features>
>   <cpu mode="host-passthrough">
>     <topology sockets="1" cores="6" threads="2"/>
>   </cpu>
>   <clock offset="localtime">
>     <timer name="rtc" tickpolicy="catchup"/>
>     <timer name="pit" tickpolicy="delay"/>
>     <timer name="hpet" present="no"/>
>     <timer name="hypervclock" present="yes"/>
>   </clock>
>   <pm>
>     <suspend-to-mem enabled="no"/>
>     <suspend-to-disk enabled="no"/>
>   </pm>
>   <devices>
>     <emulator>/usr/bin/qemu-system-x86_64</emulator>
>     <disk type="file" device="disk">
>       <driver name="qemu" type="qcow2" cache="none" discard="unmap"/>
>       <source file="/var/lib/libvirt/images/win10.qcow2"/>
>       <target dev="vda" bus="virtio"/>
>     </disk>
>     <disk type="file" device="cdrom">
>       <driver name="qemu" type="raw"/>
>       <source file="/mnt/zram1/NTLite.iso"/>
>       <target dev="sdb" bus="sata"/>
>       <readonly/>
>     </disk>
>     <disk type="file" device="cdrom">
>       <driver name="qemu" type="raw"/>
>       <source file="/mnt/zram1/virtio-win-0.1.285.iso"/>
>       <target dev="sdc" bus="sata"/>
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
>     <filesystem type="mount">
>       <source dir="/mnt/zram1"/>
>       <target dir="host_zram"/>
>       <driver type="virtiofs"/>
>     </filesystem>
>     <interface type="bridge">
>       <source bridge="virbr0"/>
>       <mac address="52:54:00:f8:33:98"/>
>       <model type="virtio"/>
>     </interface>
>     <console type="pty"/>
>     <channel type="spicevmc">
>       <target type="virtio" name="com.redhat.spice.0"/>
>     </channel>
>     <graphics type="spice" port="-1" tlsPort="-1" autoport="yes">
>       <image compression="off"/>
>     </graphics>
>     <sound model="ich9"/>
>     <video>
>       <model type="qxl"/>
>     </video>
>     <hostdev mode="subsystem" type="pci" managed="yes">
>       <source>
>         <address domain="0" bus="1" slot="0" function="0"/>
>       </source>
>     </hostdev>
>     <hostdev mode="subsystem" type="pci" managed="yes">
>       <source>
>         <address domain="0" bus="1" slot="0" function="1"/>
>       </source>
>     </hostdev>
>     <redirdev bus="usb" type="spicevmc"/>
>     <redirdev bus="usb" type="spicevmc"/>
>     <input type="tablet" bus="usb"/>
>   </devices>
> </domain>
> ```