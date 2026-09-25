local config = require("editprompt.config")
local key_notation = require("editprompt.key_notation")

local M = {}

---@class editprompt.PressOpts
---@field delay? number Milliseconds the CLI waits before delivering the key
---@field on_done? fun() Called after the key has reached the target pane

--- Send a key to the target pane via editprompt CLI
---@param key string Neovim key notation (e.g., "<CR>", "<Tab>", "1")
---@param opts? editprompt.PressOpts
function M.execute(key, opts)
  if not key or key == "" then
    return
  end

  opts = opts or {}
  local converted = key_notation.convert(key)

  local args = vim.deepcopy(config.get_cmd())
  table.insert(args, "press")
  if opts.delay then
    vim.list_extend(args, { "--delay", tostring(opts.delay) })
  end
  vim.list_extend(args, { "--", converted })

  vim.system(args, { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        local err_msg = result.stderr or "Unknown error"
        vim.notify("editprompt error: " .. err_msg, vim.log.levels.ERROR)
        return
      end
      if opts.on_done then
        opts.on_done()
      end
    end)
  end)
end

---@class editprompt.PressSequenceOpts
---@field delay? number Milliseconds to separate each key from the previous one

--- Send keys in order, starting each key only after the previous one arrived.
---
--- Firing them as independent `press` calls cannot hold the order: every call
--- spawns its own process chain (the CLI plus one multiplexer command per step),
--- so a key launched later can overtake an earlier one and reach the pane first.
--- The delay matters on top of the order: TUIs such as codex read text and a
--- following Enter that arrive in one read as a pasted newline instead of a
--- submit, leaving the text sitting in the prompt unsent.
---@param keys string[] Keys to send in Neovim notation
---@param opts? editprompt.PressSequenceOpts
function M.execute_sequence(keys, opts)
  opts = opts or {}

  local function send(index)
    local key = keys[index]
    if key == nil then
      return
    end
    M.execute(key, {
      -- The first key has nothing to be separated from
      delay = index > 1 and opts.delay or nil,
      on_done = function()
        send(index + 1)
      end,
    })
  end

  send(1)
end

return M
