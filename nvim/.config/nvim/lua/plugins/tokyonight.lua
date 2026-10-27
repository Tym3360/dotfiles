return {
	"folke/tokyonight.nvim",
	name = "tokyonight",
	priority = 1000,
	lazy = false,
	config = function()
		require("tokyonight").setup({
			style = "night",
			-- let the terminal's background opacity show through (Ghostty)
			transparent = true,
			styles = {
				-- keep comments and language constructs unitalicized for readability
				comments = { italic = false },
				keywords = { italic = false },
				-- translucent panels instead of solid dark fills
				sidebars = "transparent",
				floats = "transparent",
			},
		})
		vim.cmd.colorscheme "tokyonight"
	end
}
