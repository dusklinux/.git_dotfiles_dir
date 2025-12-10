TuneD is a system tuning service for Linux. It provides a number of pre-configured tuning profiles, each optimized for unique workload characteristics, including CPU-intensive job needs, storage/network throughput responsiveness, or power consumption reduction.

Enable and start the TuneD service.
```bash
sudo pacman -Syu --needed tuned
```
```bash
sudo systemctl enable --now tuned
```

Find out which TuneD profile is currently active.

```bash
tuned-adm active
```

Current active profile: balanced

```bash
tuned-adm list
```

> [!NOTE]- ALL AVAILABLE PROFILES
> ```ini
> - accelerator-performance     - Throughput performance based tuning with disabled higher latency STOP states
> - atomic-guest                - Optimize virtual guests based on the Atomic variant
> - atomic-host                 - Optimize bare metal systems running the Atomic variant
> - aws                         - Optimize for aws ec2 instances
> - balanced                    - General non-specialized tuned profile
> - balanced-battery            - Balanced profile biased towards power savings changes for battery
> - cpu-partitioning            - Optimize for CPU partitioning
> - cpu-partitioning-powersave  - Optimize for CPU partitioning with additional powersave
> - default                     - Legacy default tuned profile
> - desktop                     - Optimize for the desktop use-case
> - desktop-powersave           - Optmize for the desktop use-case with power saving
> - enterprise-storage          - Legacy profile for RHEL6, for RHEL7, please use throughput-performance profile
> - hpc-compute                 - Optimize for HPC compute workloads
> - intel-sst                   - Configure for Intel Speed Select Base Frequency
> - laptop-ac-powersave         - Optimize for laptop with power savings
> - laptop-battery-powersave    - Optimize laptop profile with more aggressive power saving
> - latency-performance         - Optimize for deterministic performance at the cost of increased power consumption
> - mssql                       - Optimize for Microsoft SQL Server
> - network-latency             - Optimize for deterministic performance at the cost of increased power consumption, focused on low latency network performance
> - network-throughput          - Optimize for streaming network throughput, generally only necessary on older CPUs or 40G+ networks
> - openshift                   - Optimize systems running OpenShift (parent profile)
> - openshift-control-plane     - Optimize systems running OpenShift control plane
> - openshift-node              - Optimize systems running OpenShift nodes
> - optimize-serial-console     - Optimize for serial console use.
> - oracle                      - Optimize for Oracle RDBMS
> - postgresql                  - Optimize for PostgreSQL server
> - powersave                   - Optimize for low power consumption
> - realtime                    - Optimize for realtime workloads
> - realtime-virtual-guest      - Optimize for realtime workloads running within a KVM guest
> - realtime-virtual-host       - Optimize for KVM guests running realtime workloads
> - sap-hana                    - Optimize for SAP HANA
> - sap-hana-kvm-guest          - Optimize for running SAP HANA on KVM inside a virtual guest
> - sap-netweaver               - Optimize for SAP NetWeaver
> - server-powersave            - Optimize for server power savings
> - spectrumscale-ece           - Optimized for Spectrum Scale Erasure Code Edition Servers
> - spindown-disk               - Optimize for power saving by spinning-down rotational disks
> - throughput-performance      - Broadly applicable tuning that provides excellent performance across a variety of common server workloads
> - virtual-guest               - Optimize for running inside a virtual guest
> - virtual-host                - Optimize for running KVM guests
> ```


set the profile to virtual-host. This optimizes the host for running KVM guests.

```bash
sudo tuned-adm profile virtual-host
```

Check that the TuneD profile has been updated and that virtual-host is now active.

```bash
tuned-adm active
```

Make sure there are no errors.

```bash
sudo tuned-adm verify
```