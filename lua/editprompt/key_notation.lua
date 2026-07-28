local M = {}

--- Get multiplexer type from environment variable
---@return "tmux"|"wezterm"|"herdr"
function M.get_mux()
  return vim.env.EDITPROMPT_MUX or "tmux"
end

--- tmux special key mapping (Neovim notation -> tmux notation)
---@type table<string, string>
local tmux_keys = {
  ["<CR>"] = "C-m",
  ["<Tab>"] = "Tab",
  ["<S-Tab>"] = "BTab",
  ["<Esc>"] = "Escape",
  ["<BS>"] = "BSpace",
  ["<Space>"] = "Space",
  ["<Up>"] = "Up",
  ["<Down>"] = "Down",
  ["<Left>"] = "Left",
  ["<Right>"] = "Right",
}

--- WezTerm special key mapping (Neovim notation -> WezTerm notation)
---@type table<string, string>
local wezterm_keys = {
  ["<CR>"] = "\r",
  ["<Tab>"] = "\t",
  ["<S-Tab>"] = "\x1b[Z",
  ["<Esc>"] = "\x1b",
  ["<BS>"] = "\x7f",
  ["<Space>"] = " ",
  ["<Up>"] = "\x1b[A",
  ["<Down>"] = "\x1b[B",
  ["<Left>"] = "\x1b[D",
  ["<Right>"] = "\x1b[C",
}

--- Herdr special key mapping (Neovim notation -> Herdr notation)
---@type table<string, string>
local herdr_keys = {
  ["<CR>"] = "enter",
  ["<Tab>"] = "tab",
  ["<S-Tab>"] = "shift+tab",
  ["<Esc>"] = "esc",
  ["<BS>"] = "backspace",
  ["<Space>"] = "space",
  ["<Up>"] = "up",
  ["<Down>"] = "down",
  ["<Left>"] = "left",
  ["<Right>"] = "right",
}

--- Convert Neovim <C-x> notation to tmux C-x notation
---@param nvim_key string
---@return string|nil
local function convert_ctrl_tmux(nvim_key)
  local char = nvim_key:match("^<C%-(%a)>$")
  if char then
    return "C-" .. char:lower()
  end
  return nil
end

--- Convert Neovim <C-x> notation to WezTerm control character
---@param nvim_key string
---@return string|nil
local function convert_ctrl_wezterm(nvim_key)
  local char = nvim_key:match("^<C%-(%a)>$")
  if char then
    local byte = char:upper():byte() - 64
    return string.char(byte)
  end
  return nil
end

--- Convert Neovim <C-x> notation to Herdr ctrl+x notation
---@param nvim_key string
---@return string|nil
local function convert_ctrl_herdr(nvim_key)
  local char = nvim_key:match("^<C%-(%a)>$")
  if char then
    return "ctrl+" .. char:lower()
  end
  return nil
end

--- Convert Neovim key notation to CLI argument string
---@param nvim_key string Neovim key notation (e.g., "<CR>", "<Tab>", "1")
---@return string CLI argument string
function M.convert(nvim_key)
  local mux = M.get_mux()

  if mux == "wezterm" then
    local wezterm_key = wezterm_keys[nvim_key]
    if wezterm_key then
      return wezterm_key
    end
    local ctrl = convert_ctrl_wezterm(nvim_key)
    if ctrl then
      return ctrl
    end
  elseif mux == "herdr" then
    local herdr_key = herdr_keys[nvim_key]
    if herdr_key then
      return herdr_key
    end
    local ctrl = convert_ctrl_herdr(nvim_key)
    if ctrl then
      return ctrl
    end
  else
    local tmux_key = tmux_keys[nvim_key]
    if tmux_key then
      return tmux_key
    end
    local ctrl = convert_ctrl_tmux(nvim_key)
    if ctrl then
      return ctrl
    end
  end

  return nvim_key
end

return M
