local config = require("editprompt.config")
local utils = require("editprompt.utils")

local M = {}

--- Execute input command with specified flag
---@param flag string "--always-copy" or "--auto-send"
local function execute_input(flag)
  utils.save_buffer()
  local content = utils.get_buffer_content()

  local cmd = config.get_cmd()
  local args = vim.list_extend(cmd, { "input", flag, "--", content })

  vim.system(args, {}, function(result)
    vim.schedule(function()
      if result.code == 0 then
        utils.clear_buffer()
      else
        local err_msg = result.stderr or "Unknown error"
        vim.notify("editprompt error: " .. err_msg, vim.log.levels.ERROR)
      end
    end)
  end)
end

--- Execute input with --always-copy
function M.execute()
  execute_input("--always-copy")
end

--- Execute input with --auto-send
function M.execute_auto_send()
  execute_input("--auto-send")
end

return M
