
# Mastering `systemctl`: The Arch Linux Service Manager

`systemctl` is the primary command-line tool for controlling `systemd`, the system and service manager for most modern Linux distributions, including Arch. As a system administrator, mastering `systemctl` is non-negotiable. It is your interface for managing services, inspecting system state, and troubleshooting boot and runtime issues.

This guide is structured to serve as both a learning resource and a quick-reference manual, covering commands from basic inspection to advanced diagnostics.

> [!NOTE] System vs. User Services
> `systemd` manages services on two different levels:
> *   **System-wide services:** These run with root privileges and are managed with commands like `sudo systemctl ...`. They affect the entire system.
> *   **User-specific services:** These run with your user's privileges and are managed with the `--user` flag (e.g., `systemctl --user ...`). They are specific to your user session.

---

## 1. Inspecting System & Service Status

These commands provide a real-time view of what is currently running on your system. They are your first step in any diagnostic process.


- Shows detailed runtime status of a specific unit, including whether it's active, its PID, memory usage, and the latest log entries. **This is often the most useful command for checking a single service.**
```bash
systemctl status <unit>
```

 - Lists all currently active and loaded units (services, sockets, targets, etc.). This is your immediate overview of what's running.
```bash
systemctl list-units
```

- Filters the `list-units` output to show only service units that are active and were once active during the current boot. Useful for focusing on services that ran during the current boot.
```bash
systemctl list-units --type=service
```

- Filters the `list-units` list by only the services that are currently running.
```bash
systemctl list-units --type=service --state=running
``` 

- Shows all units `systemd` knows about, regardless of their state (active, inactive, loaded, failed). Essential for seeing services that have stopped or are defined but not running. 
```bash
systemctl list-units --all
```

- A critical diagnostic command that specifically lists any services that have failed to start or have crashed. **Start your troubleshooting here.**
```bash
systemctl list-units --type=service --state=failed
```

### Example: Checking a Service

To get a detailed report on the NetworkManager service:
```bash
systemctl status NetworkManager.service
```

---

## 2. Managing Service Lifecycle

These commands are used to control services in the current session (start, stop) and configure their behavior across reboots (enable, disable).

| Command | Description |
| :--- | :--- |
| `sudo systemctl start <unit>` | Starts a unit immediately. This does not make it start on the next boot. |
| `sudo systemctl stop <unit>` | Stops a unit immediately. This does not prevent it from starting on the next boot if it's enabled. |
| `sudo systemctl restart <unit>` | Stops and then immediately starts a unit. Useful for applying configuration changes to a running service. |
| `sudo systemctl reload <unit>` | Asks a service to reload its configuration without a full restart. Not all services support this. |
| `sudo systemctl enable <unit>` | Enables a unit to start automatically at boot. This creates a symbolic link in the system's configuration. |
| `sudo systemctl disable <unit>` | Disables a unit, preventing it from starting automatically at boot. |
| `sudo systemctl enable --now <unit>` | A convenient combination that both enables a unit for future boots and starts it immediately in the current session. |

> [!TIP] Managing Multiple Services
> You can manage multiple services in a single command. This is highly efficient for initial system setup. For concrete examples, see [[Enabling System Services]].


# Enable and start multiple services at once
```bash
sudo systemctl enable --now NetworkManager.service bluetooth.service firewalld.service
```

---

## 3. Analyzing System Configuration

These commands help you understand which services are *available* on the system and which are configured to start automatically. This is crucial for performance tuning and security hardening. For a deeper dive into performance, see [[Performance Tuning]].

### List All Available Unit Files
This command shows every unit file on your system and its state (enabled, disabled, static, masked). It gives you a complete picture of what *can* be managed.
```bash
systemctl list-unit-files
```

### List Auto-Starting Services
These commands are essential for reviewing what will launch automatically when you boot your system or log in.

*   **System-wide services set to autostart:**
```bash
systemctl list-unit-files --state=enabled
```

*   **User-specific services set to autostart:**
```bash
systemctl --user list-unit-files --state=enabled
```

---

## 4. Troubleshooting and Advanced Management

When things go wrong, these commands are indispensable.

### Viewing Service Logs with `journalctl`
While not a `systemctl` command, `journalctl` is the standard tool for reading logs from the `systemd` journal. It is the most direct way to find out *why* a service failed.

> [!CAUTION] Placeholder Syntax
> In the command below, replace `<xyz.service>` with the actual name of the service you are investigating (e.g., `sshd.service`).

```bash
journalctl -u <xyz.service>
```
*   **Flags for `journalctl`:**
    *   `-f`: Follow the log in real-time.
    *   `-b`: Show logs only from the current boot.
    *   `-e`: Jump to the end of the log.

### Reloading the `systemd` Manager
After you create or modify a unit file (e.g., in `/etc/systemd/system/`), you **must** tell `systemd` to re-read its configuration from disk.

> [!WARNING] Always Reload After Editing
> Failure to run `daemon-reload` after editing a unit file means your changes will not be applied, which can be a confusing source of errors.

```bash
sudo systemctl daemon-reload
```

### Masking and Unmasking Services
Masking is a more powerful version of disabling. It creates a symlink from the service file to `/dev/null`, making it impossible for any other service to start it, even as a dependency.

*   **Mask a service:**
```bash
sudo systemctl mask <unit>
```
*   **Unmask a service:**
```bash
sudo systemctl unmask <unit>
```
