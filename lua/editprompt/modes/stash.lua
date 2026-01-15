local config = require("editprompt.config")
local utils = require("editprompt.utils")

local M = {}

--- Check if content is whitespace only
---@param content string
---@return boolean
local function is_whitespace_only(content)
  return content:match("^%s*$") ~= nil
end

--- Format ISO8601 date for display
--- @param iso_date string ISO8601 date string (e.g., "2026-01-12T00:38:58.031Z")
--- @return string formatted date
function M.format_date(iso_date)
  -- Parse ISO8601 date
  local year, month, day, hour, min, sec =
    iso_date:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")
  if not year then
    return iso_date
  end

  -- Get today's date
  local today = os.date("*t")
  local is_today = tonumber(year) == today.year
    and tonumber(month) == today.month
    and tonumber(day) == today.day

  if is_today then
    return string.format("%s:%s:%s", hour, min, sec)
  else
    return string.format("%s-%s-%s %s:%s:%s", year, month, day, hour, min, sec)
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

--- Fetch stash list from CLI
---@param callback fun(stashes: table[]|nil, err: string|nil)
local function fetch_stash_list(callback)
  local args = vim.deepcopy(config.get_cmd())
  vim.list_extend(args, { "stash", "list" })

  vim.system(args, { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        local err_msg = result.stderr or "Unknown error"
        callback(nil, err_msg)
        return
      end

      local ok, stashes = pcall(vim.json.decode, result.stdout or "[]")
      if not ok then
        callback(nil, "Failed to parse stash list")
        return
      end

      if #stashes == 0 then
        callback(nil, "No stash entries")
        return
      end

      callback(stashes, nil)
    end)
  end)
end

--- Execute stash pop with selected key
---@param key string
local function execute_pop(key)
  local args = vim.deepcopy(config.get_cmd())
  vim.list_extend(args, { "stash", "pop", "--key", key })

  vim.system(args, { text = true }, function(result)
    vim.schedule(function()
      if result.code == 0 then
        local output = result.stdout or ""
        output = output:gsub("\n$", "")
        utils.insert_to_buffer(output)
        vim.notify("Stash popped", vim.log.levels.INFO)
      else
        local err_msg = result.stderr or "Unknown error"
        vim.notify("editprompt error: " .. err_msg, vim.log.levels.ERROR)
      end
    end)
  end)
end

--- Execute stash drop with selected key
---@param key string
---@param on_success? fun() callback after successful drop
local function execute_drop(key, on_success)
  local args = vim.deepcopy(config.get_cmd())
  vim.list_extend(args, { "stash", "drop", "--key", key })

  vim.system(args, { text = true }, function(result)
    vim.schedule(function()
      if result.code == 0 then
        vim.notify("Stash dropped", vim.log.levels.INFO)
        if on_success then
          on_success()
        end
      else
        local err_msg = result.stderr or "Unknown error"
        vim.notify("editprompt error: " .. err_msg, vim.log.levels.ERROR)
      end
    end)
  end)
end

---@class editprompt.StashPickerOpts
---@field title string picker title
---@field action fun(key: string) action to execute on selection

--- Show picker with snacks.picker
---@param stashes table[]
---@param opts editprompt.StashPickerOpts
local function show_snacks_picker(stashes, opts)
  local items = {}
  for _, stash in ipairs(stashes) do
    table.insert(items, {
      text = format_stash_item(stash),
      preview = { text = stash.content, ft = "markdown" },
      stash = stash,
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
        opts.action(item.stash.key)
      end
    end,
    win = {
      input = {
        keys = {
          ["dd"] = { "drop_stash", mode = { "n" } },
        },
      },
    },
    actions = {
      drop_stash = function(the_picker)
        the_picker.preview:reset()
        for _, item in ipairs(the_picker:selected({ fallback = true })) do
          local stash = item.stash
          if stash then
            execute_drop(stash.key, function()
              the_picker.list:set_selected()
              the_picker.list:set_target()
              the_picker:find()
            end)
          end
        end
      end,
    },
  })
end

--- Show picker with vim.ui.select
---@param stashes table[]
---@param opts editprompt.StashPickerOpts
local function show_native_picker(stashes, opts)
  vim.ui.select(stashes, {
    prompt = opts.title,
    format_item = function(stash)
      return format_stash_item(stash)
    end,
  }, function(stash)
    if stash then
      opts.action(stash.key)
    end
  end)
end

--- Push current buffer content to stash
function M.push()
  local content = utils.get_buffer_content()

  if is_whitespace_only(content) then
    vim.notify("Buffer is empty", vim.log.levels.WARN)
    return
  end

  local args = vim.deepcopy(config.get_cmd())
  vim.list_extend(args, { "stash", "push", "--", content })

  vim.system(args, { text = true }, function(result)
    vim.schedule(function()
      if result.code == 0 then
        utils.clear_buffer()
        vim.notify("Stash pushed", vim.log.levels.INFO)
      else
        local err_msg = result.stderr or "Unknown error"
        vim.notify("editprompt error: " .. err_msg, vim.log.levels.ERROR)
      end
    end)
  end)
end

--- Show picker based on config
---@param stashes table[]
---@param opts editprompt.StashPickerOpts
local function show_picker(stashes, opts)
  local picker_type = config.get_picker()
  if picker_type == "snacks" then
    show_snacks_picker(stashes, opts)
  else
    show_native_picker(stashes, opts)
  end
end

--- Pop stash with picker
function M.pop()
  fetch_stash_list(function(stashes, err)
    if err then
      local level = err == "No stash entries" and vim.log.levels.WARN
        or vim.log.levels.ERROR
      local msg = err == "No stash entries" and err or ("editprompt error: " .. err)
      vim.notify(msg, level)
      return
    end
    show_picker(stashes, {
      title = "Pop Stash",
      action = execute_pop,
    })
  end)
end

--- Drop stash with picker
function M.drop()
  fetch_stash_list(function(stashes, err)
    if err then
      local level = err == "No stash entries" and vim.log.levels.WARN
        or vim.log.levels.ERROR
      local msg = err == "No stash entries" and err or ("editprompt error: " .. err)
      vim.notify(msg, level)
      return
    end
    show_picker(stashes, {
      title = "Drop Stash",
      action = function(key)
        execute_drop(key)
      end,
    })
  end)
end

return M
