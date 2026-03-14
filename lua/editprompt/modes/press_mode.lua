local config = require("editprompt.config")
local press = require("editprompt.modes.press")

local M = {}

---@private
local state = {
  active = false,
  win_id = nil,
  buf_id = nil,
  prev_win_id = nil,
  exit_pending = false,
  timer = nil,
}

local EXIT_TIMEOUT_MS = 200

--- Keys to map in press mode buffer
---@private
local function get_mappable_keys()
  local keys = {}

  -- Printable ASCII characters
  for i = 32, 126 do
    table.insert(keys, string.char(i))
  end

  -- Special keys
  local special = {
    "<CR>", "<Tab>", "<BS>", "<Space>",
    "<Up>", "<Down>", "<Left>", "<Right>",
    "<Esc>", "<C-c>", "<C-a>", "<C-b>", "<C-d>", "<C-e>",
    "<C-f>", "<C-g>", "<C-h>", "<C-j>", "<C-k>", "<C-l>",
    "<C-n>", "<C-o>", "<C-p>", "<C-r>", "<C-s>", "<C-t>",
    "<C-u>", "<C-v>", "<C-w>", "<C-x>", "<C-y>", "<C-z>",
  }
  vim.list_extend(keys, special)

  return keys
end

--- Create the floating window
---@private
---@return number buf_id, number win_id
local function create_float()
  local exit_key = config.get_press_mode_exit_key()
  local hint = "PRESS MODE | " .. exit_key .. ": exit | " .. exit_key .. exit_key .. ": send " .. exit_key

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { hint })
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  local width = #hint + 2
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = vim.o.lines - 4,
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = 1,
    style = "minimal",
    border = "rounded",
    focusable = true,
  })

  return buf, win
end

--- Handle a key press in press mode
---@private
---@param nvim_key string
local function handle_key(nvim_key)
  local exit_key = config.get_press_mode_exit_key()

  if nvim_key == exit_key then
    if state.exit_pending then
      -- Double press: send the exit key and reset
      state.exit_pending = false
      if state.timer then
        state.timer:stop()
        state.timer:close()
        state.timer = nil
      end
      press.execute(nvim_key)
    else
      -- First press: start exit timeout
      state.exit_pending = true
      state.timer = vim.uv.new_timer()
      state.timer:start(EXIT_TIMEOUT_MS, 0, vim.schedule_wrap(function()
        if state.exit_pending then
          state.exit_pending = false
          if state.timer then
            state.timer:stop()
            state.timer:close()
            state.timer = nil
          end
          M.stop()
        end
      end))
    end
  else
    press.execute(nvim_key)
  end
end

--- Set up buffer-local keymaps for all capturable keys
---@private
local function setup_keymaps(buf)
  local keys = get_mappable_keys()
  local exit_key = config.get_press_mode_exit_key()

  for _, key in ipairs(keys) do
    -- Skip space since it's in both printable and special lists
    -- (printable char(32) == " " and "<Space>" both exist)
    if key ~= " " or key == exit_key then
      vim.keymap.set("n", key, function()
        handle_key(key)
      end, { buffer = buf, nowait = true })
    end
  end

  -- Ensure <Space> is mapped (printable " " may conflict with leader)
  vim.keymap.set("n", "<Space>", function()
    handle_key("<Space>")
  end, { buffer = buf, nowait = true })
end

--- Start press mode
function M.start()
  if state.active then
    return
  end

  state.prev_win_id = vim.api.nvim_get_current_win()
  state.buf_id, state.win_id = create_float()
  state.active = true
  state.exit_pending = false

  setup_keymaps(state.buf_id)
end

--- Stop press mode
function M.stop()
  if not state.active then
    return
  end

  state.active = false
  state.exit_pending = false

  if state.timer then
    state.timer:stop()
    state.timer:close()
    state.timer = nil
  end

  if state.win_id and vim.api.nvim_win_is_valid(state.win_id) then
    vim.api.nvim_win_close(state.win_id, true)
  end
  state.win_id = nil
  state.buf_id = nil

  if state.prev_win_id and vim.api.nvim_win_is_valid(state.prev_win_id) then
    vim.api.nvim_set_current_win(state.prev_win_id)
  end
  state.prev_win_id = nil
end

--- Check if press mode is active (for testing)
---@return boolean
function M.is_active()
  return state.active
end

return M
