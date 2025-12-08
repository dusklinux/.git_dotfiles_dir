# Installing Kokoros (Text-to-Speech) on Arch Linux

This guide provides a comprehensive, tried-and-tested walkthrough for setting up the `Kokoros` text-to-speech engine on Arch Linux. We will use `uv` to create an isolated Python environment and `cargo` to build the Rust application from the source.

> [!WARNING] Use These Instructions
> The default instructions on the official GitHub repository may be outdated or incorrect. The following steps have been verified to work correctly.
> **Official Repo:** [https://github.com/lucasjinreal/Kokoros](https://github.com/lucasjinreal/Kokoros)

---

## Part 1: Environment Setup

First, we will prepare a dedicated workspace and an isolated Python environment to manage dependencies without affecting your system.

### Step 1: Create a Workspace Directory

Create a parent directory to house our application and navigate into it.

```bash
mkdir -p ~/contained_apps/uv/
cd ~/contained_apps/uv/
```

### Step 2: Create and Activate a Python Virtual Environment

Using `uv`, we'll create a virtual environment named `kokoros_rust_onnx` and then activate it.

```bash
# Create the environment
uv venv kokoros_cpu

# Activate the environment
source kokoros_cpu/bin/activate
```

> [!TIP] Your Shell Prompt
> After activation, your shell prompt should change to indicate that you are in the `(kokoros_cpu)` environment.

### Step 3: Clone the Kokoros Repository

Navigate into the newly created environment directory and clone the project source code from GitHub.

```bash
# Enter the virtual environment directory
cd kokoros_cpu

# Clone the repository
git clone https://github.com/lucasjinreal/Kokoros.git
```

### Step 4: Install Python Dependencies

**The Fix (Run this FIRST)** We explicitly tell `uv` to ignore the default index and use PyTorch's CPU-only wheelhouse for the `torch` package.
_Result:_ This downloads the lightweight (~200MB) CPU version of PyTorch instead of the ~2.5GB GPU version.
_Why this works:_ When `uv` processes `requirements.txt`, it sees that `torch>=2.0.0` is required. It checks the environment, sees that `torch` is **already installed** (the CPU version from step 2), and marks that requirement as "Satisfied." It skips downloading the massive GPU version entirely.

```bash
uv pip install torch --index-url https://download.pytorch.org/whl/cpu
```

Move into the cloned `Kokoros` directory and install the required Python packages using `uv`.

```bash
cd Kokoros
uv pip install -r scripts/requirements.txt
```

> [!NOTE]
> At this stage, do not download the models or voice files yet. We will build the application first.

---

## Part 2: Building the Application

Now, we will install the necessary build tools and compile the `Kokoros` application using Rust's package manager, Cargo.

### Step 1: Install Rust and Cargo

If you don't have Rust installed, use `pacman` to install it. Cargo is the official build tool and package manager for Rust.

```bash
sudo pacman -S --needed cargo
```

### Step 2: Compile the Executable

Ensure you are still in the `~/contained_apps/uv/kokoros_cpu/Kokoros/` directory, where the `Cargo.toml` file is located. Run the build command with the `--release` flag to create a highly optimized executable.
the next command will fail to build the project if espeak-ng and wordbook are instlaled, uninstlall it . 

```bash
sudo pacman -Rns wordbook espeak-ng
```

```bash
cargo build --release
```

> [!NOTE] Compilation Time
> This process compiles the entire Rust project and may take several minutes to complete. The final executable will be located at `./target/release/koko`.

### Step 3: Verify the Build

After the compilation finishes, verify that the binary was created successfully by checking its help menu.

```bash
./target/release/koko -h
```

---

## Part 3: Downloading Models and Voices

With the application built, we can now download the required AI model and voice data files.

### Step 1: Make Download Scripts Executable

The repository includes scripts to download the necessary files. First, we must grant them execute permissions.

```bash
# You can use either of the following commands
sudo chmod u+x scripts/download_{models,voices}.sh
```

 or
 
```bash
sudo chmod u+x scripts/download_models.sh scripts/download_voices.sh
```

You can verify the permissions have been set correctly with:
```bash
ls -la scripts/
```

### Step 2: Run the Download Scripts

Execute the scripts to download the model and voice files. They will be placed in the correct default directories (`checkpoints/` and `data/`).

> [!IMPORTANT] Current Directory Matters
> You **must** be inside the `Kokoros` project directory when running these scripts, as they download files relative to your current location.

```bash
./scripts/download_models.sh
```

```bash
./scripts/download_voices.sh
```
### Step 3: Final Verification

Check that the `koko` binary still functions correctly with the models in place.

```bash
./target/release/koko -h
```

---

## Part 4: System Integration & Usage

To make `Kokoros` easier to use from anywhere in your system, we will create a symbolic link.

### Step 1: Add `~/.local/bin` to Your PATH

*This step is already done, the path is already listed in the uwsm file.*

Ensure that your shell can find executables located in `~/.local/bin`. Add the following line to your shell's configuration file (e.g., `~/.zshrc` or `~/.bashrc`).

```bash
# Example for editing with nvim
nvim ~/.config/uwsm/env-hyprland
```

Add this line to the file:
```sh
export PATH="$HOME/.local/bin:$PATH"
```
*Remember to source your config file or restart your terminal for the change to take effect.*

### Step 2: Create the Symbolic Link

Create a symlink from the compiled binary to your local bin directory, renaming it to `kokoros` for convenience.

first create the parent directory for the symlink
```bash
mkdir -p ~/.local/bin/
```

```bash
ln -nfs ~/contained_apps/uv/kokoros_cpu/Kokoros/target/release/koko ~/.local/bin/kokoros
```

### Step 3: Basic Usage

You can now invoke the program from any terminal using the `kokoros` command.

**Command Format:**
```
Usage: kokoros [OPTIONS] <COMMAND>
```

**Example 1: Streaming Audio Output**

First, create a directory for the output files.

```bash
mkdir -p /mnt/zram1/kokoros
```

Generate audio from a predefined stream and save it to a file.

```bash
kokoros -s af_heart stream > /mnt/zram1/kokoros/1.wav
```

**Example 2: Synthesizing Text from a String**

Generate audio from a text string and save it to a specified output file using the `-o` flag.

```bash
kokoros text "There was once a time in New York when things were not as good as they are right now." -o /mnt/zram1/kokoros/2.wav
```
