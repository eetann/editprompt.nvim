local T = MiniTest.new_set()

local config = require("editprompt.config")
local press_mode = require("editprompt.modes.press_mode")

local function with_stubbed_system(fn)
  local original_system = vim.system
  local calls = {}

  vim.system = function(args, opts, callback)
    table.insert(calls, {
      args = vim.deepcopy(args),
      opts = vim.deepcopy(opts),
    })
    callback({ code = 0, stdout = "", stderr = "" })
  end

  local ok, err = pcall(fn, calls)
  vim.system = original_system
  if not ok then
    error(err)
  end
end

T["start()"] = MiniTest.new_set()

T["start()"]["creates a floating window"] = function()
  config._reset()

  with_stubbed_system(function()
    press_mode.start()

    MiniTest.expect.equality(press_mode.is_active(), true)

    -- Clean up
    press_mode.stop()
  end)
end

T["stop()"] = MiniTest.new_set()

T["stop()"]["closes the floating window"] = function()
  config._reset()

  with_stubbed_system(function()
    press_mode.start()
    press_mode.stop()

    MiniTest.expect.equality(press_mode.is_active(), false)
  end)
end

T["stop()"]["restores focus to the previous window"] = function()
  config._reset()

  with_stubbed_system(function()
    local original_win = vim.api.nvim_get_current_win()

    press_mode.start()
    press_mode.stop()

    MiniTest.expect.equality(vim.api.nvim_get_current_win(), original_win)
  end)
end

return T
