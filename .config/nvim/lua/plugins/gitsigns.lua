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
		-- This ensures the sign column is clear, but since you fixed it
		-- in options.lua, this is just a backup.
		signcolumn = true,

		-- Critical for dotfiles: show the "new file" bar for untracked files
		attach_to_untracked = true,

		-- 3. The "Dual Mode" Logic
		-- Gitsigns automatically detects normal git repos (like ~/git_test_folder).
		-- This 'worktrees' block essentially tells it:
		-- "If you don't find a normal git repo, check if we are in the Home directory
		-- and use the dotfiles bare repo."
		worktrees = {
			{
				toplevel = os.getenv("HOME"),
				gitdir = os.getenv("HOME") .. "/.git_dotfiles_dir",
			},
		},
	},
}
