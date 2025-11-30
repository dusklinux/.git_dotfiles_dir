return {
  {
    "echasnovski/mini.base16",
    lazy = false,    -- CRITICAL: Load immediately during startup
    priority = 1000, -- CRITICAL: Load before everything else (Lualine, Noice, etc.)
    config = function()
      -- Define the path to your Matugen output
      local matugen_path = os.getenv("HOME") .. "/.config/matugen/generated/neovim-colors.lua"

      -- Function to safely source the theme
      local function load_theme()
        -- OPTIMIZATION: Use libuv (fast) to check file existence
        if vim.uv.fs_stat(matugen_path) then
          local ok, err = pcall(dofile, matugen_path)
          if not ok then
            vim.notify("Matugen Load Error: " .. err, vim.log.levels.ERROR)
            -- Fallback to prevent crash if matugen fails
            require("mini.base16").setup() 
          end
        else
          vim.notify("Matugen colors not found. Generating defaults.", vim.log.levels.WARN)
          require("mini.base16").setup()
        end
      end

      -- 1. Load the theme
      load_theme()

      -- 2. Apply tweaks that must happen AFTER the theme loads
      local function apply_tweaks()
        vim.api.nvim_set_hl(0, "Comment", { italic = true })
        
        -- UI FIX: Remove background from NvimTree to make it blend with the terminal/transparency
        vim.api.nvim_set_hl(0, "NvimTreeNormal", { bg = "NONE", ctermbg = "NONE" })

        -- Reset cursor shape (Hyprland optimization)
        vim.opt.guicursor = "n-v-c:hor20-Cursor,i-ci-ve:ver25-Cursor,r-cr-o:hor20-Cursor"
      end
      
      apply_tweaks()

      -- 3. Live Reloading (Libuv Signal Listener)
      -- This correctly listens for 'pkill -USR1 nvim' on Arch/Linux
      local signal = vim.uv.new_signal()
      signal:start("sigusr1", function()
        vim.schedule(function()
          load_theme()
          apply_tweaks()
          -- Optional: Refresh lualine if it's loaded to pick up new globals
          if package.loaded["lualine"] then
            require("lualine").refresh()
          end
          vim.notify("Theme reloaded via SIGUSR1")
        end)
      end)
    end,
  },
}
