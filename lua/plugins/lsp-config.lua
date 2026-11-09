local ensure_lsp = {
	"lua_ls",
	"cmake",
	"clangd",
	"csharp_ls",
	"powershell_es",
	"pylsp",
}

local setup_lsp = function(lsp, capabilities)
	vim.lsp.config(lsp, { capabilities = capabilities })
	vim.lsp.enable(lsp)
end

return {
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = ensure_lsp,
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		config = function()
			local capabilities = require("blink.cmp").get_lsp_capabilities()
			for _, lsp in ipairs(ensure_lsp) do
				setup_lsp(lsp, capabilities)
			end

			vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
			vim.keymap.set("n", "gD", vim.lsp.buf.declaration, {})
			vim.keymap.set("n", "gi", vim.lsp.buf.implementation, {})
			vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, {})
			vim.keymap.set({ "n", "v" }, "<Space>ca", vim.lsp.buf.code_action, {})
		end,
	},
}
