TuneD is a system tuning service for Linux. It provides a number of pre-configured tuning profiles, each optimized for unique workload characteristics, including CPU-intensive job needs, storage/network throughput responsiveness, or power consumption reduction.

Enable and start the TuneD service.

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

> [!note]- All available profiles 
Available profiles:
>```ini
>- accelerator-performance     - Throughput performance based tuning with disabled higher latency STOP states
>- aws                         - Optimize for aws ec2 instances
>- balanced                    - General non-specialized tuned profile
>- desktop                     - Optimize for the desktop use-case
>- hpc-compute                 - Optimize for HPC compute workloads
>- intel-sst                   - Configure for Intel Speed Select Base Frequency
>- latency-performance         - Optimize for deterministic performance at the cost of increased power consumption
>- network-latency             - Optimize for deterministic performance at the cost of increased power consumption, focused on low latency network performance
>- network-throughput          - Optimize for streaming network throughput, generally only necessary on older CPUs or 40G+ networks
>- optimize-serial-console     - Optimize for serial console use.
>- powersave                   - Optimize for low power consumption
>- throughput-performance      - Broadly applicable tuning that provides excellent performance across a variety of common server workloads
>- virtual-guest               - Optimize for running inside a virtual guest
>- virtual-host                - Optimize for running KVM guests
>```

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