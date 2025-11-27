-- ================================================================================================
-- TITLE : conform.nvim (The Discipline)
-- ABOUT : Auto-formatting for all your code (Bash, Lua, Python, JS, C++, Markdown)
-- ================================================================================================

return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			-- "<leader>cf" = Code Format
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
			-- Scripting
			lua = { "stylua" },
			python = { "isort", "black" },
			bash = { "shfmt" },
			sh = { "shfmt" },
			zsh = { "shfmt" },

			-- Web Dev
			javascript = { "prettierd", "prettier" },
			typescript = { "prettierd", "prettier" },
			html = { "prettierd", "prettier" },
			css = { "prettierd", "prettier" },
			json = { "prettierd", "prettier" },

			-- Markdown (New Addition)
			markdown = { "prettierd", "prettier" },
			["markdown.mdx"] = { "prettierd", "prettier" },

			-- Low Level
			c = { "clang-format" },
			cpp = { "clang-format" },
		},

		-- Set up format-on-save
		format_on_save = {
			timeout_ms = 500,
			lsp_fallback = true,
		},
	},
}
