# General Linux & Shell Tips

This guide serves as a comprehensive reference for essential Arch Linux commands and shell concepts. It is designed to be both a learning tool for new users and a quick reference for experienced system administrators, ensuring every detail from the original notes is preserved and clarified.

---

## 1. Core Commands & Utilities

This section covers fundamental commands for interacting with applications, the system, and text data.

### Opening a New Application Instance

Some applications, by default, will only open one window. You can often force a new, separate instance using a specific command-line flag.

> [!EXAMPLE] Forcing a new `featherpad` instance
> To open a new, independent `featherpad` window, even if one is already running, use the `--standalone` flag.

```bash
featherpad --standalone /path/to/textfile
```

### System Information

| Command | Description |
|---|---|
| `uname -r` | Displays the current Linux kernel release version. |
| `groups $(whoami)` | Lists all the groups the current user is a part of. |

### Text & Data Processing

#### Word & Line Count (`wc`)

The `wc` (word count) command is used to count lines, words, and characters.

> [!NOTE]
> Your original note mentioned `ws -l`. This is likely a typo for `wc -l`, which is the standard command for counting lines.

-   **`wc -l`**: Counts the number of lines from a file or standard input.

**Example:** To count the number of files and directories in the current location, you can pipe (`|`) the output of `ls -l` (list files in long format) to `wc -l`.

```bash
ls -l | wc -l
```

#### Searching with Grep (`grep`)

`grep` is a powerful tool for searching plain-text data sets for lines that match a regular expression.

| Option | Description |
|:---|:---|
| `-i` | **I**gnores case distinctions in patterns and input data. |
| `-v` | In**v**erts the match, selecting and showing only the non-matching lines. |

---

## 2. Symbolic Links (Symlinks)

> [!IMPORTANT] A Foundational Skill
> As you noted, learning to use symbolic links (or symlinks) is a critical skill for managing files and structuring your system efficiently. A symlink is a pointer or shortcut to another file or directory.

### Syntax Overview

The basic structure of the `ln` command to create a symbolic link is:

```bash
ln -nfs TARGET LINK_NAME
```

-   `ln -nfs`: The command to create a **s**ymbolic link.
-   `TARGET`: The full path to the original file or directory you want to link **to**.
-   `LINK_NAME`: The path and name of the shortcut (the symlink) you want to create.

### Practical Example

Here is the exact scenario from your notes, fully preserved:

**Goal:** You have a folder in your Downloads directory named `Geekbench-6.4.0-Linux`. You created an empty folder on your Desktop named `yothis`. You want it so that when you enter the `yothis` folder, you see the files from the `Geekbench-6.4.0-Linux` folder.

**Command:**

```bash
ln -nfs ~/Downloads/Geekbench-6.4.0-Linux ~/Desktop/yothis
```

**Result:** This command creates a symlink named `yothis` on your desktop that points to the `Geekbench` directory. When you access `~/Desktop/yothis`, you are actually viewing the contents of `~/Downloads/Geekbench-6.4.0-Linux`.

---

## 3. Shell Control & Scripting Operators

These operators give you powerful control over how commands are executed in the shell. For more interactive shell shortcuts, see [[Shell Tips]].

### The Pipe (`|`)

-   **Purpose**: Connects the standard output of the command on the left to the standard input of the command on the right. It creates a "pipeline" of commands where data flows from one to the next.
-   **Usage**: `command1 | command2`
-   **Explanation**: `command1` runs, and its output is not displayed on the screen directly, but instead becomes the input for `command2`. `command2` then processes that input.
-   **Example**: Listing files and then counting them.
    ```bash
    ls -l | wc -l
    ```
    -   `ls -l`: Lists files in the current directory in long format.
    -   `|`: Takes the output of `ls -l`.
    -   `wc -l`: Receives the list of files as input and counts the number of lines.
-   **Result**: You'll see a single number, which is the count of files and directories in the current location.

### The Semicolon (`;`)

-   **Purpose**: Executes commands sequentially, one after the other, regardless of whether the previous command succeeded or failed.
-   **Usage**: `command1 ; command2 ; command3`
-   **Explanation**: The shell runs `command1`. Once `command1` finishes, `command2` starts, and so on. If `command1` fails, `command2` still runs.
-   **Example**: Running two commands back-to-back.
    ```bash
    echo "Hello" ; echo "World"
    ```
    -   `echo "Hello"`: Prints "Hello".
    -   `;`: Separates the commands.
    -   `echo "World"`: Prints "World".
-   **Result**: Both "Hello" and "World" will be printed on separate lines.

### The Double Ampersand (`&&`) - Logical AND

-   **Purpose**: Executes the command on the right **only if** the command on the left succeeds (exits with a zero status). This is a logical AND operation.
-   **Usage**: `command1 && command2`
-   **Explanation**: `command1` runs. If `command1` is successful, then `command2` runs. If `command1` fails, `command2` is not executed. This is often used for dependency – "do this, AND if that worked, then do this other thing."
-   **Example**: Update package lists and then upgrade if the update was successful.
    > [!WARNING] Distribution-Specific Commands
    > The original example `sudo dnf check-update && sudo dnf upgrade` uses `dnf`, which is for Fedora/RHEL-based systems. For your Arch Linux systems, the equivalent is `pacman`.

    ```bash
    # Arch Linux Equivalent
    sudo pacman -Syu
    ```
    -   `sudo pacman -Syu`: Synchronizes package databases and upgrades all packages. The command itself is a combined "update and upgrade," which implicitly functions like a `&&` operation. If the sync (`-Sy`) fails, the upgrade (`-u`) won't proceed.

### The Double Pipe (`||`) - Logical OR

-   **Purpose**: Executes the command on the right **only if** the command on the left fails (exits with a non-zero status). This is a logical OR operation.
-   **Usage**: `command1 || command2`
-   **Explanation**: `command1` runs. If `command1` fails, then `command2` runs. If `command1` succeeds, `command2` is not executed. This is often used for alternatives or fallback actions – "try this, OR if that failed, do this other thing."
-   **Example**: Try to start a service, and if it fails, print an error message.
    ```bash
    systemctl start my-service || echo "Failed to start my-service"
    ```
    -   `systemctl start my-service`: Tries to start a system service. It will likely exit with a non-zero status if it fails.
    -   `||`: If starting the service fails...
    -   `echo "Failed to start my-service"`: ...then print this error message.
-   **Result**: If `my-service` starts successfully, you won't see the error message. If it fails to start, you will see "Failed to start my-service".

### The Single Ampersand (`&`)

-   **Purpose**: Runs the command in the background. This allows you to continue using your terminal while the command is running.
-   **Usage**: `command &`
-   **Explanation**: The shell starts `command` and immediately returns control to you, allowing you to type and run other commands. The background command's output might still appear in your terminal unless redirected.
-   **Example**: Starting a graphical application from the terminal without blocking the terminal.
    ```bash
    firefox &
    ```
    -   `firefox`: The command to launch the Firefox browser.
    -   `&`: Runs `firefox` in the background.
-   **Result**: Firefox will open, and you will immediately get your terminal prompt back to run other commands. You might see a job number and PID displayed.

### Parentheses `()` - Subshell Grouping

-   **Purpose**: Groups commands to be executed in a subshell. A subshell is a child process of your current shell, with its own environment. Changes made within a subshell (like changing directories) do not affect the parent shell.
-   **Usage**: `(command1 ; command2)`
-   **Explanation**: The commands inside the parentheses are executed in a separate, isolated shell environment.
-   **Example**: Changing directory and listing files in a subshell without affecting the current directory of your main shell.
    ```bash
    pwd ; (cd /tmp ; pwd) ; pwd
    ```
    -   `pwd`: Prints the current working directory.
    -   `(cd /tmp ; pwd)`:
        -   `( ... )`: Creates a subshell.
        -   `cd /tmp`: Changes directory **within the subshell** to `/tmp`.
        -   `pwd`: Prints the working directory **within the subshell** (which is now `/tmp`).
    -   `pwd`: Prints the current working directory in the original parent shell again.
-   **Result**: You will see your original directory, then `/tmp`, and then your original directory again. The `cd /tmp` command inside the parentheses did not change the directory of the main shell process.

---

### Key Differences Summarized

Understanding these symbols gives you powerful control over scripting and combining commands efficiently in the Linux terminal.

| Symbol | Name | Function |
|:---|:---|:---|
| `|` | Pipe | Connects the output of one command to the input of another. Focus is on **data flow**. |
| `;` | Semicolon | Executes commands sequentially, regardless of success or failure. Focus is on **simple ordering**. |
| `&&` | Double Ampersand | Executes the next command only on **success** of the previous one. Focus is on conditional execution based on success. |
| `||` | Double Pipe | Executes the next command only on **failure** of the previous one. Focus is on conditional execution based on failure (fallback). |
| `&` | Single Ampersand | Runs a command in the **background**. Focus is on not blocking the current terminal session. |
| `()` | Parentheses | Groups commands to run in an **isolated subshell**. Focus is on creating a temporary environment. |

