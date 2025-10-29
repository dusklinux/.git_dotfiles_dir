---
subject: keyboard layout
context:
  - setup
  - arch install
type: guide
status: complete
---


Before proceeding, it's essential to configure the correct keyboard layout to ensure your typing is accurate in the console. The default is the US layout.

### Step 1: List Available Keymaps

To see a list of all available keyboard layouts, use the following command:

```bash
localectl list-keymaps
```

> [!TIP] Filtering the List
> The list of keymaps is extensive. You can use `grep` to filter the results and find your specific country or language code more easily. For example, to search for German (`de`) or UK (`uk`) layouts:
> ```bash
> # Search for German layouts
> localectl list-keymaps | grep de
> 
> # Search for UK layouts
> localectl list-keymaps | grep uk
> ```

### Step 2: Load Your Preferred Layout

Once you have identified the correct keymap name from the list, load it using the `loadkeys` command.

To load the standard **US** keyboard layout, which is often the default:

```bash
loadkeys us
```

For any other layout, simply replace `us` with the name you found. For example, to load a French layout:

```bash
loadkeys fr
```

> [!NOTE] Temporary Setting
> This keyboard layout setting is temporary and will only persist for your current session in the live installation environment. It will be configured permanently later in the installation process.


