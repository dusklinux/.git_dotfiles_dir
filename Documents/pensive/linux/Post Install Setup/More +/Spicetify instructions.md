# Spicetify + Matugen Manual Setup (Arch Linux)

### 1. Prerequisites

Ensure Spotify is installed and you have logged in at least once. **Keep Spotify open for ~60 seconds** on first run to ensure it generates all necessary user files.

### 2. Install Spicetify CLI

Install the command-line tool from the AUR.

```
paru -S spicetify-cli
```

### 3. Initialize & Patch Spotify

Generate the default configuration file and apply the initial patch to enable developer tools (required for custom CSS/JS).

```
# Generate config
spicetify

# Backup original files and enable devtools
spicetify backup apply enable-devtools
```

### 4. Install Marketplace

Download and install the Marketplace extension (App Store for Spicetify).

```
curl -fsSL [https://raw.githubusercontent.com/spicetify/spicetify-marketplace/main/resources/install.sh](https://raw.githubusercontent.com/spicetify/spicetify-marketplace/main/resources/install.sh) | sh
```

### 5. Install Comfy Theme

Clone the Comfy theme repository directly into your Spicetify themes folder.

```
mkdir -p ~/.config/spicetify/Themes
git clone https://github.com/Comfy-Themes/Spicetify Comfy ~/.config/spicetify/Themes/Comfy
```

### 6. Configure Theme

Tell Spicetify to use the "Comfy" theme and color scheme.

```
spicetify config current_theme Comfy color_scheme Comfy
```

### 7. Generate Colors (Matugen)

Run Matugen on your current wallpaper. This generates the `color.ini` and automatically links it to the Comfy folder (assuming your Matugen `config.toml` is set up correctly).

```
# Replace with your actual wallpaper path
matugen image ~/Pictures/wallpapers/dusk_default.jpg
```

### 8. Apply Changes

Apply the theme and reload Spotify without fully restarting the client.

```
spicetify apply -n
```

### Quick Fixes

- **If Spotify updates and breaks:** Run `spicetify backup apply`.
    
- **If colors look wrong:** Run `matugen` again, then `spicetify apply -n`.