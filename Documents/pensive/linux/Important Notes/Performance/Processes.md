
# Mastering Process Management on Arch Linux

Effective process management is a cornerstone of system administration. It is the key to diagnosing performance issues, ensuring application stability, and maintaining system security. This guide provides a comprehensive, structured approach to viewing, controlling, and interacting with processes on Arch Linux, designed to serve as both a foundational learning tool and a quick-reference manual for daily operations.

> [!NOTE] Foundational Knowledge
> A deep understanding of processes is critical for managing system resources. This note is closely related to [[CPU]] performance analysis and [[Power Management]], as every running process consumes these resources.

---

## 1. Process Inspection: Viewing and Understanding What's Running

Before you can manage a process, you must first identify and understand it. The following tools provide different lenses through which to view the processes running on your system.

### 1.1. `ps`: The Process Status Snapshot

The `ps` (Process Status) command is the fundamental tool for viewing running processes. It works by parsing the raw data found in the `/proc` filesystem (specifically the `/proc/<PID>` directories) and presenting it in a human-readable format.

> [!TIP] The Power of `ps`
> The `ps` command is incredibly versatile. It's highly recommended to review its manual page (`man ps`) to discover its vast array of formatting and filtering options.

#### Key `ps` Commands

| Command | Nickname | Purpose & When to Use |
|---|---|---|
| `ps aux` | The All-Seeing Eye | Provides a comprehensive list of **all** processes running on the system. Ideal for getting a complete overview or finding a specific process with `grep`. |
| `ps axjf` | The Family Tree | Displays the process hierarchy, showing parent-child relationships. Invaluable for tracing the origin of a process or understanding process groups. |
| `ps -eLf` | The Thread Inspector | Shows individual threads within each process. Essential for debugging applications that appear stuck or are consuming high CPU, as it can pinpoint a single misbehaving thread. |
| `pstree` | The Genealogist | A specialized tool for visualizing the process hierarchy as a clean, easy-to-read tree. Often superior to `ps axjf` for understanding process lineage. |

---

### 1.2. `ps` In-Depth Examples

#### `ps aux`: The Comprehensive Overview

This command provides a detailed snapshot of every process.
*   `a`: Show processes for all users.
*   `u`: Display in a user-oriented format (shows owner, CPU/MEM usage, etc.).
*   `x`: Include processes without a controlling terminal (e.g., daemons).

**Common Use Cases:**

*   **Find a specific process by name:**
    ```bash
    ps aux | grep -i 'hyprland'
    ```

*   **Find resource-hungry processes:**
    ```bash
    # Sort by highest CPU usage
    ps aux --sort=-%cpu | head
    
    # Sort by highest Memory usage
    ps aux --sort=-%mem | head
    ```

#### `ps axjf`: The Process Hierarchy View

This command helps you understand process relationships.
*   `j`: Jobs format, providing columns like PID, PPID (Parent PID), PGID (Process Group ID), and SID (Session ID).
*   `f`: Forest view, which uses ASCII art to draw the process tree.

```bash
ps axjf
```

#### `ps -eLf`: The Thread-Level View

This command lets you peer inside a process to see its individual threads.
*   `-e`: Select every process (equivalent to `ax`).
*   `-L`: Show threads, adding columns for LWP (Light Weight Process, i.e., thread ID) and NLWP (Number of Light Weight Processes).
*   `-f`: Full-format listing.

```bash
ps -eLf
```

---

### 1.3. `pstree`: The Specialist for Visualization

While `ps` can show the process tree, `pstree` is designed specifically for this task and produces a much cleaner visual output.

*   **Show command-line arguments (`-a`):** This helps distinguish between multiple instances of the same program.
    ```bash
    pstree -a
    ```

*   **The Ultimate Diagnostic View (`-pau`):** This combination gives you the most useful output: a process tree showing PIDs (`-p`), arguments (`-a`), and user owners (`-u`).
    ```bash
    pstree -pau
    ```

---

## 2. Process Interaction: Sending Signals

Signals are the primary way the kernel and other processes communicate with a running process. They can be used to request termination, pause execution, or trigger custom actions.

### 2.1. The `kill` Command and Common Signals

The `kill` command is used to send a signal to a process specified by its PID.

| Signal | Number | Command Example | Purpose & Use Case |
|---|---|---|---|
| **SIGHUP** | 1 | `kill -1 <PID>` | **Hang Up**. Tells a process to reload its configuration. Used by daemons like `nginx` or `sshd`. |
| **SIGINT** | 2 | `kill -2 <PID>` | **Interrupt**. The signal sent by `Ctrl+C`. Requests a graceful shutdown. |
| **SIGQUIT** | 3 | `kill -3 <PID>` | **Quit**. The signal sent by `Ctrl+\`. Asks the process to quit and generate a core dump for debugging. |
| **SIGKILL** | 9 | `kill -9 <PID>` | **Kill**. A non-ignorable, forceful termination. The process is killed immediately without cleanup. |
| **SIGTERM** | 15 | `kill -15 <PID>` | **Terminate**. The default signal for `kill`. A polite request for the process to shut down gracefully. |
| **SIGSTOP** | 19 | `kill -STOP <PID>` | **Stop**. A non-ignorable signal that pauses the process, freezing its execution. |
| **SIGCONT** | 18 | `kill -CONT <PID>` | **Continue**. Resumes a process that was paused with `SIGSTOP`. |

> [!WARNING] Use `SIGKILL` as a Last Resort
> `kill -9` does not allow a process to save its state or clean up resources. This can lead to data corruption or orphaned files. Always try `kill -15` (or just `kill`) first.

### 2.2. Special-Purpose Signals

| Signal | Command Example | Purpose & Use Case |
|---|---|---|
| **Signal 0** | `kill -0 <PID>` | **Check Existence**. Doesn't send a signal, but checks if the process exists and you have permission to signal it. Useful in scripts. |
| **SIGUSR1/2** | `kill -USR1 <PID>` | **User-Defined**. These signals have no default behavior. Application developers can program them to trigger custom actions, like rotating log files or dumping status information. |

### 2.3. Listing All Signals

To see a full list of signals supported by your system, use the `-l` flag.

```bash
kill -l
```

---

## 3. Advanced Process Control

### 3.1. Targeting by Name: `pkill` and `killall`

When you don't know the PID or want to signal multiple processes at once, these tools are invaluable.

*   **`pkill`**: Sends a signal to all processes matching a name or other attributes.
    ```bash
    # Forcefully kill all processes named 'myprocess'
    pkill -9 myprocess
    
    # Send a user-defined signal
    pkill -USR1 myprocess
    ```

*   **`killall`**: Similar to `pkill`, but matches the exact process name. Its intent is very explicit.
    ```bash
    # Forcefully kill all instances of 'myprocess'
    killall -9 myprocess
    
    # Tell all 'myprocess' instances to reload their configuration
    killall -HUP myprocess
    ```
> [!DANGER] Use with Caution
> On a multi-user system, `pkill` and `killall` can affect processes owned by other users. Be certain of what you are targeting before using them, especially with `-9`.

### 3.2. Interactive Job Control in the Shell

Your terminal provides powerful job control features for managing foreground processes.

| Action | Keystroke / Command | Signal Sent | Description |
|---|---|---|---|
| **Interrupt** | `Ctrl+C` | `SIGINT` | Stops the current foreground process. |
| **Suspend** | `Ctrl+Z` | `SIGTSTP` | Pauses the current foreground process and moves it to the background. |
| **Foreground** | `fg` | `SIGCONT` | Resumes the most recently suspended job and brings it to the foreground. |
| **Background** | `bg` | `SIGCONT` | Resumes the most recently suspended job but keeps it running in the background. |

---

## 4. Scripting: Handling Signals with `trap`

When writing shell scripts, you can "trap" signals to perform cleanup actions, ensuring your script exits gracefully.

```bash
#!/bin/bash

# Define a function to run on exit
cleanup() {
    echo "Caught signal... cleaning up temporary files."
    rm -f /tmp/myscript.*
    exit
}

# Trap SIGINT (Ctrl+C) and SIGTERM (from kill) and run the cleanup function
trap cleanup SIGINT SIGTERM

echo "Script running with PID $$... Press Ctrl+C to test the trap."
# Main script logic goes here
sleep 60
```

This makes your scripts more robust by preventing them from being terminated abruptly, leaving temporary files or incomplete operations behind.

