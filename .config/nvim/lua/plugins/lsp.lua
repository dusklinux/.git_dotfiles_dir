-- ================================================================================================
-- TITLE : LSP Configuration (The Brain)
-- ABOUT : Configures Language Servers for intelligence
-- ================================================================================================

return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
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

		-- 2. Define capabilities ONCE
		local capabilities = require("cmp_nvim_lsp").default_capabilities()

		-- 3. Mason Managed Servers (Everything EXCEPT Lua)
		-- We REMOVED lua_ls from here because Mason's version is broken on Arch.
		local mason_servers = {
			bashls = {},
			pyright = {},
			cssls = {},
			html = {},
			ts_ls = {}, 
			jsonls = {},
			clangd = {},
			marksman = {},
		}

		-- 4. Setup Mason Handlers
		require("mason-lspconfig").setup({
			ensure_installed = vim.tbl_keys(mason_servers),
			handlers = {
				function(server_name)
					local server_config = mason_servers[server_name] or {}
					server_config.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server_config.capabilities or {})
					require("lspconfig")[server_name].setup(server_config)
				end,
			},
		})

		-- 5. Manual Setup for System Lua LSP (The Arch Fix)
		-- This uses the /usr/bin/lua-language-server installed via pacman
		require("lspconfig").lua_ls.setup({
			capabilities = capabilities,
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
		})

		-- 6. Aesthetic Tweaks
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
