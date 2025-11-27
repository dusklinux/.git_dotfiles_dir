-- ~/.config/nvim/lua/config/matugen.lua

local M = {}

-- Path to Matugen output
local matugen_path = os.getenv("HOME") .. "/.config/matugen/generated/neovim-colors.lua"

local function source_matugen()
  local file = io.open(matugen_path, "r")
  if not file then
    vim.cmd("colorscheme base16-catppuccin-mocha")
    vim.notify("Matugen colors not found, using fallback theme.", vim.log.levels.WARN)
    return
  end
  io.close(file)
  dofile(matugen_path)
end

local function on_matugen_reload()
  source_matugen()

  -- Any other post-theme refresh tweaks
  vim.api.nvim_set_hl(0, "Comment", { italic = true })
end

-- Listen for Matugen’s signal
vim.api.nvim_create_autocmd("Signal", {
  pattern = "SIGUSR1",
  callback = on_matugen_reload,
})

-- Initial load
on_matugen_reload()

return M
