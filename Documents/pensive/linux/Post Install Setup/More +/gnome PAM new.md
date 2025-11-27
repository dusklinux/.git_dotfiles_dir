# Guide: Robust GNOME Keyring Configuration (uwsm & TTY)

This guide details how to integrate **GNOME Keyring** with **PAM** (Pluggable Authentication Modules) on Arch Linux. It is specifically tailored for users launching their Wayland compositor (like Hyprland) via **`uwsm`** (Universal Wayland Session Manager) from a **TTY login**.

## 🧠 The Concept (An Analogy)

To understand _why_ we are doing this, imagine your Linux system is a high-security office building.

- **The Building (Linux):** The secure facility you want to enter.
    
- **The Front Desk Security (PAM):** This is the **P**luggable **A**uthentication **M**odule. It stops everyone at the door and asks for ID (Username) and a Code (Password).
    
- **Your Personal Safe (GNOME Keyring):** Once inside your office, you have a locked safe containing your API keys, WiFi passwords, and GitHub tokens.
    
- **The Problem:** Without configuration, you pass security at the front door, walk to your desk, and then have to type a _second_ code to open your safe.
    
- **The Solution (PAM Integration):** We tell the Front Desk Security (PAM) to take your code, unlock the front door, and _immediately_ radio the safe to unlock itself using that same code. When you sit down at your desk (`uwsm` starts your session), the safe is already open.
    

## 🛠️ Step 1: Install Required Packages

We need the safe (`gnome-keyring`), the communication line (`libsecret`), and optionally a visual inspection tool (`seahorse`).

```
sudo pacman -S --needed gnome-keyring libsecret seahorse
```

- **`gnome-keyring`**: The daemon (service) that actually stores the secrets.
    
- **`libsecret`**: The library apps (like Git or VS Code) use to talk to the keyring.
    
- **`seahorse`**: A GUI app ("Passwords and Keys") to view what's inside the keyring.
    

## 🔐 Step 2: Configure PAM for TTY Login

Since you log in via a TTY (terminal) before `uwsm` starts, we must configure the **login** service.

> [!DANGER] Critical Warning
> 
> You are editing authentication files. A typo here can lock you out of your system.
> 
> 1. Keep a **root terminal open** in a separate window/tmux pane while testing.
>     
> 2. If you break it, you will need to boot from a Live USB (Arch ISO) to fix it.
>     

Open the configuration file:

```
sudo nvim /etc/pam.d/login
```

You need to insert the keyring lines **after** the system includes. Think of the `include` lines as "Do the standard work," and your new lines as "Now do the extra keyring work."

**Make your file look exactly like this:**

```
#%PAM-1.0

# 1. Standard Checks
auth       requisite    pam_nologin.so
auth       include      system-local-login
# ➕ ADD THIS: Unlock the keyring using the password verified above
auth       optional     pam_gnome_keyring.so

# 2. Account Management (Leave as is)
account    include      system-local-login

# 3. Session Setup
session    include      system-local-login
# ➕ ADD THIS: Start the daemon and set environment variables
session    optional     pam_gnome_keyring.so auto_start

# 4. Password Changes
password   include      system-local-login
# ➕ ADD THIS: Update keyring password if you change your user password
password   optional     pam_gnome_keyring.so
```

### 🔍 Deep Dive: Why this order?

- **Auth Order:** We place `pam_gnome_keyring.so` **after** `system-local-login`.
    
    - _Analogy:_ The guard must verify you are actually an employee (system login) _before_ he bothers trying to unlock your safe. If you fail the first check, the second doesn't matter.
        
- **Session Order:** We place `auto_start` **after** `system-local-login`.
    
    - _Analogy:_ We want the standard office lights and AC turned on (system session) before we worry about powering up your specific safe.
        
- **`include system-local-login`**: This line is a "shortcut" that imports a bunch of other rules from Arch's default configuration. By adding our lines _around_ it, we keep the file clean and respectful of system defaults.
    

## 🖥️ Step 3: The `uwsm` Factor

Since `uwsm` wraps your Wayland session using systemd, we need to ensure the environment variables created by PAM make it all the way to your graphical session.

When PAM unlocks the keyring (Step 2), it exports variables like `SSH_AUTH_SOCK` and `GNOME_KEYRING_CONTROL` to your TTY shell. `uwsm` is smart; it usually inherits these from your shell when you run `uwsm start`.

Action Item:

Ensure your uwsm start command in your shell profile (~/.bash_profile or ~/.zprofile) is standard. You generally do not need to manually set SSH_AUTH_SOCK in your config files if PAM is working.

> [!TIP] Cleaning up Hyprland Config
> 
> If you previously had exec-once commands in hyprland.conf to start the keyring, remove them.
> 
> ❌ **Remove this:** `exec-once = /usr/bin/gnome-keyring-daemon --start ...`
> 
> PAM handles the start. Systemd handles the persistence. `uwsm` handles the environment.

## 🔄 Transitioning to SDDM (Display Manager)

If you later decide to use a Display Manager like SDDM, the `/etc/pam.d/login` file will no longer be used for your graphical login. SDDM uses its own PAM file.

1. **Install SDDM**: `sudo pacman -S sddm`
    
2. **Edit SDDM PAM**:
    

```
sudo nvim /etc/pam.d/sddm
```

3. **Add the exact same lines** in the same sections (`auth` and `session`):
    

```
#%PAM-1.0

# Authentication
auth     include       system-login
# Unlock gnome-keyring using the login password
auth     optional      pam_gnome_keyring.so

# Account Management
account  include       system-login

# Password Management (for changing passwords)
password include       system-login
# Update gnome-keyring password if the user changes their login password
password optional      pam_gnome_keyring.so

# Session Management
session  optional      pam_keyinit.so force revoke
session  include       system-login
# Initialize the keyring daemon
session  optional      pam_gnome_keyring.so auto_start
```

> [!NOTE] Logic Check
> 
> The logic is identical. Whether it's login (TTY) or sddm (GUI), the "Security Guard" (PAM) needs the instructions to unlock the "Safe" (Keyring).

## ✅ Verification & Troubleshooting

Reboot your computer and log in. Open a terminal.

**1. Check if the Daemon is running:**

```
pgrep -a gnome-keyring
```

_Expected output:_ A process ID and the command.

**2. Check the Environment:**

```
echo $SSH_AUTH_SOCK
```

_Expected output:_ Something like `/run/user/1000/keyring/ssh`.

3. Test with Seahorse:

Open seahorse. The "Login" keyring should be unlocked (the lock icon should be open/absent) without asking you for a password.

### 🐛 Troubleshooting: "It's still asking for a password!"

If the keyring asks for a password on login, it means your **User Login Password** and your **Keyring Password** are different.

**The Fix:**

1. Open `seahorse`.
    
2. Right-click the "Login" keyring.
    
3. Select "Change Password".
    
4. Enter the _old_ keyring password.
    
5. Set the **new** password to match your current **User Login Password** exactly.