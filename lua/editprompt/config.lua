---@doc.type
---@alias editprompt.PickerType "native" | "snacks"

---@doc.type
---@class editprompt.SendContext
---@field bufnr integer
---@field source "content" | "buffer" | "visual"
---@field copy boolean
---@field auto_send boolean

---@doc.type
---@class editprompt.Config
---@field cmd string|string[] editprompt CLI command
---@field picker editprompt.PickerType picker to use (auto-detected on setup)
---@field before_input? fun(content: string, ctx: editprompt.SendContext): string
---@field should_copy? fun(content: string, ctx: editprompt.SendContext): boolean
---@field on_success? fun(content: string, bufnr: integer, ctx: editprompt.SendContext)
---@field on_error? fun(content: string, bufnr: integer, result: vim.SystemCompleted, ctx: editprompt.SendContext)

local M = {}

---@type editprompt.Config
local default_config = {
  cmd = "editprompt",
  picker = "native",
}

---@type editprompt.Config
local config = vim.deepcopy(default_config)

--- Setup configuration
---@param opts? editprompt.Config
function M.setup(opts)
  config = vim.tbl_deep_extend("force", default_config, opts or {})
end

--- Get command as string array
---@return string[]
function M.get_cmd()
  if type(config.cmd) == "string" then
    return { config.cmd }
  end
  return config.cmd
end

--- Get picker type
---@return editprompt.PickerType
function M.get_picker()
  return config.picker
end

--- Get raw config
---@return editprompt.Config
function M.get()
  return config
end

--- Reset configuration to default (for testing)
function M._reset()
  config = vim.deepcopy(default_config)
end

--- Format default config for documentation
---@return string
function M._format_default()
  local lines = { "```lua" }
  for line in vim.gsplit(vim.inspect(default_config), "\n") do
    table.insert(lines, line)
  end
  table.insert(lines, "```")
  return table.concat(lines, "\n")
end

return M
