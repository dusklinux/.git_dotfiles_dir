
```bash
nvim .config/psd/psd.conf
```

> [!NOTE]- Default config
> ```ini
> #
> # $XDG_CONFIG_HOME/psd/psd.conf
> #
> # For documentation, refer man 1 psd or to the wiki page
> # https://wiki.archlinux.org/index.php/Profile-sync-daemon
> 
> ## NOTE the following:
> ## To protect data from corruption, in the event that you do make an edit while
> ## psd is active, any changes made will be applied the next time you start psd.
> 
> # Uncomment and set to "yes" to use overlayfs instead of a full copy to reduce
> # the memory costs and to improve sync/unsync operations. Note that your kernel
> # MUST have this module available in order to use this mode.
> #
> #USE_OVERLAYFS="no"
> 
> # Uncomment and set to "yes" to resync on suspend to reduce potential data loss.
> # Note that your system MUST have gdbus from glib2 installed to use this mode.
> #
> #USE_SUSPSYNC="no"
> 
> # List any browsers in the array below to have managed by psd. Useful if you do
> # not wish to have all possible browser profiles managed which is the default if
> # this array is left commented.
> #
> # Possible values:
> #  chromium
> #  chromium-dev
> #  conkeror.mozdev.org
> #  epiphany
> #  falkon
> #  firefox
> #  firefox-trunk
> #  google-chrome
> #  google-chrome-beta
> #  google-chrome-unstable
> #  heftig-aurora
> #  icecat
> #  inox
> #  luakit
> #  midori
> #  opera
> #  opera-beta
> #  opera-developer
> #  opera-legacy
> #  otter-browser
> #  qupzilla
> #  qutebrowser
> #  palemoon
> #  rekonq
> #  seamonkey
> #  surf
> #  vivaldi
> #  vivaldi-snapshot
> #
> #BROWSERS=()
> 
> # Uncomment and set to "no" to completely disable the crash recovery feature.
> #
> # The default is to create crash recovery backups if the system is ungracefully
> # powered-down due to a kernel panic, hitting the reset switch, battery going
> # dead, etc. Some users keep very diligent backups and don't care to have this
> # feature enabled.
> #USE_BACKUPS="yes"
> 
> # Uncomment and set to an integer that is the maximum number of crash recovery
> # snapshots to keep (the oldest ones are deleted first).
> #
> # The default is to save the most recent 5 crash recovery snapshots.
> #BACKUP_LIMIT=5
> ```


> [!NOTE]- Firefox Optimized
> ```ini
> # ~/.config/psd/psd.conf
> 
> # 1. DISABLE OVERLAYFS (The "Max RAM" Switch)
> # Default is "yes" (RAM saves changes only).
> # Setting "no" forces a FULL COPY of the profile into RAM.
> # With 64GB RAM, this is the single best setting for smoothness.
> # It eliminates all read latency from your /mnt/browser partition.
> USE_OVERLAYFS="no"
> 
> # 2. DEFINE BROWSER
> # Explicitly tell it to look for Firefox.
> # PSD follows symlinks, so it will seamlessly look through 
> # ~/.mozilla -> /mnt/browser/.mozilla/firefox
> BROWSERS=("firefox")
> 
> # 3. SYNC ON SUSPEND (Safety)
> # Since your data is in RAM, if your PC sleeps and runs out of battery,
> # you lose data. This forces a sync to disk right before the system sleeps.
> USE_SUSPSYNC="yes"
> 
> # 4. CRASH RECOVERY
> # Keep this ON. If your system crashes while the profile is in RAM,
> # you need these backups to restore the state.
> USE_BACKUPS="yes"
> BACKUP_LIMIT=5
> ```