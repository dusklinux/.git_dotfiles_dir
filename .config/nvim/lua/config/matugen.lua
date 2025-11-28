-- ~/.config/nvim/lua/config/matugen.lua

local M = {}

-- Path to Matugen output
local matugen_path = os.getenv("HOME") .. "/.config/matugen/generated/neovim-colors.lua"

local function source_matugen()
  -- OPTIMIZATION: Check if file exists first
  local f = io.open(matugen_path, "r")
  if f ~= nil then
    io.close(f)
    
    -- SAFETY: Use pcall (protected call) to prevent crashes if the generated file is corrupt
    local ok, err = pcall(dofile, matugen_path)
    if not ok then
      vim.notify("Matugen Error: " .. err, vim.log.levels.ERROR)
    end
  else
    -- Fallback if file doesn't exist
    vim.notify("Matugen colors not found.", vim.log.levels.WARN)
  end
end

local function on_matugen_reload()
  source_matugen()
  -- Post-theme refresh tweaks
  vim.api.nvim_set_hl(0, "Comment", { italic = true })

  -- SET CURSOR SHAPE:
  -- n-v-c: Normal, Visual, Command modes
  -- hor20: Horizontal Bar (20% height of the line)
  -- blinkon0: Disable blinking (optional, remove if you like blinking)
  vim.opt.guicursor = "n-v-c:hor20-Cursor,i-ci-ve:ver25-Cursor,r-cr-o:hor20-Cursor"
end

-- Listen for Matugen’s signal
vim.api.nvim_create_autocmd("Signal", {
  pattern = "SIGUSR1",
  callback = on_matugen_reload,
})

-- Initial load
on_matugen_reload()

return M
