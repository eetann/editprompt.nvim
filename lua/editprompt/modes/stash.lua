local config = require("editprompt.config")

local M = {}

--- Get buffer content as string
---@return string
local function get_buffer_content()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  return table.concat(lines, "\n")
end

--- Check if content is whitespace only
---@param content string
---@return boolean
local function is_whitespace_only(content)
  return content:match("^%s*$") ~= nil
end

--- Clear buffer and save
local function clear_buffer()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
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
    vim.api.nvim_buf_set_lines(0, 0, -1, false, new_lines)
  else
    local line_count = vim.api.nvim_buf_line_count(0)
    local lines_to_add = { "" }
    vim.list_extend(lines_to_add, new_lines)
    vim.api.nvim_buf_set_lines(0, line_count, line_count, false, lines_to_add)
  end
end

--- Format ISO8601 date for display
--- @param iso_date string ISO8601 date string (e.g., "2026-01-12T00:38:58.031Z")
--- @return string formatted date
function M.format_date(iso_date)
  -- Parse ISO8601 date
  local year, month, day, hour, min =
    iso_date:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+)")
  if not year then
    return iso_date
  end

  -- Get today's date
  local today = os.date("*t")
  local is_today = tonumber(year) == today.year
    and tonumber(month) == today.month
    and tonumber(day) == today.day

  if is_today then
    return string.format("%s:%s", hour, min)
  else
    return string.format("%s-%s-%s %s:%s", year, month, day, hour, min)
  end
end

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

--- Format stash item for display
---@param stash {key: string, content: string}
---@return string
local function format_stash_item(stash)
  local date_str = M.format_date(stash.key)
  local content_str = M.truncate_content(stash.content)
  return date_str .. " " .. content_str
end

--- Execute stash pop with selected key
---@param key string
local function execute_pop(key)
  local cmd = config.get_cmd()
  local args = vim.list_extend(cmd, { "stash", "pop", "--key", key })

  vim.system(args, {}, function(result)
    vim.schedule(function()
      if result.code == 0 then
        local output = result.stdout or ""
        output = output:gsub("\n$", "")
        insert_to_buffer(output)
        vim.notify("Stash popped", vim.log.levels.INFO)
      else
        local err_msg = result.stderr or "Unknown error"
        vim.notify("editprompt error: " .. err_msg, vim.log.levels.ERROR)
      end
    end)
  end)
end

--- Show picker with snacks.picker
---@param stashes table[]
local function show_snacks_picker(stashes)
  local items = {}
  for _, stash in ipairs(stashes) do
    table.insert(items, {
      text = format_stash_item(stash),
      stash = stash,
    })
  end

  require("snacks.picker")({
    items = items,
    format = function(item)
      return { { item.text } }
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        execute_pop(item.stash.key)
      end
    end,
  })
end

--- Show picker with vim.ui.select
---@param stashes table[]
local function show_native_picker(stashes)
  vim.ui.select(stashes, {
    prompt = "Select Stash",
    format_item = function(stash)
      return format_stash_item(stash)
    end,
  }, function(stash)
    if stash then
      execute_pop(stash.key)
    end
  end)
end

--- Push current buffer content to stash
function M.push()
  local content = get_buffer_content()

  if is_whitespace_only(content) then
    vim.notify("Buffer is empty", vim.log.levels.WARN)
    return
  end

  local cmd = config.get_cmd()
  local args = vim.list_extend(cmd, { "stash", "push", "--", content })

  vim.system(args, {}, function(result)
    vim.schedule(function()
      if result.code == 0 then
        clear_buffer()
        vim.notify("Stash pushed", vim.log.levels.INFO)
      else
        local err_msg = result.stderr or "Unknown error"
        vim.notify("editprompt error: " .. err_msg, vim.log.levels.ERROR)
      end
    end)
  end)
end

--- Pop stash with picker
function M.pop()
  local cmd = config.get_cmd()
  local args = vim.list_extend(cmd, { "stash", "list" })

  vim.system(args, {}, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        local err_msg = result.stderr or "Unknown error"
        vim.notify("editprompt error: " .. err_msg, vim.log.levels.ERROR)
        return
      end

      local ok, stashes = pcall(vim.json.decode, result.stdout or "[]")
      if not ok then
        vim.notify("Failed to parse stash list", vim.log.levels.ERROR)
        return
      end

      if #stashes == 0 then
        vim.notify("No stash entries", vim.log.levels.WARN)
        return
      end

      local picker_type = config.get_picker()
      if picker_type == "snacks" then
        show_snacks_picker(stashes)
      else
        show_native_picker(stashes)
      end
    end)
  end)
end

return M
