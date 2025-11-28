-- lua/plugins/lualine.lua
return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local noice = require("noice")

    require("lualine").setup({
      options = {
        theme = "auto", -- Adapts to your generated Base16 colors automatically
        globalstatus = true,
        component_separators = "|",
        section_separators = { left = "", right = "" },
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { 
          "filename", 
          {
            noice.api.status.mode.get,
            cond = noice.api.status.mode.has,
            -- FIX: Use base16 variable for Orange instead of hardcoded hex
            color = { fg = vim.g.base16_gui09 }, 
          }
        }, 
        lualine_x = {
          {
            function()
              local clients = vim.lsp.get_clients({ bufnr = 0 })
              if #clients == 0 then return "" end
              local names = {}
              for _, client in ipairs(clients) do
                table.insert(names, client.name)
              end
              return " " .. table.concat(names, ", ")
            end,
            -- FIX: Use base16 variable for Main Text (Base05) or Function Blue (Base0D)
            -- Using Base05 ensures it matches your main editor text color exactly.
            color = { fg = vim.g.base16_gui05, gui = "bold" },
          },
          "encoding", "fileformat", "filetype" 
        },
        lualine_y = { 
          "searchcount",
          "progress" 
        },
        lualine_z = { 
          "location",
          {
            function() 
              return vim.api.nvim_buf_line_count(0) .. "L" 
            end,
          }
        },
      },
    })
  end,
}
