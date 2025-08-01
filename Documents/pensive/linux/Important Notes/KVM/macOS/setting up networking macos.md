There are two main ways to set up networking on OS X / macOS, as it does not
function with what QEMU defaults to for network settings:

-----------------------------------
User Mode Networking (Easier Setup)
-----------------------------------

By default, QEMU uses user mode networking (SLiRP). This networking mode is the
slowest and is not visible via the outside network, but requires no host-side
setup, so it's perfect if you just want internet but don't care about latency
or about connecting to the VM from an external source.

In order to do this, change the line in your qemu-system-x86_64 command (found
in boot-macOS.sh) to the following:

-netdev user,id=net0 -device network_adapter,netdev=net0,id=net0,mac=52:54:00:c9:18:27 \

Once you set network_adapter to the preferred adapter, no further setup is required; your
internet should Just Werk™ in your virtual machine!

For further information on detailed configuration options, see QEMU's
documentation on networking ( http://wiki.qemu.org/Documentation/Networking )

Here is the list of network adapters supported by macOS,

e1000-82545em - The problem that we run into here is that OS X is nitpicky
about what emulated networking devices it is willing to accept. The
e1000-82545em is a known adapter that can be used on pretty much any version of
MacOS.

To use this adapter, replace network_adapter with e1000-82545em

vmxnet3,virtio-net-pci - An alternative solution to e1000. Instead of emulating
the e1000, these are paravirtualized NICs, which can allow for better
performance (in theory). The only catch is that the you need to have a recent
version of MacOS (10.11 or later).

To use these adapters, replace network_adapter with vmxnet3 or virtio-net-pci.


SSH access in user mode
-----------------------

Although the IP address of the VM is not visible to the outside, it is possible
to use port forwarding to access the VM's ports from your host, eg the SSH port.
To achieve that:

- In MacOS, turn on SSH under System Preferences > Sharing > Remote Login.
- Modify the startup script to include `-netdev user,id=net0,hostfwd=tcp::10022-:22`
- Use `ssh localhost -p10022` to get in.

You can use the same for VNC.

-----------------------------------
Tap Networking (Better Performance)
-----------------------------------

Installing "virt-manager" automagically creates the "virbr0" local private bridge :-)

sudo apt-get install uml-utilities virt-manager

sudo ip tuntap add dev tap0 mode tap
sudo ip link set tap0 up promisc on
sudo ip link set dev tap0 master virbr0

sudo ip link set dev virbr0 up  # as needed
sudo ip link set dev tap0 master virbr0

Note: If `virbr0` network interface is not present on your system, it may
have been deactivated. Try enabling it by using the following commands,

virsh net-start default
virsh net-autostart default

Add "-netdev tap,id=net0,ifname=tap0,script=no,downscript=no -device e1000-82545em,netdev=net0,id=net0,mac=52:54:00:c9:18:27 \"
to your qemu-system-x86_64 command.


Using an rc.local startup script
--------------------------------

I have the following commands present in `/etc/rc.local`.

#!/usr/bin/env bash
sudo ip tuntap add dev tap0 mode tap
sudo ip link set tap0 up promisc on
sudo ip link set dev virbr0 up
sudo ip link set dev tap0 master virbr0

This has been enough for me so far.

Note: You may need to enable the `rc.local` functionality manually on modern
Ubuntu versions. Check out the [[all notes macos]] included in this repository
for details.


QEMU networking tip
-------------------

# printf '52:54:00:AB:%02X:%02X\n' $((RANDOM%256)) $((RANDOM%256))  # generates QEMU compatible mac addresses!


------------------
Bridged Networking
------------------

QEMU defaults to using NAT for its guests. It has a built-in DHCP server that
provides addresses from the 192.168.12x.0 subnet. However, this configuration
makes file sharing, printer sharing, and other common networking activities
harder to use in a home network.

Bridged networking allows your QEMU guest to get an address on the same subnet
as the host computer. For example, many home networks let the wireless router
handle IP assignment via DHCP. Here are the steps for setting up the bridge.

To setup bridged networking from the command line, refer to this documentation
at the Ubuntu website. https://help.ubuntu.com/community/KVM/Networking

Ultimately, the script for booting the QEMU guest will need a line similar to
the following to enable bridged networking in the guest:

    -netdev bridge,id=net0,br=virbr0,"helper=/usr/lib/qemu/qemu-bridge-helper"

On some systems the `qemu-bridge-helper` file has incorrect permissions. For it
to work, it needs to be setuid root. This can be accomplished with this command:

    $ sudo chmod u+s /usr/lib/qemu/qemu-bridge-helper

Note that this is sometimes viewed as a security hole. Be careful and understand
what you are doing before running this command.


-----------------------
Bridged Networking 2023
-----------------------

sudo mkdir -p /etc/qemu

sudo cp bridge.conf /etc/qemu

sudo chmod u+s /usr/lib/qemu/qemu-bridge-helper

sudo ip link add name br0 type bridge

sudo ip link set dev br0 up

sudo ip link set enx00e04c680a67 master br0 && sudo dhclient br0

$ brctl show
bridge name	bridge id		STP enabled	interfaces
br0		8000.ead0ee60b7c1	yes		enx00e04c680a67
							tap0
Use the following network device in scripts:

-netdev bridge,id=net0,br=br0,"helper=/usr/lib/qemu/qemu-bridge-helper" -device virtio-net-pci,netdev=net0,id=net0,mac=00:16:CB:00:11:34

Also see https://dortania.github.io/OpenCore-Post-Install/universal/iservices.html to tweak the config.plist file.