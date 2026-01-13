local config = require("editprompt.config")

local M = {}

--- Save current buffer
local function save_buffer()
  vim.cmd("update")
end

--- Get buffer content as string
---@return string
local function get_buffer_content()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  return table.concat(lines, "\n")
end

--- Clear buffer and save
local function clear_buffer()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
  vim.cmd("update")
end

--- Execute input command with specified flag
---@param flag string "--always-copy" or "--auto-send"
local function execute_input(flag)
  save_buffer()
  local content = get_buffer_content()

  local cmd = config.get_cmd()
  local args = vim.list_extend(cmd, { "input", flag, "--", content })

  vim.system(args, {}, function(result)
    vim.schedule(function()
      if result.code == 0 then
        clear_buffer()
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
