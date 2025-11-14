-- installing/Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- importing. 

require("config.options")
require("config.globals")
require("config.keymaps")
require("config.autocmds")

-- Setup lazy.nvim

require("lazy").setup({
  spec = {
    -- import your plugins
    { import = "plugins" },
  },
    rtp = {
		disabled_plugins = {
			"netrw",
			"netrwPlugin",
		},
  },
  -- Configure any other settings here. See the documentation for more details.
  -- automatically check for plugin updates
  checker = { enabled = true },
})

-- this is intentially kept here, becuase the order matters. this only needs to be loaded after lazy has loaded.
require("config.matugen")
