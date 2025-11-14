A libvirt deployment for accessing one of the stateful drivers will require one or more daemons to be deployed on the virtualization host. There are a number of ways the daemons can be configured which will be outlined in this page.
Architectural options
Monolithic vs modular daemons

Traditionally libvirt provided a single monolithic daemon called libvirtd which exposed support for all the stateful drivers, both primary hypervisor drivers and secondary supporting drivers. It also enables secure remote access from clients running off host.

Work is underway for the monolithic daemon to be replaced by a new set of modular daemons virt${DRIVER}d, each one servicing a single stateful driver. A further virtproxyd daemon will provide secure remote access, as well as backcompatibility for clients using the UNIX socket path of the monolithic daemon.

The change to modular daemons should not affect API functionality used by management applications. It will, however, have an impact on host provisioning tools since there are new systemd services and configuration files to be managed.

Currently both monolithic and modular daemons are built by default, but the RPC client still prefers connecting to the monolithic daemon. It is intended to switch the RPC client to prefer the modular daemons in the near future. At least 1 year after this switch (but not more than 2 years), the monolithic daemon will be deleted entirely.
Operating modes

The libvirt daemons, whether monolithic or modular, can often operate in two modes

    System mode - the daemon is running as the root user account, enabling access to its full range of functionality. A read-write connection to daemons in system mode typically implies privileges equivalent to having a root shell. Suitable authentication mechanisms must be enabled to secure it against untrustworthy clients/users.

    Session mode - the daemon is running as any non-root user account, providing access to a more restricted range of functionality. Only client apps/users running under the same UID are permitted to connect, thus a connection does not imply any elevation of privileges.

    Not all drivers support session mode and as such the corresponding modular daemon may not support running in this mode

Monolithic driver daemon

The monolithic daemon is known as libvirtd and has historically been the default in libvirt. It is configured via the file /etc/libvirt/libvirtd.conf
Monolithic sockets

When running in system mode, libvirtd exposes three UNIX domain sockets, and optionally, one or two TCP sockets:

    /var/run/libvirt/libvirt-sock - the primary socket for accessing libvirt APIs, with full read-write privileges. A connection to this socket gives the client privileges that are equivalent to having a root shell. This is the socket that most management applications connect to by default.

    /var/run/libvirt/libvirt-sock-ro - the secondary socket for accessing libvirt APIs, with limited read-only privileges. A connection to this socket gives the ability to query the existence of objects and monitor some aspects of their operation. This is the socket that most management applications connect to when requesting read only mode. Typically this is what a monitoring app would use.

    /var/run/libvirt/libvirt-admin-sock - the administrative socket for controlling operation of the daemon itself (as opposed to drivers it is running). This can be used to dynamically reconfigure some aspects of the daemon and monitor/control connected clients.

    TCP 16509 - the non-TLS socket for remotely accessing the libvirt APIs, with full read-write privileges. A connection to this socket gives the client privileges that are equivalent to having a root shell. Since it does not use TLS, an authentication mechanism that provides encryption must be used. Only the GSSAPI/Kerberos mechanism is capable of satisfying this requirement. In general applications should not use this socket except for debugging in a development/test environment.

    TCP 16514 - the TLS socket for remotely accessing the libvirt APIs, with full read-write privileges. A connection to this socket gives the client privileges that are equivalent to having a root shell. Access control can be enforced either through validation of x509 certificates, and/or by enabling an authentication mechanism.

NB, some distros will use /run instead of /var/run.

When running in session mode, libvirtd exposes two UNIX domain sockets:

    $XDG_RUNTIME_DIR/libvirt/libvirt-sock - the primary socket for accessing libvirt APIs, with full read-write privileges. A connection to this socket does not alter the privileges that the client already has. This is the socket that most management applications connect to by default.

    $XDG_RUNTIME_DIR/libvirt/libvirt-admin-sock - the administrative socket for controlling operation of the daemon itself (as opposed to drivers it is running). This can be used to dynamically reconfigure some aspects of the daemon and monitor/control connected clients.

Notice that the session mode does not have a separate read-only socket. Since the clients must be running as the same user as the daemon itself, there is not any security benefit from attempting to enforce a read-only mode.

$XDG_RUNTIME_DIR commonly points to a per-user private location on tmpfs, such as /run/user/$UID.
Monolithic Systemd Integration

When the libvirtd daemon is managed by systemd a number of desirable features are available, most notably socket activation.

Libvirt ships a number of unit files for controlling libvirtd:

    libvirtd.service - the main unit file for launching the libvirtd daemon in system mode. The command line arguments passed can be configured by editing /etc/sysconfig/libvirtd. This is typically only needed to control the use of the auto shutdown timeout value. It is recommended that this service unit be configured to start on boot. This is because various libvirt drivers support autostart of their objects. If it is known that autostart is not required, this unit can be left to start on demand.

    libvirtd.socket - the unit file corresponding to the main read-write UNIX socket /var/run/libvirt/libvirt-sock. This socket is recommended to be started on boot by default.

    libvirtd-ro.socket - the unit file corresponding to the main read-only UNIX socket /var/run/libvirt/libvirt-sock-ro. This socket is recommended to be started on boot by default.

    libvirtd-admin.socket - the unit file corresponding to the administrative UNIX socket /var/run/libvirt/libvirt-admin-sock. This socket is recommended to be started on boot by default.

    libvirtd-tcp.socket - the unit file corresponding to the TCP 16509 port for non-TLS remote access. This socket should not be configured to start on boot until the administrator has configured a suitable authentication mechanism.

    libvirtd-tls.socket - the unit file corresponding to the TCP 16509 port for TLS remote access. This socket should not be configured to start on boot until the administrator has deployed x509 certificates and optionally configured a suitable authentication mechanism.

NB, some distros will use /etc/default instead of /etc/sysconfig.

The socket unit files are newly introduced in 5.6.0. On newly installed hosts the UNIX socket units should be enabled by default. When upgrading an existing host from a previous version of libvirt, the socket unit files will be masked if libvirtd is currently configured to use the --listen argument, since the --listen argument is mutually exclusive with use of socket activation.

When systemd socket activation is used a number of configuration settings in libvirtd.conf are no longer honoured. Instead these settings must be controlled via the system unit files

    listen_tcp - TCP socket usage is enabled by starting the libvirtd-tcp.socket unit file.

    listen_tls - TLS socket usage is enabled by starting the libvirtd-tls.socket unit file.

    tcp_port - Port for the non-TLS TCP socket, controlled via the ListenStream parameter in the libvirtd-tcp.socket unit file.

    tls_port - Port for the TLS TCP socket, controlled via the ListenStream parameter in the libvirtd-tls.socket unit file.

    listen_addr - IP address to listen on, independently controlled via the ListenStream parameter in the libvirtd-tcp.socket or libvirtd-tls.socket unit files.

    unix_sock_group - UNIX socket group owner, controlled via the SocketGroup parameter in the libvirtd.socket and libvirtd-ro.socket unit files

    unix_sock_ro_perms - read-only UNIX socket permissions, controlled via the SocketMode parameter in the libvirtd-ro.socket unit file

    unix_sock_rw_perms - read-write UNIX socket permissions, controlled via the SocketMode parameter in the libvirtd.socket unit file

    unix_sock_admin_perms - admin UNIX socket permissions, controlled via the SocketMode parameter in the libvirtd-admin.socket unit file

    unix_sock_dir - directory in which all UNIX sockets are created independently controlled via the ListenStream parameter in any of the libvirtd.socket, libvirtd-ro.socket and libvirtd-admin.socket unit files.

Modular driver daemons

The modular daemons are named after the driver which they are running, with the pattern virt${DRIVER}d and will become the default in future libvirt. They are configured via the files /etc/libvirt/virt${DRIVER}d.conf

The following modular daemons currently exist for hypervisor drivers

    virtqemud - the QEMU management daemon, for running virtual machines on UNIX platforms, optionally with KVM acceleration, in either system or session mode

    virtxend - the Xen management daemon, for running virtual machines on the Xen hypervisor, in system mode only

    virtlxcd - the Linux Container management daemon, for running LXC guests in system mode only

    virtbhyved - the BHyve management daemon, for running virtual machines on FreeBSD with the BHyve hypervisor, in system mode.

    virtvboxd - the VirtualBox management daemon, for running virtual machines on UNIX platforms.

The additional modular daemons service secondary drivers

    virtinterfaced - the host NIC management daemon, in system mode only

    virtnetworkd - the virtual network management daemon, in system mode only

    virtnodedevd - the host physical device management daemon, in system mode only

    virtnwfilterd - the host firewall management daemon, in system mode only

    virtsecretd - the host secret management daemon, in system or session mode

    virtstoraged - the host storage management daemon, in system or session mode

Modular Sockets

When running in system mode, virt${DRIVER}d exposes three UNIX domain sockets:

    /var/run/libvirt/virt${DRIVER}d-sock - the primary socket for accessing libvirt APIs, with full read-write privileges. For many of the daemons, a connection to this socket gives the client privileges that are equivalent to having a root shell. This is the socket that most management applications connect to by default.

    /var/run/libvirt/virt${DRIVER}d-sock-ro - the secondary socket for accessing libvirt APIs, with limited read-only privileges. A connection to this socket gives the ability to query the existence of objects and monitor some aspects of their operation. This is the socket that most management applications connect to when requesting read only mode. Typically this is what a monitoring app would use.

    /var/run/libvirt/virt${DRIVER}d-admin-sock - the administrative socket for controlling operation of the daemon itself (as opposed to drivers it is running). This can be used to dynamically reconfigure some aspects of the daemon and monitor/control connected clients.

NB, some distros will use /run instead of /var/run.

When running in session mode, virt${DRIVER}d exposes two UNIX domain sockets:

    $XDG_RUNTIME_DIR/libvirt/virt${DRIVER}d-sock - the primary socket for accessing libvirt APIs, with full read-write privileges. A connection to this socket does not alter the privileges that the client already has. This is the socket that most management applications connect to by default.

    $XDG_RUNTIME_DIR/libvirt/virt${DRIVER}d-admin-sock - the administrative socket for controlling operation of the daemon itself (as opposed to drivers it is running). This can be used to dynamically reconfigure some aspects of the daemon and monitor/control connected clients.

Notice that the session mode does not have a separate read-only socket. Since the clients must be running as the same user as the daemon itself, there is not any security benefit from attempting to enforce a read-only mode.

$XDG_RUNTIME_DIR commonly points to a per-user private location on tmpfs, such as /run/user/$UID.
Modular Systemd Integration

When the virt${DRIVER}d daemon is managed by systemd a number of desirable features are available, most notably socket activation.

Libvirt ships a number of unit files for controlling virt${DRIVER}d:

    virt${DRIVER}d.service - the main unit file for launching the virt${DRIVER}d daemon in system mode. The command line arguments passed can be configured by editing /etc/sysconfig/virt${DRIVER}d. This is typically only needed to control the use of the auto shutdown timeout value. It is recommended that this service unit be configured to start on boot. This is because various libvirt drivers support autostart of their objects. If it is known that autostart is not required, this unit can be left to start on demand.

    virt${DRIVER}d.socket - the unit file corresponding to the main read-write UNIX socket /var/run/libvirt/virt${DRIVER}d-sock. This socket is recommended to be started on boot by default.

    virt${DRIVER}d-ro.socket - the unit file corresponding to the main read-only UNIX socket /var/run/libvirt/virt${DRIVER}d-sock-ro. This socket is recommended to be started on boot by default.

    virt${DRIVER}d-admin.socket - the unit file corresponding to the administrative UNIX socket /var/run/libvirt/virt${DRIVER}d-admin-sock. This socket is recommended to be started on boot by default.

NB, some distros will use /etc/default instead of /etc/sysconfig.

The socket unit files are newly introduced in 5.6.0. On newly installed hosts the UNIX socket units should be enabled by default. When upgrading an existing host from a previous version of libvirt, the socket unit files will be masked if virt${DRIVER}d is currently configured to use the --listen argument, since the --listen argument is mutually exclusive with use of socket activation.

When systemd socket activation is used a number of configuration settings in virt${DRIVER}d.conf are no longer honoured. Instead these settings must be controlled via the system unit files:

    unix_sock_group - UNIX socket group owner, controlled via the SocketGroup parameter in the virt${DRIVER}d.socket and virt${DRIVER}d-ro.socket unit files

    unix_sock_ro_perms - read-only UNIX socket permissions, controlled via the SocketMode parameter in the virt${DRIVER}d-ro.socket unit file

    unix_sock_rw_perms - read-write UNIX socket permissions, controlled via the SocketMode parameter in the virt${DRIVER}d.socket unit file

    unix_sock_admin_perms - admin UNIX socket permissions, controlled via the SocketMode parameter in the virt${DRIVER}d-admin.socket unit file

    unix_sock_dir - directory in which all UNIX sockets are created independently controlled via the ListenStream parameter in any of the virt${DRIVER}d.socket, virt${DRIVER}d-ro.socket and virt${DRIVER}d-admin.socket unit files.

Switching to modular daemons

If a host is currently set to use the monolithic libvirtd daemon and needs to be migrated to the modular daemons a number of services need to be changed. The steps below outline the process on hosts using the systemd init service.

While it is technically possible to do this while virtual machines are running, it is recommended that virtual machines be stopped or live migrated to a new host first.

    Stop the current monolithic daemon and its socket units

    $ systemctl stop libvirtd.service
    $ systemctl stop libvirtd{,-ro,-admin,-tcp,-tls}.socket

    Disable future start of the monolithic daemon

    $ systemctl disable libvirtd.service
    $ systemctl disable libvirtd{,-ro,-admin,-tcp,-tls}.socket

    For stronger protection it is valid to use mask instead of disable too.

    Enable the new daemons for the particular virtualizationd driver desired, and any of the secondary drivers to accompany it. The following example enables the QEMU driver and all the secondary drivers:

    $ for drv in qemu interface network nodedev nwfilter secret storage
      do
        systemctl unmask virt${drv}d.service
        systemctl unmask virt${drv}d{,-ro,-admin}.socket
        systemctl enable virt${drv}d.service
        systemctl enable virt${drv}d{,-ro,-admin}.socket
      done

    Start the sockets for the same set of daemons. There is no need to start the services as they will get started when the first socket connection is established

    $ for drv in qemu network nodedev nwfilter secret storage
      do
        systemctl start virt${drv}d{,-ro,-admin}.socket
      done

    If connections from remote hosts need to be supported the proxy daemon must be enabled and started

    $ systemctl unmask virtproxyd.service
    $ systemctl unmask virtproxyd{,-ro,-admin}.socket
    $ systemctl enable virtproxyd.service
    $ systemctl enable virtproxyd{,-ro,-admin}.socket
    $ systemctl start virtproxyd{,-ro,-admin}.socket

    The UNIX sockets allow for remote access using SSH tunneling. If libvirtd had TCP or TLS sockets configured, those should be started too

    $ systemctl unmask virtproxyd-tls.socket
    $ systemctl enable virtproxyd-tls.socket
    $ systemctl start virtproxyd-tls.socket

Checking whether modular/monolithic mode is in use

New distributions are likely to use the modular mode although the upgrade process preserves whichever mode was in use before the upgrade.

To determine whether modular or monolithic mode is in use on a host running systemd as the init system you can take the following steps:

    Check whether the modular daemon infrastructure is in use

    First check whether the modular daemon you are interested (see Modular driver daemons for a summary of which daemons are provided by libvirt) in is running:

        Check .socket for socket activated services

        # systemctl is-active virtqemud.socket
        active

        Check .service for always-running daemons

        # systemctl is-active virtqemud.service
        active

    If either of the above is active your system is using the modular daemons.

    Check whether the monolithic daemon is in use

        Check libvirtd.socket

        # systemctl is-active libvirtd.socket
        active

        Check libvirtd.service for always-running daemon

        # systemctl is-active libvirtd.service
        active

    If either of the above is active your system is using the monolithic daemon.

    To determine which of the above will be in use on the next boot of the system, substitute is-enabled for is-active in the above examples.

