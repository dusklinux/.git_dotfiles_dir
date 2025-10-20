
This guide outlines the steps to install DaVinci Resolve on your Linux system using the AUR (Arch User Repository).

## Installation Steps

Follow these steps to get DaVinci Resolve set up:

### 1. Download DaVinci Resolve

First, download the latest Linux ZIP file from the official Blackmagic Design website.

```url
https://www.blackmagicdesign.com/products/davinciresolve
```

### 2. Clone the AUR Repository

Navigate to your `~/contained_apps` directory and clone the `davinci-resolve` AUR repository. Then, change into the newly created directory.

>[!important] make sure the git version of davinci git is for the zip version you downloaded, sometimes the most recent zip is yet to be updated on the git


```bash
cd ~/contained_apps
git clone https://aur.archlinux.org/davinci-resolve.git
cd davinci-resolve
```

### 3. Place the Downloaded ZIP File

Copy the DaVinci Resolve ZIP file you downloaded in Step 1 into the `davinci-resolve` directory.

```bash
cp /mnt/media/Documents/do_not_delete_linux/appimages/DaVinci_Resolve_* ./
```

### 4. Install DaVinci Resolve

Finally, run the `makepkg` command to build and install DaVinci Resolve.

```bash
makepkg -si
```

---