return {
  "mbbill/undotree",
  lazy = false, -- We load it immediately so the history is ready
  keys = {
    -- Binds <leader>u to toggle the tree. Change "u" if you prefer.
    { "<leader>u", vim.cmd.UndotreeToggle, desc = "Toggle Undotree" },
  },
  config = function()
    -- Optional: Focus the tree immediately when opened
    vim.g.undotree_SetFocusWhenToggle = 1
  end,
}
