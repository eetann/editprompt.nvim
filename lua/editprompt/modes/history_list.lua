local config = require("editprompt.config")
local utils = require("editprompt.utils")
local history = require("editprompt.history")

local M = {}

--- Truncate content for display
--- @param content string
--- @param max_len? number default 40
--- @return string
function M.truncate_content(content, max_len)
  max_len = max_len or 40
  -- Replace newlines with \n
  local escaped = content:gsub("\n", "\\n")
  if #escaped > max_len then
    return escaped:sub(1, max_len) .. "..."
  end
  return escaped
end

---@class editprompt.HistoryPickerOpts
---@field title string picker title
---@field action fun(content: string) action to execute on selection

--- Show picker with snacks.picker
---@param entries string[]
---@param opts editprompt.HistoryPickerOpts
local function show_snacks_picker(entries, opts)
  local items = {}
  for _, content in ipairs(entries) do
    table.insert(items, {
      text = M.truncate_content(content),
      preview = { text = content, ft = "markdown" },
      content = content,
    })
  end

  require("snacks.picker")({
    title = opts.title,
    items = items,
    format = function(item)
      return { { item.text } }
    end,
    preview = "preview",
    confirm = function(picker, item)
      picker:close()
      if item then
        opts.action(item.content)
      end
    end,
  })
end

--- Show picker with vim.ui.select
---@param entries string[]
---@param opts editprompt.HistoryPickerOpts
local function show_native_picker(entries, opts)
  vim.ui.select(entries, {
    prompt = opts.title,
    format_item = M.truncate_content,
  }, function(content)
    if content then
      opts.action(content)
    end
  end)
end

--- Show picker based on config
---@param entries string[]
---@param opts editprompt.HistoryPickerOpts
local function show_picker(entries, opts)
  local picker_type = config.get_picker()
  if picker_type == "snacks" then
    show_snacks_picker(entries, opts)
  else
    show_native_picker(entries, opts)
  end
end

--- Show a picker of history entries and insert the selected one
function M.list()
  local entries = history.list()
  if #entries == 0 then
    vim.notify("No history entries", vim.log.levels.WARN)
    return
  end

  show_picker(entries, {
    title = "History",
    action = function(content)
      utils.insert_to_buffer(content)
    end,
  })
end

return M
