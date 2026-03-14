---@doc.type
---@alias editprompt.PickerType "native" | "snacks"

---@doc.type
---@class editprompt.PressModeConfig
---@field exit_key string key to exit press mode (default: "q")

---@doc.type
---@class editprompt.Config
---@field cmd string|string[] editprompt CLI command
---@field picker editprompt.PickerType picker to use (auto-detected on setup)
---@field press_mode editprompt.PressModeConfig press mode settings

local M = {}

---@type editprompt.Config
local default_config = {
  cmd = "editprompt",
  picker = "native",
  press_mode = {
    exit_key = "q",
  },
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

--- Get press mode exit key
---@return string
function M.get_press_mode_exit_key()
  return config.press_mode.exit_key
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
