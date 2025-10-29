Manual Installation with Neovim's Built-in Package Feature

Neovim has a native way to load plugins, which is the most lightweight approach as it doesn't require any external tools.[1][2] This method involves cloning plugin repositories into a specific directory structure.

1. Directory Structure:

Neovim on Linux follows the XDG Base Directory Specification. Your Neovim configuration files reside in ~/.config/nvim/, and the plugins you install will go into ~/.local/share/nvim/site/pack/.[1]

Within the pack directory, you can create subdirectories to organize your plugins. A common convention is to use a "vendor" or "group" name, followed by start or opt.[3]

- start plugins: Plugins in a start directory will be loaded automatically every time you launch Neovim.[3]

- opt plugins: Plugins in an opt directory are optional and can be loaded on-demand using the :packadd <plugin-name> command in Neovim.[3] This is useful for plugins you don't need all the time, which helps to keep your startup time fast.

Create the necessary directories:

```bash
mkdir -p ~/.local/share/nvim/site/pack/mypackages/start
```

Clone the plugin repository:
Navigate to the start directory you just created and clone the plugin's Git repository:

```bash
cd ~/.local/share/nvim/site/pack/mypackages/start
```

```bash
git clone https://github.com/nvim-treesitter/nvim-treesitter
```


That's it! The next time you open Neovim, the nvim-treesitter plugin will be loaded. You can then add its configuration to your init.lua or init.vim file located in ~/.config/nvim/.

To find the correct path for your system, you can run the command :echo stdpath('config') from within Neovim