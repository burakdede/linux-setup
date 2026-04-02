-- Developer tools plugins
-- lua/plugins/tools.lua
--
-- File navigation, fuzzy finding, git integration, and other utilities.
-- Un-comment the sections you want.

return {
    -- ─── Fuzzy finder (telescope) ─────────────────────────────────────────────
    -- {
    --     "nvim-telescope/telescope.nvim",
    --     cmd          = "Telescope",
    --     dependencies = { "nvim-lua/plenary.nvim" },
    --     keys = {
    --         { "<leader>ff", "<cmd>Telescope find_files<cr>",  desc = "Find files" },
    --         { "<leader>fg", "<cmd>Telescope live_grep<cr>",   desc = "Live grep" },
    --         { "<leader>fb", "<cmd>Telescope buffers<cr>",     desc = "Buffers" },
    --         { "<leader>fh", "<cmd>Telescope help_tags<cr>",   desc = "Help tags" },
    --     },
    -- },

    -- ─── File tree ────────────────────────────────────────────────────────────
    -- {
    --     "nvim-neo-tree/neo-tree.nvim",
    --     branch       = "v3.x",
    --     dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "MunifTanjim/nui.nvim" },
    --     keys = {
    --         { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle file tree" },
    --     },
    -- },

    -- ─── Git ──────────────────────────────────────────────────────────────────
    -- {
    --     "lewis6991/gitsigns.nvim",
    --     event = "BufReadPre",
    --     opts  = {},
    -- },

    -- ─── Which-key ────────────────────────────────────────────────────────────
    -- Shows a popup with available key bindings.
    -- {
    --     "folke/which-key.nvim",
    --     event = "VeryLazy",
    --     opts  = {},
    -- },

    -- ─── Auto-pairs ───────────────────────────────────────────────────────────
    -- {
    --     "windwp/nvim-autopairs",
    --     event = "InsertEnter",
    --     opts  = {},
    -- },

    -- ─── Comment ──────────────────────────────────────────────────────────────
    -- {
    --     "numToStr/Comment.nvim",
    --     keys = { { "gc", mode = { "n", "v" } }, { "gb", mode = { "n", "v" } } },
    --     opts = {},
    -- },
}
