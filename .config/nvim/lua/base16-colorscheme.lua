-- lua/base16-colorscheme.lua
-- This file bridges the gap between Matugen's output and mini.base16
local M = {}

function M.setup(colors)
  -- Matugen generates a table of colors (base00, base01, etc.)
  -- We pass this palette to mini.base16 to create the theme.
  require("mini.base16").setup({
    palette = colors
  })
end

return M
