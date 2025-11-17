# Kernel mitigation flags — how to write them (Obsidian note)

> Short: **No — it’s not always just `vulnerability_name=off`.**  
> This note explains patterns, common knobs, interdependencies, verification, and safe workflows for crafting kernel command-line flags that disable CPU-side-channel mitigations.

---

## Purpose

A compact, reproducible guide for writing kernel command-line flags to _selectively_ disable CPU vulnerability mitigations (for performance testing, benchmarking, or controlled lab use). This is written for system administrators and power users who manage many machines and already understand the risks.

## Big safety warning (read first)

Disabling mitigations removes protections against real hardware side-channel attacks and local privilege escalation. Only do this on machines you control, that are not multi-tenant, and where the risk is acceptable. Do not run untrusted code or host sensitive workloads on systems with mitigations disabled.

---

## High-level rules and terminology

- **Kernel knobs are not a single uniform namespace.** Some mitigations use `vulnerability=...` (e.g. `reg_file_data_sampling=`), others use `spectre_v2=...`, `spec_store_bypass_disable=...`, `mds=...`, `l1tf=...`, `pti=off`/`nopti`, etc.
    
- **Common value tokens:** `off`, `on`, `auto`, `full`, `prctl`, `force`, `nospec_*`, `noibrs`, `noibpb`. `off` usually means “don’t apply the mitigation”; `auto` means “kernel decide based on CPU/features”; `prctl` means per-thread/process control.
    
- **Synonyms exist.** Example: `nopti` and `pti=off` are synonymous; `nospectre_v2` == `spectre_v2=off` on many kernels.
    
- **Kernel version matters.** Newer kernels add knobs for newer mitigations. If a parameter is unknown, the kernel will silently ignore it or log an “unknown parameter” message in `dmesg`.
    

---

## Patterns to craft a flag

1. **Find the exact vulnerability name in sysfs:**
    
    ```bash
    grep . /sys/devices/system/cpu/vulnerabilities/*
    ```
    
    The filename (right of `/vulnerabilities/`) is the canonical vulnerability token used in docs; it often maps to a kernel cmdline param but not always.
    
2. **Look up kernel doc for that vulnerability** (docs usually show the exact command-line knob and valid values). Example docs live under `Documentation/admin-guide/hw-vuln/` in the kernel source or docs.kernel.org.
    
3. **Use the documented knob, not guesswork.** If docs say `reg_file_data_sampling=off` is the control, use that rather than `reg_file_data_sampling=0` or guessing.
    
4. **Prefer explicit strings** (e.g. `spec_store_bypass_disable=off`) rather than synonyms when scripting, because synonyms vary across distro kernels.
    

---

## Common mappings & example knobs (non-exhaustive)

> These are _patterns_ — always verify for your kernel version.

- Spectre v2: `spectre_v2=off` (synonym: `nospectre_v2`) or fine-grained: `noibrs`/`noibpb`/`retpoline` toggles.
    
- Spectre v1: often _not_ globally toggleable — many kernels implement hardening at code level. There may be no `spectre_v1=off` in your kernel.
    
- Speculative Store Bypass (SSB / Spectre v4): `spec_store_bypass_disable=off` (or `nospec_store_bypass_disable`). `prctl` is another mode.
    
- Meltdown / KPTI: `nopti` or `pti=off` to disable KPTI.
    
- MDS/TAA: `mds=off`, `tsx_async_abort=off` or `tsx=off` (some TAA mitigations are tied to MDS).
    
- L1TF: `l1tf=off`.
    
- MMIO stale data: `mmio_stale_data=off` (may need `mds=off` too if they share mitigation mechanisms).
    
- RFDS (Register-File Data Sampling): `reg_file_data_sampling=off`.
    
- RETBleed: `retbleed=off` on kernels that expose it.
    
- VMScape-type behavior: `vmscape=off` / `vmscape=ibpb` / `vmscape=force` depending on kernel.
    

> **Don’t assume `vulnname=off` exists.** Some names are only used for `/sys` reporting; their cmdline control uses a different string or none at all.

---

## Practical examples (templates)

- Minimal targeted (edit only the knobs you care about):
    
    ```text
    GRUB_CMDLINE_LINUX="reg_file_data_sampling=off spec_store_bypass_disable=off spectre_v2=off vmscape=off"
    ```
    
- Aggressive (disable most x86 mitigations — dangerous):
    
    ```text
    GRUB_CMDLINE_LINUX="spectre_v2=off spec_store_bypass_disable=off mds=off tsx_async_abort=off mmio_stale_data=off l1tf=off pti=off reg_file_data_sampling=off retbleed=off"
    ```
    
- Note: `mitigations=off` exists as a global shortcut — it should disable most mitigations, but it is a blunt instrument and may be ignored by some kernels or microcode.
    

---

## Verification checklist (after reboot)

- Check kernel got the flags:
    
    ```bash
    cat /proc/cmdline
    ```
    
- Check vulnerability status:
    
    ```bash
    grep . /sys/devices/system/cpu/vulnerabilities/*
    ```
    
- Inspect `dmesg` for ignored/unknown parameter messages and for kernel messages that say a mitigation was refused due to microcode:
    
    ```bash
    dmesg | egrep -i "unknown parameter|mitigat|microcode|VERW|IBPB|IBRS" -n
    ```
    

---

## Troubleshooting — common reasons a mitigation remains active

1. **Unknown parameter / wrong kernel version** — update kernel or use the exact documented knob.
    
2. **Microcode or firmware forces mitigation** — vendor microcode can enable CPU features that the kernel honors; the kernel will refuse to drop a mitigation in some cases.
    
3. **Shared mitigation mechanism** — multiple vulnerabilities may be mitigated with the same code path (e.g. MDS/TAA/MMIO/RFDS share buffer-clearing logic). You may need to disable _all_ related knobs (e.g. `mds=off` + `tsx_async_abort=off`) for the visible `/sys` entry to change.
    
4. **Non-toggleable mitigations** — some hardenings (for example, specific Spectre v1 mitigations) are implemented in kernel code and are not globally switchable; docs will say this.
    

---

## Scripting/automation tips when you manage many machines

- **Detect kernel support first**: parse `dmesg` or `/proc/cmdline` and the kernel parameter list at `/boot/config-$(uname -r)` or `docs.kernel.org` for your kernel tree.
    
- **Use explicit tokens**: use `spectre_v2=off` rather than `nospectre_v2` in scripts unless you’ve tested both on your distro kernels.
    
- **Check `dmesg` post-boot** and parse for refusal messages; alert if a mitigation remains enabled after your expected flags.
    

---

## Final checklist before production use

- You **must** document why mitigations were disabled, which machines, and retain a rollback plan.
    
- Keep microcode/BIOS firmware versions recorded — they can affect the behavior.
    
- Prefer toggling only what you need for benchmarking; keep production systems with mitigations enabled.
    

---

## Quick references (where to look in the tree)

- `Documentation/admin-guide/hw-vuln/` in kernel sources contains per-vulnerability pages (spectre, reg-file-data-sampling, tsx_async_abort, mmio_stale_data, etc.).
    
- `Documentation/admin-guide/kernel-parameters.rst` / `kernel-parameters.txt` lists recognized boot parameters.
    

---

## Appendix: sample commands to edit GRUB (Debian/Ubuntu example)

```bash
# backup
sudo cp /etc/default/grub /etc/default/grub.bak
# add flags (manual edit recommended); a safe sed approach risks breaking quoting so edit by hand
sudo nano /etc/default/grub
# then update
sudo update-grub
sudo reboot
```

---

_End of note._