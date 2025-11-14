# Matugen + Neovim

## The `base16-colorscheme` Plugin

As with any program broad and free as Neovim, there are infinite ways to go
about styling it. However, the easiest approach is to utilize
the `base16-colorscheme` plugin. This plugin allows you to pass in an arbitrary
list of 16 color values, and it will automatically propagate them to all
highlight groups in a reasonable fashion.

```lua
-- NOTE: THIS IS NOT THE ENTIRE TEMPLATE FILE
-- To see why, continue reading below...
require('base16-colorscheme').setup({
  base00 = "{{colors.background.default.hex}}",
  base01 = "{{colors.surface_container_lowest.default.hex}}",
  base02 = "{{colors.surface_container_low.default.hex}}",
  base03 = "{{colors.outline_variant.default.hex}}",    
  base04 = "{{colors.on_surface_variant.default.hex}}", 
  base05 = "{{colors.on_surface.default.hex}}",         
  base06 = "{{colors.inverse_on_surface.default.hex}}", 
  base07 = "{{colors.surface_bright.default.hex}}",    
  base08 = "{{colors.error.default.hex}}",
  base09 = "{{colors.tertiary.default.hex}}",
  base0A = "{{colors.secondary.default.hex}}",
  base0B = "{{colors.primary.default.hex}}",
  base0C = "{{colors.tertiary_container.default.hex}}",
  base0D = "{{colors.primary_container.default.hex}}",
  base0E = "{{colors.secondary_container.default.hex}}",
  base0F = "{{colors.error_container.default.hex}}",
})
```

While this `.setup()` call takes care of mostly everything, some additional
calls to `nvim_set_hl` may be needed to tweak colors to your liking:

``` lua
-- Make selected text stand out more
vim.api.nvim_set_hl(0, 'Visual', {
  bg = '{{colors.primary_container.default.hex}}',
  fg = '{{colors.background.default.hex}}',
})
```

## Lualine (and plugins that manage their own colors)

Because Lualine has its own specific named highlight groups, the
`base16-colorscheme` plugin cannot style it within its `setup` function.
Thankfully, Lualine is flexible enough to offer the following configuration
option, which aids the process a little:

```lua
require('lualine').setup({
  options = {
    theme = "base16",
  }
})
```

Setting this option tells Lualine to base its highlight group colors off of
some internal 16 base values (which `base16-colorscheme` sets). While this helps,
it unfortunately does not give us full hot-reloading out of the box. In addition
to this, Lualine must be **re-sourced upon every matugen update**.

If you are using an unmodified (or simple) Lualine configuration, all you need
to do is tack on a `require('lualine').setup({})` to the end of matugen's
`template.lua` and call it a day. However, if your Lualine setup is a bit
complex, it can be sub-optimal to copy its entire setup function into the
matugen template file. To solve this, you can instead extract your entire
Lualine setup into its own file, and then just call `dofile()` on said file
from both your `init.lua` and matugen template.

## Init Hook

It's a good idea to attempt to source matugen's generated file upon Neovim's
startup, falling back to a default colorscheme when the matugen file is
unavailable. The following code snippet can be added in your `init.lua` or
adjacent to safely perform this source:

```lua
local function source_matugen()
  -- Update this with the location of your output file
  local matugen_path = os.getenv("HOME") .. "/.config/nvim/generated.lua"  -- dofile doesn't expand $HOME or ~

  local file, err = io.open(matugen_path, "r")
  -- If the matugen file does not exist (yet or at all), we must initialize a color scheme ourselves
  if err ~= nil then
    -- Some placeholder theme, this will be overwritten once matugen kicks in
    vim.cmd('colorscheme base16-catppuccin-mocha')

    -- Optionally print something to the user
    vim.print("A matugen style file was not found, but that's okay! The colorscheme will dynamically change if matugen runs!")
  else
    dofile(matugen_path)
    io.close(file)
  end
end
```

## Updating Neovim with New Colors

Neovim does not support hot-reloading directly, but we must register an
`autocmd` to listen process signals and execute Lua code as a result. This is
fairly simply, as shown below:

```lua
-- Register an autocmd to listen for matugen updates
vim.api.nvim_create_autocmd("Signal", {
  pattern = "SIGUSR1",
  callback = auxiliary_function,
})


-- Main entrypoint on matugen reloads
local function auxiliary_function()
  -- Load the matugen style file to get all the new colors
  source_matugen()

  -- Because reloading base16 overwrites lualine configuration, just source lualine here
  dofile(os.getenv("HOME") .. '/.config/nvim/config/plugins/lualine-nvim.lua') -- path of your lualine setup

  -- Any other options you wish to set upon matugen reloads can also go here!
  vim.api.nvim_set_hl(0, "Comment", { italic = true })
end
```

## Matugen Config

Create an entry in matugen's `config.toml` as shown below:

```toml
[templates.neovim]
input_path = './template.lua'
output_path = '~/.config/nvim/generated.lua'
post_hook = 'pkill -SIGUSR1 nvim'
```

With any luck, your Neovim should now be stylized to match your wallpaper!
