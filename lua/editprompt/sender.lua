local config = require("editprompt.config")
local history = require("editprompt.history")
local utils = require("editprompt.utils")

local M = {}

local function notify_error(err_msg)
  vim.notify("editprompt error: " .. err_msg, vim.log.levels.ERROR)
end

local function clear_render_markdown(bufnr)
  local ok, render_ui = pcall(require, "render-markdown.core.ui")
  if ok then
    vim.api.nvim_buf_clear_namespace(bufnr, render_ui.ns, 0, -1)
  end
end

local function normalize_rows(start_pos, end_pos)
  local start_row = start_pos[2] - 1
  local end_row = end_pos[2] - 1

  if start_row > end_row then
    start_row, end_row = end_row, start_row
  end

  return start_row, end_row
end

---@param mode string
---@return boolean
local function is_visual_mode(mode)
  return mode == "v"
    or mode == "V"
    or mode == "\022"
    or mode == "s"
    or mode == "S"
    or mode == "\019"
end

---@return integer[]?, integer[]?
local function get_live_visual_positions()
  if not is_visual_mode(vim.fn.mode()) then
    return nil, nil
  end

  return vim.fn.getpos("v"), vim.fn.getpos(".")
end

---@param start_pos? integer[]
---@param end_pos? integer[]
function M.get_selected_lines(start_pos, end_pos)
  if not start_pos or not end_pos then
    start_pos, end_pos = get_live_visual_positions()
  end

  if not start_pos or not end_pos then
    return nil
  end

  if start_pos[2] == 0 or end_pos[2] == 0 then
    return nil
  end

  local start_row, end_row = normalize_rows(start_pos, end_pos)
  local lines = vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)
  local text = table.concat(lines, "\n")

  return text,
    function()
      vim.api.nvim_buf_set_lines(0, start_row, end_row + 1, false, {})
    end
end

---@param opts table
---@param ctx editprompt.SendContext
---@return fun()[]?
local function prepare_success_cleanup(opts, ctx)
  local cleanups = {}

  if opts.delete_selection then
    local _, delete_selected_lines =
      M.get_selected_lines(opts.start_pos, opts.end_pos)
    if not delete_selected_lines then
      notify_error("No visual selection available")
      return nil
    end
    table.insert(cleanups, delete_selected_lines)
  end

  if opts.clear_buffer then
    table.insert(cleanups, function()
      utils.clear_buffer()
    end)
  end

  if opts.after_success then
    table.insert(cleanups, opts.after_success)
  end

  return cleanups
end

---@param opts? table
---@return editprompt.SendContext
local function build_context(opts)
  opts = opts or {}

  return {
    bufnr = opts.bufnr or vim.api.nvim_get_current_buf(),
    source = opts.source or "content",
    copy = opts.copy ~= false,
    auto_send = opts.auto_send == true,
  }
end

---@param hook_name string
---@param callback function
---@return any?
local function call_hook(hook_name, callback, ...)
  local ok, result = pcall(callback, ...)
  if not ok then
    notify_error(string.format("%s hook failed: %s", hook_name, result))
    return nil
  end
  return result
end

---@param content string
---@param ctx editprompt.SendContext
---@return string?
local function apply_before_input(content, ctx)
  local before_input = config.get().before_input
  if type(before_input) ~= "function" then
    return content
  end

  local transformed = call_hook("before_input", before_input, content, ctx)
  if transformed == nil then
    return nil
  end

  if type(transformed) ~= "string" then
    notify_error("before_input hook must return a string")
    return nil
  end

  return transformed
end

---@param content string
---@param opts table
---@param ctx editprompt.SendContext
---@return boolean?
local function resolve_copy(content, opts, ctx)
  if opts.copy ~= nil then
    ctx.copy = opts.copy
    return opts.copy
  end

  local should_copy = config.get().should_copy
  if type(should_copy) == "function" then
    local result = call_hook("should_copy", should_copy, content, ctx)
    if result == nil then
      return nil
    end
    ctx.copy = result == true
    return ctx.copy
  end

  ctx.copy = true
  return true
end

---@param content string
---@param ctx editprompt.SendContext
---@return string[]?
local function build_args(content, ctx)
  if ctx.copy and ctx.auto_send then
    notify_error("copy and auto_send cannot both be true")
    return nil
  end

  local args = vim.deepcopy(config.get_cmd())
  vim.list_extend(args, { "input" })

  if ctx.auto_send then
    table.insert(args, "--auto-send")
  elseif ctx.copy then
    table.insert(args, "--always-copy")
  end

  vim.list_extend(args, { "--", content })
  return args
end

---@param original_content string
---@param opts? table
function M.send(original_content, opts)
  opts = opts or {}
  if type(original_content) ~= "string" or original_content == "" then
    return
  end

  local ctx = build_context(opts)
  local content = apply_before_input(original_content, ctx)
  if type(content) ~= "string" or content == "" or content:match("^%s*$") then
    return
  end

  local copy = resolve_copy(content, opts, ctx)
  if copy == nil then
    return
  end

  local success_cleanups = prepare_success_cleanup(opts, ctx)
  if success_cleanups == nil then
    return
  end

  local args = build_args(content, ctx)
  if not args then
    return
  end

  vim.system(args, { text = true }, function(result)
    vim.schedule(function()
      if result.code == 0 then
        for _, cleanup in ipairs(success_cleanups) do
          cleanup()
        end

        clear_render_markdown(ctx.bufnr)

        history.push(original_content)

        local on_success = config.get().on_success
        if type(on_success) == "function" then
          call_hook("on_success", on_success, original_content, ctx.bufnr, ctx)
        end
      else
        local on_error = config.get().on_error
        if type(on_error) == "function" then
          call_hook(
            "on_error",
            on_error,
            original_content,
            ctx.bufnr,
            result,
            ctx
          )
          return
        end

        notify_error(result.stderr or "Unknown error")
      end
    end)
  end)
end

return M
