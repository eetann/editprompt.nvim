local M = {}

--- Save current buffer
function M.save_buffer()
  vim.cmd("update")
end

--- Get buffer content as string
---@return string
function M.get_buffer_content()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  return table.concat(lines, "\n")
end

--- Clear buffer and save
function M.clear_buffer()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
  vim.cmd("update")
end

--- Check if buffer is empty
---@return boolean
function M.is_buffer_empty()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  return #lines == 0 or (#lines == 1 and lines[1] == "")
end

--- Insert content into buffer
---@param content string
function M.insert_to_buffer(content)
  local new_lines = vim.split(content, "\n", { plain = true })

  if M.is_buffer_empty() then
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

return M
