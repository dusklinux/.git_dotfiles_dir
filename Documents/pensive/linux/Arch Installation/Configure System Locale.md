
Setting the system locale is crucial for defining the language, character encoding, and regional formatting (such as date and currency) for your entire system.

#### Step 1: Edit Locale Definitions

First, you need to specify which locales your system should support. This is done by editing the `/etc/locale.gen` file and uncommenting the desired entries.

1.  Open the locale definition file with a text editor:
    ```bash
    nvim /etc/locale.gen
    ```

2.  Find the locale(s) you need and uncomment them by removing the leading `#`. For US English, the line looks like this:
    ```ini
    # Find this line:
    #en_US.UTF-8 UTF-8
    
    # And uncomment it to look like this:
    en_US.UTF-8 UTF-8
    ```

> [!TIP] Searching in `nvim`
> You can search for your language code (e.g., `en_US`, `de_DE`, `fr_FR`) in `nvim` by pressing `/` followed by your search term and pressing `Enter`.

#### Step 2: Generate Locales

After saving your changes to `/etc/locale.gen`, run the `locale-gen` command. This will generate the locales you just uncommented, making them available to the system.

```bash
locale-gen
```

You should see output confirming that the locales have been generated successfully.

#### Step 3: Set the System-Wide Locale

Finally, create the `locale.conf` file to set the default locale for all users and services. This determines the language used in system menus and applications.

```bash
echo "LANG=en_US.UTF-8" > /etc/locale.conf
```

> [!IMPORTANT]
> The value assigned to `LANG` (e.g., `en_US.UTF-8`) must exactly match one of the locales you uncommented in `/etc/locale.gen`.

#### (Optional) Set Persistent Keyboard Layout

While you may have set a temporary keyboard layout with `loadkeys` earlier (as in the [[Set Keyboard Layout]] note), you should make this setting permanent so it persists after rebooting.

Create the `vconsole.conf` file to define the default keyboard layout for the virtual console.

```bash
echo "KEYMAP=us" > /etc/vconsole.conf
```

> [!NOTE]
> Replace `us` with the keymap you wish to use (e.g., `uk`, `de-latin1`, `fr`). This should match the layout you loaded with `loadkeys`.
