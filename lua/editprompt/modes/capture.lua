local config = require("editprompt.config")

local M = {}

--- Save current buffer
local function save_buffer()
  vim.cmd("update")
end

--- Check if buffer is empty
---@return boolean
local function is_buffer_empty()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  return #lines == 0 or (#lines == 1 and lines[1] == "")
end

--- Insert content into buffer
---@param content string
local function insert_to_buffer(content)
  local new_lines = vim.split(content, "\n", { plain = true })

  if is_buffer_empty() then
    -- Insert at the beginning
    vim.api.nvim_buf_set_lines(0, 0, -1, false, new_lines)
  else
    -- Append at the end with empty line separator
    local line_count = vim.api.nvim_buf_line_count(0)
    local lines_to_add = { "" }
    vim.list_extend(lines_to_add, new_lines)
    vim.api.nvim_buf_set_lines(0, line_count, line_count, false, lines_to_add)
  end
end

--- Execute capture (dump) command
function M.execute()
  save_buffer()

  local cmd = config.get_cmd()
  local args = vim.list_extend(cmd, { "dump" })

  vim.system(args, {}, function(result)
    vim.schedule(function()
      if result.code == 0 then
        local output = result.stdout or ""
        -- Remove trailing newline if present
        output = output:gsub("\n$", "")
        insert_to_buffer(output)
      else
        local err_msg = result.stderr or "Unknown error"
        vim.notify("editprompt error: " .. err_msg, vim.log.levels.ERROR)
      end
    end)
  end)
end

return M
