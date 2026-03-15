local sender = require("editprompt.sender")
local utils = require("editprompt.utils")

local M = {}

local function exit_to_normal()
  vim.cmd("stopinsert")
  local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
  vim.api.nvim_feedkeys(esc, "nx", false)
end

---@param content string
---@param auto_send boolean
local function execute_content(content, auto_send)
  sender.send(content, {
    source = "content",
    copy = not auto_send,
    auto_send = auto_send,
  })
end

--- Execute input with default copy behavior
function M.execute()
  utils.save_buffer()
  sender.send(utils.get_buffer_content(), {
    source = "buffer",
    bufnr = vim.api.nvim_get_current_buf(),
    clear_buffer = true,
  })
end

--- Execute input with --auto-send
function M.execute_auto_send()
  utils.save_buffer()
  sender.send(utils.get_buffer_content(), {
    source = "buffer",
    bufnr = vim.api.nvim_get_current_buf(),
    copy = false,
    auto_send = true,
    clear_buffer = true,
  })
end

---@param content string
function M.execute_content(content)
  execute_content(content, false)
end

---@param content string
function M.execute_content_auto_send(content)
  execute_content(content, true)
end

--- Execute visual input with default copy behavior
---@param opts? table
function M.execute_visual(opts)
  opts = opts or {}

  local content = sender.get_selected_lines(opts.start_pos, opts.end_pos)
  if not content then
    return
  end

  exit_to_normal()
  sender.send(content, {
    source = "visual",
    bufnr = vim.api.nvim_get_current_buf(),
    delete_selection = true,
    start_pos = opts.start_pos,
    end_pos = opts.end_pos,
    after_success = function()
      exit_to_normal()
    end,
  })
end

--- Execute visual input with --auto-send
---@param opts? table
function M.execute_visual_auto_send(opts)
  opts = opts or {}

  local content = sender.get_selected_lines(opts.start_pos, opts.end_pos)
  if not content then
    return
  end

  exit_to_normal()
  sender.send(content, {
    source = "visual",
    bufnr = vim.api.nvim_get_current_buf(),
    copy = false,
    auto_send = true,
    delete_selection = true,
    start_pos = opts.start_pos,
    end_pos = opts.end_pos,
    after_success = function()
      exit_to_normal()
    end,
  })
end

return M
