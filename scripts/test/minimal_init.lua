vim.env.LAZY_STDPATH = ".repro"
load(
  vim.fn.system(
    "curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"
  )
)()

local plugins = {
  { "echasnovski/mini.test", opts = {} },
  -- {
  --   "folke/tokyonight.nvim",
  --   config = function()
  --     vim.cmd([[colorscheme tokyonight]])
  --   end,
  -- },
  -- {
  --   "EdenEast/nightfox.nvim",
  --   config = function()
  --     vim.cmd([[colorscheme terafox]])
  --   end,
  -- },
  {
    dir = vim.uv.cwd(),
    dependencies = {
      {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        -- need tree-sitter-cli
        -- https://github.com/tree-sitter/tree-sitter/blob/master/crates/cli/README.md
        build = ":TSUpdate",
        lazy = false,
        config = function()
          local languages = {
            "javascript",
            "lua",
            "markdown",
            "typescript",
          }
          require("nvim-treesitter").install(languages)

          local filetypes = {}
          for _, lang in ipairs(require("nvim-treesitter").get_available(2)) do
            for _, filetype in
              ipairs(vim.treesitter.language.get_filetypes(lang))
            do
              table.insert(filetypes, filetype)
            end
          end

          vim.api.nvim_create_autocmd("FileType", {
            pattern = filetypes,
            group = vim.api.nvim_create_augroup("vim-treesitter-start", {}),
            callback = function()
              pcall(vim.treesitter.start)
              vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
              vim.bo.indentexpr =
                "v:lua.require('nvim-treesitter').indentexpr()"
            end,
          })
        end,
      },
    },
    lazy = false,
    opts = {},
  },
}

vim.opt.clipboard = { "unnamedplus", "unnamed" }
vim.o.loadplugins = true
require("lazy").setup({
  spec = plugins,
  change_detection = { enabled = false },
})
