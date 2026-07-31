local M = {}

local entries = {}
local index = nil
local draft = nil

local function get_buffer_content()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  return table.concat(lines, "\n")
end

local function set_buffer_content(content)
  local lines = {}
  if content ~= "" then
    lines = vim.split(content, "\n", { plain = true })
  end

  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

local function reset_session()
  index = nil
  draft = nil
end

local function ensure_session()
  local newest_index = #entries + 1

  if index == nil then
    draft = get_buffer_content()
    index = newest_index
    return
  end

  if index == newest_index then
    draft = get_buffer_content()
  end
end

local function navigate(step)
  if #entries == 0 then
    return false
  end

  ensure_session()

  local newest_index = #entries + 1
  local next_index = math.max(1, math.min(index + step, newest_index))
  index = next_index

  local text = next_index == newest_index and (draft or "")
    or entries[next_index]
  set_buffer_content(text)
  return true
end

function M.push(text)
  if text == "" then
    return
  end

  table.insert(entries, text)
  reset_session()
end

function M.prev()
  return navigate(-1)
end

function M.next()
  return navigate(1)
end

--- List all sent entries, newest first
---@return string[]
function M.list()
  local result = {}
  for i = #entries, 1, -1 do
    table.insert(result, entries[i])
  end
  return result
end

function M._reset()
  entries = {}
  reset_session()
end

return M
