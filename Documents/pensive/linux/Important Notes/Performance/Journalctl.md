# Mastering the Systemd Journal with `journalctl`

The `journalctl` command is the primary tool for querying and displaying logs from the `systemd` journal. On Arch Linux, it is the modern, powerful replacement for traditional log files. Mastering `journalctl` is essential for system diagnostics, troubleshooting, and monitoring.

It is a core component of the `systemd` init system, working hand-in-hand with tools like [[Systemctl]] to provide a comprehensive view of your system's behavior.

---

## 1. Basic Viewing & Live Monitoring

These are the foundational commands for viewing logs.

| Command | Description |
|---|---|
| `journalctl` | Displays the entire journal, starting with the oldest entries. |
| `journalctl -r` | Shows logs in reverse order, with the most recent entries first. |
| `journalctl -f` | "Follow" the journal. This displays recent logs and then waits for new messages, printing them in real-time. This is invaluable for live troubleshooting. |

> [!TIP] Searching with Grep
> While `journalctl` has powerful built-in filtering, you can always pipe its output to `grep` for familiar, flexible searching.
> ```bash
> journalctl -b | grep -i "your search term"
> ```

---

## 2. Filtering by Unit and Process

Focus your search on specific services or system components, known as "units." For more information on managing units, see [[Systemctl]].

| Command | Description |
|---|---|
| `journalctl -u <unit_name>` | Shows logs only for the specified unit. For example, `journalctl -u vsftpd.service`. |
| `journalctl -f -u <unit_name>` | Combines "follow" mode with unit filtering to show a live feed of logs for a single service. |

**Example:** To watch the live activity of the `vsftpd` service:
```bash
journalctl -f -u vsftpd
```

---

## 3. Filtering by Timeframe

Isolate logs from a specific period, which is critical for diagnosing issues that occurred at a known time.

### Using Absolute Timestamps
Provide a specific date and time. The quotes are required.
```bash
# Logs since a specific time
journalctl --since "YYYY-MM-DD HH:MM:SS"

# Logs within a specific time window
journalctl --since "2025-07-08 07:16:40" --until "2025-07-08 07:16:45"
```

### Using Relative Timestamps
Use human-readable strings to define the time.
```bash
# Logs from the last hour until now
journalctl --since "1 hour ago" --until "now"

# Logs since yesterday
journalctl --since "yesterday"
```

> [!NOTE] Flexible Time Formats
> The time parser is very flexible. You can use values like `"2 days ago"`, `"15 minutes ago"`, or just a date like `"2025-07-08"`.

---

## 4. Filtering by Boot and Kernel Messages

Analyze logs from specific boot sessions or focus exclusively on messages from the Linux kernel.

### Boot Logs
| Command | Description |
|---|---|
| `journalctl -b` | Shows all logs from the current boot session. |
| `journalctl -b -1` | Shows logs from the previous boot. Use `-2` for the one before that, and so on. |
| `journalctl --list-boots` | Displays a table of all recorded boot sessions with their IDs. |
| `journalctl -b <ID>` | Shows logs for a specific boot session using the ID from `--list-boots`. |

### Kernel Logs
Kernel messages (the "ring buffer") are crucial for diagnosing hardware and driver issues.

| Command | Description |
|---|---|
| `journalctl -k` | Shows only kernel messages from the current boot. |
| `journalctl -k -b` | An alternative, explicit way to show kernel messages for the current boot. |

> [!NOTE] `journalctl` vs. `dmesg`
> The `journalctl -k` command is the modern, persistent way to view kernel messages. It has largely replaced the classic [[Dmesg]] command, as it integrates kernel logs with all other system events and provides superior filtering.

---

## 5. Filtering by Message Priority

Filter logs by severity to quickly find errors and warnings, cutting through the noise of informational messages.

```bash
# Show all errors from the current boot
journalctl -b -p err

# Show a range of priorities (errors, critical, alerts, and emergencies)
journalctl -b -p err..alert
```

You can use either the name or the corresponding number for the priority level.

| Priority | Number | Description |
|---|---|---|
| `emerg` | 0 | System is unusable. |
| `alert` | 1 | Action must be taken immediately. |
| `crit` | 2 | Critical conditions. |
| `err` | 3 | Error conditions. |
| `warning` | 4 | Warning conditions. |
| `notice` | 5 | Normal but significant condition. |
| `info` | 6 | Informational messages. |
| `debug` | 7 | Debug-level messages. |

---

## 6. Advanced Usage & Output Formatting

### Combining Flags for Precision
The true power of `journalctl` comes from combining flags. This allows you to zero in on the exact information you need.

**Example:** Find all warning-level (and higher) messages from the `bluetooth.service` during the previous boot.
```bash
journalctl -b -1 -u bluetooth.service -p warning
```

### Verbose Output
To get every field stored in the journal for matching entries, which can reveal extra context:
```bash
journalctl -b -o verbose
```

---

## 7. Journal Maintenance

Over time, the systemd journal can grow to occupy a significant amount of disk space. These commands help you manage its size.

> [!WARNING]
> Be cautious when cleaning the journal. Deleting logs permanently removes historical data that might be needed for future troubleshooting or security audits.

| Command | Description |
|---|---|
| `sudo journalctl --disk-usage` | Shows how much disk space the journal is currently using. |
| `sudo journalctl --vacuum-size=500M` | Shrinks the journal by deleting the oldest log files until the total size on disk is at or below the specified amount (e.g., 500MB). |
| `sudo journalctl --vacuum-time=2weeks` | Deletes all log files that are older than the specified relative time (e.g., 2 weeks). |

