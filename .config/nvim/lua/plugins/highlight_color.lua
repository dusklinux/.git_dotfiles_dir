-- ~/.config/nvim/lua/plugins/highlight_colors.lua
return {
  {
    "brenoprata10/nvim-highlight-colors",
    lazy = false,           -- load at startup
    opts = {
      render = "background",
      enable_named_colors = true,
    },
  },
}
