return {
    "goolord/alpha-nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        local alpha = require("alpha")
        local dashboard = require("alpha.themes.dashboard")

        vim.api.nvim_set_hl(0, "TNPunkGreen", { fg = "#00ff66", bold = true })

        dashboard.section.header.val = {
            "  ████████╗███╗   ██╗██████╗ ██╗   ██╗███╗   ██╗██╗  ██╗",
            "  ╚══██╔══╝████╗  ██║██╔══██╗██║   ██║████╗  ██║██║ ██╔╝",
            "     ██║   ██╔██╗ ██║██████╔╝██║   ██║██╔██╗ ██║█████╔╝ ",
            "     ██║   ██║╚██╗██║██╔═══╝ ██║   ██║██║╚██╗██║██╔═██╗ ",
            "     ██║   ██║ ╚████║██║     ╚██████╔╝██║ ╚████║██║  ██╗",
            "     ╚═╝   ╚═╝  ╚═══╝╚═╝      ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝",
            "                     [ TNPUNK - gr0cx ]                 ",
        }

        dashboard.section.header.opts = {
            hl = "TNPunkGreen",
            position = "center"
        }

        dashboard.section.buttons.val = {
            dashboard.button("f", " Search file", ":Telescope find_files<CR>"),
            dashboard.button("r", " Recent files", ":Telescope oldfiles<CR>"),
            dashboard.button("g", "󰱼 Search text (Grep)", ":Telescope live_grep<CR>"),
            dashboard.button("e", " File explorer", ":Neotree toggle<CR>"),
            dashboard.button("t", "󰏘 Theme selector", ":Telescope colorscheme<CR>"),
            dashboard.button("l", "󰒲 Plugins manager (Lazy)", ":Lazy<CR>"),
            dashboard.button("q", " Exit Neovim", ":qa<CR>")
        }

        for _, button in ipairs(dashboard.section.buttons.val) do
            button.opts.hl = "Constant"
            button.opts.hl_shortcut = "String"
        end

        alpha.setup(dashboard.opts)
    end,
}
