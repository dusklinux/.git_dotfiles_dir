
After completing the base Arch Linux installation and booting into the new system, one of the first steps is to install an AUR (Arch User Repository) helper. This allows you to easily build and install packages from the vast collection of user-submitted software in the AUR.

This guide provides instructions for installing two of the most popular AUR helpers: `paru` and `yay`. You only need to install one.

> [!WARNING] Do Not Build as Root
> AUR helpers must be built and installed as a regular, non-root user. Running `makepkg` with `sudo` or as the `root` user is a security risk and will fail by default.

---

### Option 1: Install `paru`

`paru` is a feature-rich AUR helper with a focus on a minimal and interactive user experience.

1.  **Clone the Build Files**
- Download the source files from the AUR using `git`.

```bash
git clone https://aur.archlinux.org/paru.git
```

2.  **Navigate into the Directory**

```bash
cd paru
```

3.  **Build and Install the Package**
- This command compiles the source, installs dependencies, and installs the package.

```bash
makepkg -si
```

---

### Option 2: Install `yay`

`yay` is another popular and robust AUR helper, known for its advanced dependency solving and minimal user input.

1.  **Clone the Build Files**
Download the source files from the AUR using `git`.

```bash
git clone https://aur.archlinux.org/yay.git
```

2.  **Navigate into the Directory**

```bash
cd yay
```

3.  **Build and Install the Package**
- This command compiles the source, installs dependencies, and installs the package.

```bash
makepkg -si
```

> [!TIP] Understanding `makepkg -si`
> The flags used with `makepkg` are common and useful to know:
> - `-s` (**s**ync dependencies): Automatically resolves and installs any required dependencies using `pacman`.
> - `-i` (**i**nstall): Installs the package after a successful build.

