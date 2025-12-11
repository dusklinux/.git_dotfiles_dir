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
          -- Merge capabilities
          server_config.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server_config.capabilities or {})
          require("lspconfig")[server_name].setup(server_config)
        end,
      },
    })

    -- 5. Manual Setup for System Lua LSP (The Arch Fix)
    local lua_opts = {
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
    }

    -- CRITICAL FIX for Nvim 0.11 Crash:
    -- 1. Force load the config definition to prevent "nil value" error
    --    (This ensures lspconfig.lua_ls exists before we use it)
    local lspconfig = require("lspconfig")
    local configs = require("lspconfig.configs")
    
    -- Accessing configs.lua_ls forces the lazy-loader to pull it in
    if not configs.lua_ls then
       pcall(require, "lspconfig.server_configurations.lua_ls")
    end

    -- 2. Setup safely
    if lspconfig.lua_ls then
      lspconfig.lua_ls.setup(lua_opts)
    elseif configs.lua_ls then
      -- Fallback: If lspconfig.lua_ls is still nil (0.11 strict mode),
      -- we instantiate the default config manually.
      configs.lua_ls.setup(lua_opts)
    else
      vim.notify("Could not load lua_ls configuration!", vim.log.levels.ERROR)
    end
  end,
}
