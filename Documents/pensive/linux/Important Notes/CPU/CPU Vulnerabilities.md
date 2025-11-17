	DISABLELING CPU VULNABILITIES MITIGATIONS
	
	there are files in this directory for each mitigation, opening each file will show you the mitigation status for each vulrnability. 
		
```bash
ls /sys/devices/system/cpu/vulnerabilities/
```
	
Files within that directory will show one of these three things
	
first option is specific to the vulnability and is shown if mitigation is on and in effect. 	
Vulnerable: The system is vulnerable, and no mitigation is active.
Not affected: Your CPU is not vulnerable to this variant.

to list out the mitigation status for every file withing that directory, but this one doesn't tell you which one the cat is for.

```bash
cat /sys/devices/system/cpu/vulnerabilities/*
```

12700H grub flags for the `GRUB_CMDLINE_LINUX=""` line. 
```ini
reg_file_data_sampling=off spec_store_bypass_disable=off spectre_v2=off vmscape=off
```

```bash
grep . /sys/devices/system/cpu/vulnerabilities/*
```

this lists the status for each file along with naming the name of the file for each vulnability

```bash
for f in /sys/devices/system/cpu/vulnerabilities/*; do echo "--- $f ---"; cat "$f"; done
```

to run a script for comprehensive analyisis of what mitigations are in place and what are not, 

curl -L https://meltdown.ovh -o spectre-meltdown-checker.sh
	or
wget https://meltdown.ovh -O spectre-meltdown-checker.sh

chmod +x spectre-meltdown-checker.sh
sudo ./spectre-meltdown-checker.sh


to turn off all mitigations for a cpu, not recommanded for modern cpus, check individually for each vulnebality to see how much of a perfomrance improvement there is, cuz dsabling all hurts perfromancce of some cpus because of haredware implimentation os vulnebalites mitigations. 
	
mitigations=off

list of most common boot parameters to indidivudually turn off mitigations for each vulnability.

	gather_data_sampling=off [X86] ()
	indirect_target_selection=off [X86]
	kvm.nx_huge_pages=off [X86]
	l1tf=off [X86]
	mds=off [X86]
	mmio_stale_data=off [X86]
	no_entry_flush [PPC]
	no_uaccess_flush [PPC]
	nobp=0 [S390]
	nopti [X86,PPC]
	nospectre_bhb [ARM64]
	nospectre_v1 [X86,PPC]
	nospectre_v2 [X86,PPC,S390,ARM64]
	reg_file_data_sampling=off [X86]
	retbleed=off [X86]
	spec_rstack_overflow=off [X86]
	spec_store_bypass_disable=off [X86,PPC]
	spectre_bhi=off [X86]
	spectre_v2_user=off [X86]
	srbds=off [X86,INTEL]
	ssbd=force-off [ARM64]
	tsx_async_abort=off [X86]
   
	Exceptions:
	
	This does not have any effect on
	kvm.nx_huge_pages when
	kvm.nx_huge_pages=force.
	
auto (default)
	Mitigate all CPU vulnerabilities, but leave SMT
	enabled, even if it's vulnerable.  This is for
	users who don't want to be surprised by SMT
	getting disabled across kernel upgrades, or who
	have other ways of avoiding SMT-based attacks.
	Equivalent to: (default behavior)

auto,nosmt
	Mitigate all CPU vulnerabilities, disabling SMT
	if needed.  This is for users who always want to
	be fully mitigated, even if it means losing SMT.
	Equivalent to: l1tf=flush,nosmt [X86]
	mds=full,nosmt [X86]
	tsx_async_abort=full,nosmt [X86]
	mmio_stale_data=full,nosmt [X86]
	retbleed=auto,nosmt [X86]
