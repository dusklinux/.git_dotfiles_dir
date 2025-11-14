-- ================================================================================================
-- TITLE : nvim-tree.lua
-- ABOUT : A file explorer tree for Neovim, written in Lua.
-- LINKS :
--   > github : https://github.com/nvim-tree/nvim-tree.lua
-- ================================================================================================

return {
	"nvim-tree/nvim-tree.lua",
	lazy = false,
	config = function()

		-- Remove background color from the NvimTree window (ui fix) (this is a fix for the current theme remove this line if you use another theme)
		vim.cmd([[hi NvimTreeNormal guibg=NONE ctermbg=NONE]])
-- above line for theme

		require("nvim-tree").setup({
			filters = {
				dotfiles = false, -- Show hidden files (dotfiles)
			},
			view = {
				adaptive_size = true,
			},
		})
	end,
}
