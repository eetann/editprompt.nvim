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

local function with_stubbed_system(fn, exit_code)
  local original_system = vim.system
  local calls = {}

  vim.system = function(args, opts, callback)
    table.insert(calls, {
      args = vim.deepcopy(args),
      opts = vim.deepcopy(opts),
    })
    callback({ code = exit_code or 0, stdout = "", stderr = "" })
  end

  local ok, err = pcall(fn, calls)
  vim.system = original_system
  if not ok then
    error(err)
  end
end

local function with_stubbed_notify(fn)
  local original_notify = vim.notify
  vim.notify = function() end
  local ok, err = pcall(fn)
  vim.notify = original_notify
  if not ok then
    error(err)
  end
end

--- Let the vim.schedule'd result handlers (and the chained calls they start) run
---@param calls table[]
---@param expected number
local function wait_for_calls(calls, expected)
  vim.wait(200, function()
    return #calls >= expected
  end, 5)
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

T["execute()"]["passes delay to the CLI"] = function()
  config._reset()

  with_mux("tmux", function()
    with_stubbed_system(function(calls)
      press.execute("<CR>", { delay = 100 })

      MiniTest.expect.equality(#calls, 1)
      MiniTest.expect.equality(calls[1].args, {
        "editprompt",
        "press",
        "--delay",
        "100",
        "--",
        "C-m",
      })
    end)
  end)
end

T["execute_sequence()"] = MiniTest.new_set()

T["execute_sequence()"]["sends the next key only after the previous one finished"] = function()
  config._reset()

  with_mux("tmux", function()
    with_stubbed_system(function(calls)
      press.execute_sequence({ "ok", "<CR>" }, { delay = 100 })

      -- The second key must not be launched alongside the first one
      MiniTest.expect.equality(#calls, 1)
      wait_for_calls(calls, 2)

      MiniTest.expect.equality(#calls, 2)
      MiniTest.expect.equality(calls[1].args, {
        "editprompt",
        "press",
        "--",
        "ok",
      })
      -- Only the keys that follow another one need to be separated from it
      MiniTest.expect.equality(calls[2].args, {
        "editprompt",
        "press",
        "--delay",
        "100",
        "--",
        "C-m",
      })
    end)
  end)
end

T["execute_sequence()"]["stops when a key fails"] = function()
  config._reset()

  with_mux("tmux", function()
    with_stubbed_system(function(calls)
      with_stubbed_notify(function()
        press.execute_sequence({ "ok", "<CR>" }, { delay = 100 })

        wait_for_calls(calls, 2)
        MiniTest.expect.equality(#calls, 1)
      end)
    end, 1)
  end)
end

return T
