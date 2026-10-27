return {
	"folke/tokyonight.nvim",
	priority = 1000,
	config = function()
		require("tokyonight").setup({
			style = "night",       -- night, storm, day, moon
			-- Let the terminal background show through: Ghostty runs with
			-- background-opacity = 0.85, so Neovim must not paint its own bg.
			transparent = true,
			styles = {
				-- Without these, sidebars (neo-tree) and floating windows keep the
				-- theme's solid "dark" background and look opaque against the rest.
				sidebars = "transparent",
				floats = "transparent",
			},
			terminal_colors = true,
			-- `floats = "transparent"` covers floating windows, but Pmenu (the
			-- nvim-cmp popup, wildmenu, etc.) is hard-wired to bg_popup in the
			-- theme, so clear it here to keep the menu see-through too.
			-- PmenuSel keeps its highlight so the selected entry stays visible.
			on_highlights = function(hl, c)
				for _, group in ipairs({ "Pmenu", "PmenuMatch", "PmenuSbar" }) do
					if hl[group] then
						hl[group].bg = c.none
					end
				end
			end,
		})
		vim.cmd.colorscheme "tokyonight"
	end
}
