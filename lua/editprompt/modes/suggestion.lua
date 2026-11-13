local config = require("editprompt.config")
local utils = require("editprompt.utils")

local M = {}

--- Move the cursor to the end of the current buffer
local function move_cursor_to_end()
  local line_count = vim.api.nvim_buf_line_count(0)
  local last_line = vim.api.nvim_buf_get_lines(0, -2, -1, false)[1] or ""
  vim.api.nvim_win_set_cursor(0, { line_count, #last_line })
end

--- Insert prompt suggestions kept by editprompt CLI into the current buffer
---@param on_inserted? fun() called after the suggestions are inserted
local function insert(on_inserted)
  local args = vim.deepcopy(config.get_cmd())
  vim.list_extend(args, { "suggestion", "get" })

  vim.system(args, { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        local err_msg = result.stderr or "Unknown error"
        vim.notify("editprompt error: " .. err_msg, vim.log.levels.ERROR)
        return
      end

      local output = (result.stdout or ""):gsub("\n$", "")
      -- No suggestion is a normal state, so warn instead of raising an error
      if output == "" then
        vim.notify("No suggestion", vim.log.levels.WARN)
        return
      end

      utils.insert_to_buffer(output)
      move_cursor_to_end()

      if on_inserted then
        on_inserted()
      end
    end)
  end)
end

--- Insert suggestions and leave the cursor at the end of the buffer
function M.execute()
  insert()
end

--- Insert suggestions, then send the whole buffer to the target pane.
--- Sending through the buffer keeps the prompt in history like `input --auto-send`.
function M.execute_auto_send()
  insert(function()
    require("editprompt.modes.input").execute_auto_send()
  end)
end

return M
