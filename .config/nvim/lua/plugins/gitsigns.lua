return {
	"lewis6991/gitsigns.nvim",
	event = { "BufReadPre", "BufNewFile" },
	opts = {
		-- 1. The Aesthetic "Rice" Settings
		signs = {
			add = { text = "" },
			change = { text = "" },
			delete = { text = "󰮉" },
			topdelete = { text = "" },
			changedelete = { text = "" },
			untracked = { text = "" },
		},
		numhl = false,
		linehl = false,

		-- 2. Behavior Settings
		signcolumn = true,

		-- Critical for dotfiles: show the "new file" bar for untracked files
		attach_to_untracked = true,

		-- 3. The "Dual Mode" Logic
		worktrees = {
			{
				toplevel = os.getenv("HOME"),
				gitdir = os.getenv("HOME") .. "/dusky",
			},
		},
	},
	-- We use the config function to run the setup AND force the highlight overrides
	config = function(_, opts)
		require("gitsigns").setup(opts)

		-- Force every GitSigns highlight group to link to "GitSignsAdd" (Green/Add color)
		vim.api.nvim_set_hl(0, "GitSignsChange", { link = "GitSignsAdd" })
		vim.api.nvim_set_hl(0, "GitSignsDelete", { link = "GitSignsAdd" })
		vim.api.nvim_set_hl(0, "GitSignsTopDelete", { link = "GitSignsAdd" })
		vim.api.nvim_set_hl(0, "GitSignsChangeDelete", { link = "GitSignsAdd" })
		vim.api.nvim_set_hl(0, "GitSignsUntracked", { link = "GitSignsAdd" })
	end,
}
