-- ============================================================
-- Options
-- ============================================================
vim.g.mapleader = " "

local o = vim.o
o.number         = true
o.relativenumber = true
o.signcolumn     = "yes"
o.scrolloff      = 8
o.mouse          = "a"
o.clipboard      = "unnamedplus"   -- presse-papier système (via wl-clipboard)
o.ignorecase     = true
o.smartcase      = true
o.undofile       = true
o.updatetime     = 250
o.splitright     = true
o.splitbelow     = true
o.expandtab      = true
o.shiftwidth     = 4
o.tabstop        = 4
o.winborder      = "rounded"
o.completeopt    = "menu,menuone,noinsert,fuzzy,popup"

-- 2 espaces pour le web, le JSON, le YAML, le Lua
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "javascript", "typescript", "typescriptreact", "json", "yaml", "html", "css", "lua" },
  command = "setlocal shiftwidth=2 tabstop=2",
})

-- ============================================================
-- Plugins (gestionnaire intégré vim.pack)
-- ============================================================
-- Recompile les parsers treesitter quand le plugin est installé ou mis à jour
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local d = ev.data
    if d.spec.name == "nvim-treesitter" and (d.kind == "install" or d.kind == "update") then
      vim.schedule(function() pcall(vim.cmd, "TSUpdate") end)
    end
  end,
})

vim.pack.add({
  "https://github.com/folke/tokyonight.nvim",
  "https://github.com/neovim/nvim-lspconfig",        -- fournit les configs par défaut des serveurs
  "https://github.com/ibhagwan/fzf-lua",
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
})

vim.cmd.colorscheme("tokyonight")

-- ============================================================
-- Treesitter (coloration syntaxique)
-- ============================================================
require("nvim-treesitter").install({
  "lua", "python", "rust", "go", "gomod", "c", "cpp", "cmake", "make",
  "javascript", "typescript", "tsx", "html", "css", "json", "yaml", "toml",
  "bash", "markdown", "markdown_inline", "dockerfile",
})

vim.api.nvim_create_autocmd("FileType", {
  callback = function() pcall(vim.treesitter.start) end,
})

-- ============================================================
-- LSP (natif)
-- ============================================================
vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      runtime     = { version = "LuaJIT" },
      diagnostics = { globals = { "vim" } },
      workspace   = { library = { vim.env.VIMRUNTIME }, checkThirdParty = false },
    },
  },
})

vim.lsp.enable({
  "lua_ls", "pyright", "ruff", "rust_analyzer",
  "gopls", "clangd", "ts_ls", "bashls",
})

vim.diagnostic.config({ virtual_text = true, severity_sort = true })

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    local map = function(lhs, rhs) vim.keymap.set("n", lhs, rhs, { buffer = args.buf }) end

    -- Complétion automatique native
    if client and client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
    end

    map("gd", vim.lsp.buf.definition)
    map("<leader>f", function() vim.lsp.buf.format({ async = true }) end)
    map("<leader>e", vim.diagnostic.open_float)
  end,
})

-- ============================================================
-- Raccourcis généraux
-- ============================================================
local fzf = function(fn) return function() require("fzf-lua")[fn]() end end
vim.keymap.set("n", "<leader>ff", fzf("files"),     { desc = "Fichiers" })
vim.keymap.set("n", "<leader>fg", fzf("live_grep"), { desc = "Recherche texte" })
vim.keymap.set("n", "<leader>fb", fzf("buffers"),   { desc = "Buffers" })
vim.keymap.set("n", "<leader>fh", fzf("helptags"),  { desc = "Aide" })
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>")
