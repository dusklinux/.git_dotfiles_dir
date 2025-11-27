return {
	"lewis6991/gitsigns.nvim",
	event = { "BufReadPre", "BufNewFile" },
	opts = {
		signs = {
			add = { text = "▎" },
			change = { text = "▎" },
			delete = { text = "" },
			topdelete = { text = "" },
			changedelete = { text = "▎" },
			untracked = { text = "▎" },
		},
		-- This highlights the line number in the gutter instead of just a symbol
		-- Set to true if you want the number to change color (very "riced" look)
		numhl = false,
		linehl = false,
	},
}
