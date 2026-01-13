local config = require("editprompt.config")
local utils = require("editprompt.utils")

local M = {}

--- Execute capture (dump) command
function M.execute()
  utils.save_buffer()

  local cmd = config.get_cmd()
  local args = vim.list_extend(cmd, { "dump" })

  vim.system(args, {}, function(result)
    vim.schedule(function()
      if result.code == 0 then
        local output = result.stdout or ""
        -- Remove trailing newline if present
        output = output:gsub("\n$", "")
        utils.insert_to_buffer(output)
      else
        local err_msg = result.stderr or "Unknown error"
        vim.notify("editprompt error: " .. err_msg, vim.log.levels.ERROR)
      end
    end)
  end)
end

return M
