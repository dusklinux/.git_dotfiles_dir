
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
>or change the version of the file manually, ususally the first checksum256 needs to be changed and the version number for two lines. 
>instructions are usually in the arch aur repo comments

>[!note]- eg instructions to manually change the version for the latest version 
 > Clone this repo
> 
> Download the new 20.2.2 zip from blackmagic's website and place it inside the repo root folder.
> 
> Edit .SRCINFO file:
> Change pkgver = 20.2.2
> Change source = file://DaVinci_Resolve_20.2.1_Linux.zip
> 
> Change the first sha256sums = b1467f8e66a94c30f6b760c7b71ef14fb888c463716f1fc3423b7a5443d29da2
> 
> Edit PKGBUILD file:
> Change pkgver=20.2.2
> Change the first sha256sums=('b1467f8e66a94c30f6b760c7b71ef14fb888c463716f1fc3423b7a5443d29da2')
> If you are unsure if you have the same sha256, you can run: sha256sum DaVinci_Resolve_20.2.2_Linux.zip

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

[[DaVinci Resolve Setup]]