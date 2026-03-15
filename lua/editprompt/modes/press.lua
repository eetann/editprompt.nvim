local config = require("editprompt.config")
local key_notation = require("editprompt.key_notation")

local M = {}

--- Send a key to the target pane via editprompt CLI
---@param key string Neovim key notation (e.g., "<CR>", "<Tab>", "1")
function M.execute(key)
  if not key or key == "" then
    return
  end

  local converted = key_notation.convert(key)

  local args = vim.deepcopy(config.get_cmd())
  vim.list_extend(args, { "press", "--", converted })

  vim.system(args, { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        local err_msg = result.stderr or "Unknown error"
        vim.notify("editprompt error: " .. err_msg, vim.log.levels.ERROR)
      end
    end)
  end)
end

return M
