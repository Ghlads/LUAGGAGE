return { 
  "nvim-treesitter/nvim-treesitter", 
  build = ":TSUpdate", 
  config = function()
    local config = require("nvim-treesitter.config")
    config.setup({
      ensure_installed = { "lua", "c", "python", "vim", "c++", "html", "css", "mathlab", "javascript", "typescript", "yaml", "shell" },
      sync_install = false,
      highlight = { enable = true },
      indent = { enable = true },
    })
  end
}
