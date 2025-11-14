
# Shell Tips: A Sysadmin's Guide to Terminal Efficiency

Mastering the command line is a fundamental skill for any system administrator. This guide provides a collection of essential shell tips, shortcuts, and commands to streamline your workflow in Arch Linux.

---

## 1. Filesystem Navigation

Efficiently moving through your directory structure is the first step to terminal mastery.

| Command | Action |
|---|---|
| `cd ~` | Navigates to the home directory (`/home/username`). |
| `cd -` | Switches to the previous directory you were in. |
| `pushd <dir>` | Pushes the current directory onto a stack and changes to `<dir>`. |
| `popd` | Pops the last directory from the stack and changes to it. |

> [!NOTE] Understanding `pushd` and `popd`
> Think of `pushd` and `popd` as creating a "memory" of directories. You can use `pushd` multiple times to build a list of locations and then use `popd` to navigate back through them in reverse order. This is more powerful than `cd -` which only remembers the single last location.

**Example:**
```bash
# Start in your home directory
pwd
# /home/user

# Push home and go to /etc
pushd /etc
# /etc ~

# Push /etc and go to /var/log
pushd /var/log
# /var/log /etc ~

# Now, pop back
popd
# /etc ~

popd
# ~
```

---

## 2. Command Line Editing Shortcuts

Edit long commands with ease without reaching for the mouse. These shortcuts are invaluable for speed and precision.

| Shortcut | Action |
|---|---|
| `Ctrl` + `A` | Jumps to the **A**ll the way to the beginning of the line. |
| `Ctrl` + `E` | Jumps to the **E**nd of the line. |
| `Ctrl` + `U` | Clears the entire line from the cursor to the beginning. |
| `Ctrl` + `L` | Clears the visible screen, but keeps the scrollback history. |
| `reset` | Performs a hard reset of the terminal, fully clearing the screen and scrollback. |

---

## 3. Command History

Leverage your shell's memory to reuse and find previous commands quickly.

| Command / Shortcut | Action |
|---|---|
| `history` | Displays a numbered list of your previously executed commands. |
| `!<num>` | Executes the command with the corresponding number from the `history` list (e.g., `!234`). |
| `sudo !!` | Re-runs the *immediately* preceding command with `sudo` prepended. |
| `Ctrl` + `R` | Initiates a **R**everse search. Start typing any part of a past command to find it. |
| `Ctrl` + `C` | Exits the reverse search mode. |

> [!WARNING] Be Careful with `sudo !!`
> Always be certain what the last command was before using `sudo !!`. Running a destructive or unintended command with root privileges can have serious consequences. You can press `Enter` after typing `sudo !!` to see the command before executing it.

---

## 4. Job & Process Control

Manage running processes directly from your active terminal session.

| Shortcut / Command | Action |
|---|---|
| `Ctrl` + `Z` | Pauses the current foreground process and moves it to the background. |
| `fg` | Brings the most recently backgrounded job back to the **f**ore**g**round. |
| `bg` | Resumes a backgrounded job, keeping it running in the background. |
| `jobs` | Lists all jobs currently running in the background of the shell session. |

> [!TIP] A Practical Use Case
> This is extremely useful for temporarily pausing a task like a file transfer or a running script (e.g., `htop`, `nvtop`) with `Ctrl+Z`, doing something else in the same terminal, and then resuming it with `fg`.

---

## 5. Command Chaining & Operators

Combine multiple commands into a single, powerful line. The operator you choose determines how they interact. For a more detailed explanation, see [[General Tips]].

| Operator | Name | Function |
|---|---|---|
| `;` | Semicolon | Executes commands sequentially, regardless of success or failure. |
| `&&` | Logical AND | Executes the second command **only if** the first one succeeds. |
| `||` | Logical OR | Executes the second command **only if** the first one fails. |
| `|` | Pipe | Takes the output of the first command and uses it as the input for the second. |

**Examples:**
```bash
# Run update, and if it succeeds, run upgrade
sudo pacman -Syu && echo "Update successful!"

# Try to create a directory; if it fails (e.g., it exists), print a message
mkdir my_dir || echo "Directory already exists."
```

---

## 6. Aliases: Creating Custom Shortcuts

Aliases allow you to create short, memorable names for longer or more complex commands.

To create a temporary alias for your current session:
```bash
alias update='sudo pacman -Syu'
```
Now, you can simply type `update` to run the full command.

> [!NOTE] Making Aliases Permanent
> To make your aliases available every time you open a terminal, you must add them to your shell's configuration file. For most Arch Linux users, this will be:
> - **Bash:** `~/.bashrc`
> - **Zsh:** `~/.zshrc`
>
> Simply add the `alias update='...'` line to the end of the appropriate file and restart your shell.

---

## 7. Instant Help & Cheatsheets

When you forget the syntax for a command, you don't have to leave the terminal.

```bash
curl https://cheat.sh/rsync
```
This command fetches a concise cheatsheet for almost any command-line tool. Simply replace `rsync` with the command you need help with.

> [!TIP] Create an Alias for Cheatsheets
> For even faster access, create an alias for this function in your `.bashrc` or `.zshrc`:
> ```bash
> # Function to get cheatsheets
> cheat() {
>     curl "https://cheat.sh/$1"
> }
> ```
> After reloading your shell, you can just type `cheat rsync` to get help.

