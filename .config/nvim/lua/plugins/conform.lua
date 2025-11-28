-- ================================================================================================
-- TITLE : conform.nvim (The Discipline)
-- ABOUT : Manual formatting only. Auto-save formatting is DISABLED.
-- ================================================================================================

return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>cf",
			function()
				require("conform").format({ async = true, lsp_fallback = true })
			end,
			mode = "",
			desc = "Format buffer",
		},
	},
	opts = {
		-- Define your formatters
		formatters_by_ft = {
			lua = { "stylua" },
			python = { "isort", "black" },
			bash = { "shfmt" },
			sh = { "shfmt" },
			zsh = { "shfmt" },
			javascript = { "prettierd", "prettier" },
			typescript = { "prettierd", "prettier" },
			html = { "prettierd", "prettier" },
			css = { "prettierd", "prettier" },
			json = { "prettierd", "prettier" },
			jsonc = { "prettierd", "prettier" },
			markdown = { "prettier" },
			["markdown.mdx"] = { "prettier" },
			c = { "clang-format" },
			cpp = { "clang-format" },
		},

		-- format_on_save is intentionally REMOVED.
		-- To format a file, you must press <leader>cf manually.
	},
}
