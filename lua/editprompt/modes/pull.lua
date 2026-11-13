local config = require("editprompt.config")
local utils = require("editprompt.utils")

local M = {}

---@class editprompt.PullOpts
---@field keep? boolean leave the draft in the agent's prompt box

--- Move the cursor to the end of the current buffer
local function move_cursor_to_end()
  local line_count = vim.api.nvim_buf_line_count(0)
  local last_line = vim.api.nvim_buf_get_lines(0, -2, -1, false)[1] or ""
  vim.api.nvim_win_set_cursor(0, { line_count, #last_line })
end

--- Pull the prompt box content of the target panes into the current buffer
---@param opts editprompt.PullOpts
---@param on_inserted? fun() called after the pulled text is inserted
local function pull(opts, on_inserted)
  local args = vim.deepcopy(config.get_cmd())
  vim.list_extend(args, { "pull" })
  if opts.keep then
    table.insert(args, "--keep")
  end

  vim.system(args, { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        local err_msg = result.stderr or "Unknown error"
        vim.notify("editprompt error: " .. err_msg, vim.log.levels.ERROR)
        return
      end

      local output = (result.stdout or ""):gsub("\n$", "")
      -- An empty prompt box without a suggestion is a normal state
      if output == "" then
        vim.notify("Nothing to pull", vim.log.levels.WARN)
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

--- Pull the draft or the suggestion and leave the cursor at the end of the buffer
---@param opts? editprompt.PullOpts
function M.execute(opts)
  pull(opts or {})
end

--- Pull the draft or the suggestion, then send the whole buffer to the target pane.
--- Sending through the buffer keeps the prompt in history like `input --auto-send`.
--- The draft is always cleared from the prompt box, otherwise sending would duplicate it.
function M.execute_auto_send()
  pull({ keep = false }, function()
    require("editprompt.modes.input").execute_auto_send()
  end)
end

return M
