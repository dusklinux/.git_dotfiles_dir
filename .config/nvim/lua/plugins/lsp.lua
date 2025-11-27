-- ================================================================================================
-- TITLE : LSP Configuration (The Brain)
-- ABOUT : Configures Language Servers for intelligence (Bash, Python, CSS, Lua, C++, JS, HTML, MD)
-- DEPENDENCIES:
--   1. neovim/nvim-lspconfig (The core client)
--   2. williamboman/mason.nvim (The installer UI)
--   3. hrsh7th/cmp-nvim-lsp (The bridge to your autocomplete)
-- ================================================================================================

return {
	"neovim/nvim-lspconfig",
	dependencies = {
		-- Mason handles the installation of the servers so you don't have to use pacman/pip
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
		"hrsh7th/cmp-nvim-lsp", -- Links LSP to your Autocomplete (nvim-cmp)
	},
	config = function()
		-- 1. Setup Mason (The Installer)
		require("mason").setup({
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		})

		-- 2. Define which servers you want automatically installed
		local servers = {
			-- Scripting & System
			bashls = {}, -- Bash
			pyright = {}, -- Python
			lua_ls = { -- Lua (Special config to know about Neovim globals)
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

			-- Web Development
			cssls = {}, -- CSS
			html = {}, -- HTML
			ts_ls = {}, -- JavaScript / TypeScript
			jsonls = {}, -- JSON

			-- Low Level
			clangd = {}, -- C / C++

			-- Writing
			marksman = {}, -- Markdown (The new addition)
		}

		-- 3. Ensure they are installed
		require("mason-lspconfig").setup({
			ensure_installed = vim.tbl_keys(servers),
			handlers = {
				function(server_name)
					-- This function runs for every server in the list
					local server_config = servers[server_name] or {}

					-- This ties the LSP to your nvim-cmp autocomplete
					local capabilities = require("cmp_nvim_lsp").default_capabilities()
					server_config.capabilities =
						vim.tbl_deep_extend("force", {}, capabilities, server_config.capabilities or {})

					require("lspconfig")[server_name].setup(server_config)
				end,
			},
		})

		-- 4. Aesthetic Tweaks (Make errors look nice)
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
