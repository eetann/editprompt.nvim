local T = MiniTest.new_set()

local config = require("editprompt.config")
local editprompt = require("editprompt")
local press = require("editprompt.modes.press")

local function with_mux(mux, fn)
  local original = vim.env.EDITPROMPT_MUX
  vim.env.EDITPROMPT_MUX = mux
  local ok, err = pcall(fn)
  vim.env.EDITPROMPT_MUX = original
  if not ok then
    error(err)
  end
end

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

T["execute()"] = MiniTest.new_set()

T["execute()"]["tmux: sends plain character as-is"] = function()
  config._reset()

  with_mux("tmux", function()
    with_stubbed_system(function(calls)
      press.execute("1")

      MiniTest.expect.equality(#calls, 1)
      MiniTest.expect.equality(calls[1].args, {
        "editprompt",
        "press",
        "--",
        "1",
      })
    end)
  end)
end

T["execute()"]["tmux: converts <CR> to C-m"] = function()
  config._reset()

  with_mux("tmux", function()
    with_stubbed_system(function(calls)
      press.execute("<CR>")

      MiniTest.expect.equality(#calls, 1)
      MiniTest.expect.equality(calls[1].args, {
        "editprompt",
        "press",
        "--",
        "C-m",
      })
    end)
  end)
end

T["execute()"]["wezterm: converts <CR> to \\r"] = function()
  config._reset()

  with_mux("wezterm", function()
    with_stubbed_system(function(calls)
      press.execute("<CR>")

      MiniTest.expect.equality(#calls, 1)
      MiniTest.expect.equality(calls[1].args, {
        "editprompt",
        "press",
        "--",
        "\r",
      })
    end)
  end)
end

T["execute()"]["herdr: press(<CR>) sends enter"] = function()
  config._reset()

  with_mux("herdr", function()
    with_stubbed_system(function(calls)
      editprompt.press("<CR>")

      MiniTest.expect.equality(#calls, 1)
      MiniTest.expect.equality(calls[1].args, {
        "editprompt",
        "press",
        "--",
        "enter",
      })
    end)
  end)
end

T["execute()"]["herdr: press(<S-Tab>) sends shift+tab"] = function()
  config._reset()

  with_mux("herdr", function()
    with_stubbed_system(function(calls)
      editprompt.press("<S-Tab>")

      MiniTest.expect.equality(#calls, 1)
      MiniTest.expect.equality(calls[1].args, {
        "editprompt",
        "press",
        "--",
        "shift+tab",
      })
    end)
  end)
end

return T
