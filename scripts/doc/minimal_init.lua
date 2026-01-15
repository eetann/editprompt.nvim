vim.env.LAZY_STDPATH = ".repro"
load(
  vim.fn.system(
    "curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"
  )
)()

local plugins = {
  {
    dir = vim.uv.cwd(),
    lazy = true,
  },
}

vim.o.loadplugins = true
require("lazy").setup({
  spec = plugins,
  change_detection = { enabled = false },
})
io.stdout:write(require("editprompt.config")._format_default())
