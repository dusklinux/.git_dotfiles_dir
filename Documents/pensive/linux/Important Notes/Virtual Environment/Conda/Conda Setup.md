# Conda Installation & Setup on Arch Linux

This guide provides a step-by-step walkthrough for installing and configuring Miniconda on an Arch Linux-based system. Following these instructions will result in a robust and correctly configured Conda installation, ready for creating and managing isolated Python environments.

---

### 1. Install Miniconda3

First, we will use `paru`, an AUR (Arch User Repository) helper, to install the `miniconda3` package. This is the core installation of the Conda package manager.

```bash
paru -S miniconda3
```

> [!NOTE] What is Miniconda?
> Miniconda is a minimal installer for Conda. It includes only Conda, Python, the packages they depend on, and a small number of other useful packages. This is in contrast to the full Anaconda distribution, which includes over 150 scientific packages by default.

---

### 2. Initial Activation & Permissions

Before we can configure Conda, we need to activate it for the current terminal session and grant your user account the necessary permissions to manage the installation directory.

#### A. Activate Conda for the Current Session
This command makes the `conda` executable available in your current terminal. This is a temporary step required to run the subsequent setup commands.

```bash
source /opt/miniconda3/etc/profile.d/conda.sh
```

#### B. Set Directory Permissions
By default, the Miniconda directory is owned by `root`. To allow your user to create environments, install packages, and update Conda without using `sudo`, you must take ownership of the installation directory.

```bash
sudo chown -R dusk:dusk /opt/miniconda3
```

> [!IMPORTANT] Update Username
> In the command above, you **must** replace `dusk:dusk` with your own `username:group`. You can find your username by running the `whoami` command.

---

### 3. System Configuration & Updates

With the initial setup complete, we'll apply a common compatibility fix and update Conda to the latest version.

#### A. Fix OpenSSL Compatibility Issue
Newer versions of OpenSSL can sometimes cause issues with packages built against older versions. This command sets an environment variable to prevent a common `legacy provider` error. We chain it with `conda --version` to immediately test that Conda is working.

```bash
export CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1 && conda --version
```

> [!TIP] Make it Permanent
> To avoid typing this command in every new terminal session, you can add it to your shell's configuration file (e.g., `~/.zshrc` or `~/.bashrc`):
> ```bash
> echo 'export CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1' >> ~/.zshrc
> ```

#### B. Update Conda to the Latest Version
It's a best practice to ensure the Conda package manager itself is up-to-date. This command updates `conda` in the `base` environment using the `defaults` channel.

```bash
conda update -n base -c defaults conda
```

---

### 4. Configure Channels for Package Management

Channels are the locations (repositories) where Conda looks for packages. We will configure Conda to prioritize the community-maintained `conda-forge` channel, which is a best practice for ensuring package availability and compatibility.

#### A. Edit the Conda Configuration File
Open the `.condarc` file in your home directory using a text editor like `nvim`. This file may not exist yet, in which case the editor will create a new one.

```bash
nvim ~/.condarc
```

#### B. Add Channel Configuration
Paste the following content into the file. This configuration tells Conda to look in `conda-forge` first, then `defaults`, and to use a `strict` priority, which helps prevent dependency conflicts.

```yaml
channels:
  - conda-forge
  - defaults
channel_priority: strict
```

#### C. Verify the Configuration
After saving and closing the file, run these commands to confirm that your changes have been applied correctly.

```bash
# Verify the channel order
conda config --show channels

# Verify the channel priority setting
conda config --show channel_priority
```

---

### 5. Enable Automatic Activation (Shell Integration)

This final step integrates Conda with your shell, so the `conda` command is automatically available every time you open a new terminal.

#### Option A: For the Current User (Recommended)
This is the most common and recommended method. It adds the Conda initialization script to your personal `.zshrc` file.

```bash
echo "[ -f /opt/miniconda3/etc/profile.d/conda.sh ] && source /opt/miniconda3/etc/profile.d/conda.sh" >> ~/.zshrc
```

#### Option B: For All System Users
If you need Conda to be available for all users on the system, create a system-wide symbolic link instead.

```bash
sudo ln -nfs /opt/miniconda3/etc/profile.d/conda.sh /etc/profile.d/conda.sh
```

---

### 6. Finalize Setup

Your Conda installation is now complete! For the changes to take effect, you must either **close and reopen your terminal** or source your shell's configuration file:

```bash
source ~/.zshrc
```

You should now see `(base)` prepended to your shell prompt, indicating that the base Conda environment is active. You are ready to start using Conda

