-- ================================================================================================
-- TITLE : LSP Configuration (The Brain)
-- ABOUT : Configures Language Servers for intelligence
-- ================================================================================================

return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" }, -- OPTIMIZATION: Load only when reading a file
	dependencies = {
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
		"hrsh7th/cmp-nvim-lsp",
	},
	config = function()
		-- 1. Setup Mason
		require("mason").setup({
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		})

		-- 2. Define servers
		local servers = {
			bashls = {},
			pyright = {},
			lua_ls = {
				settings = {
					Lua = {
						diagnostics = { globals = { "vim" } },
						workspace = {
							library = {
								[vim.fn.expand("$VIMRUNTIME/lua")] = true,
								[vim.fn.stdpath("config") .. "/lua"] = true,
							},
						},
					},
				},
			},
			cssls = {},
			html = {},
			ts_ls = {}, 
			jsonls = {},
			clangd = {},
			marksman = {},
		}

		-- 3. OPTIMIZATION: Define capabilities ONCE before the loop
		local capabilities = require("cmp_nvim_lsp").default_capabilities()

		-- 4. Ensure they are installed
		require("mason-lspconfig").setup({
			ensure_installed = vim.tbl_keys(servers),
			handlers = {
				function(server_name)
					local server_config = servers[server_name] or {}

					-- Merge the capabilities we defined above
					server_config.capabilities =
						vim.tbl_deep_extend("force", {}, capabilities, server_config.capabilities or {})

					require("lspconfig")[server_name].setup(server_config)
				end,
			},
		})

		-- 5. Aesthetic Tweaks
		vim.diagnostic.config({
			virtual_text = true,
			underline = true,
			update_in_insert = false,
			severity_sort = true,
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = " ",
					[vim.diagnostic.severity.WARN] = " ",
					[vim.diagnostic.severity.HINT] = "󰠠 ",
					[vim.diagnostic.severity.INFO] = " ",
				},
			},
		})
	end,
}
