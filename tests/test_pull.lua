local T = MiniTest.new_set()

local editprompt = require("editprompt")
local config = require("editprompt.config")
local history = require("editprompt.history")

local function create_buffer(lines)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines or {})
  vim.api.nvim_set_current_buf(bufnr)
  return bufnr
end

--- Stub vim.system and vim.notify while running fn
---@param results vim.SystemCompleted[] results returned in call order
---@param fn fun(calls: table[], notifications: table[])
local function with_stubs(results, fn)
  local original_system = vim.system
  local original_notify = vim.notify
  local calls = {}
  local notifications = {}

  vim.system = function(args, opts, callback)
    table.insert(calls, { args = vim.deepcopy(args), opts = vim.deepcopy(opts) })
    local result = results[#calls] or { code = 0, stdout = "", stderr = "" }
    callback(vim.deepcopy(result))
  end
  vim.notify = function(msg, level)
    table.insert(notifications, { msg = msg, level = level })
  end

  local ok, err = pcall(fn, calls, notifications)
  vim.system = original_system
  vim.notify = original_notify
  if not ok then
    error(err)
  end
end

--- Wait for the scheduled callbacks of vim.system to run
local function flush()
  vim.wait(100, function()
    return false
  end)
end

local function reset()
  config._reset()
  history._reset()
end

T["pull()"] = MiniTest.new_set({ hooks = { pre_case = reset } })

T["pull()"]["executes `pull`"] = function()
  with_stubs({ { code = 0, stdout = "draft", stderr = "" } }, function(calls)
    create_buffer({})

    editprompt.pull()
    flush()

    MiniTest.expect.equality(#calls, 1)
    MiniTest.expect.equality(calls[1].args, { "editprompt", "pull" })
  end)
end

T["pull()"]["passes --keep"] = function()
  with_stubs({ { code = 0, stdout = "draft", stderr = "" } }, function(calls)
    create_buffer({})

    editprompt.pull({ keep = true })
    flush()

    MiniTest.expect.equality(calls[1].args, { "editprompt", "pull", "--keep" })
  end)
end

T["pull()"]["inserts the pulled text into an empty buffer"] = function()
  with_stubs({
    { code = 0, stdout = "first pane\nsecond pane", stderr = "" },
  }, function(_, notifications)
    local bufnr = create_buffer({})

    editprompt.pull()
    flush()

    MiniTest.expect.equality(
      vim.api.nvim_buf_get_lines(bufnr, 0, -1, false),
      { "first pane", "second pane" }
    )
    MiniTest.expect.equality(#notifications, 0)
  end)
end

T["pull()"]["appends after a blank line and moves the cursor to the end"] = function()
  with_stubs({ { code = 0, stdout = "next prompt\n", stderr = "" } }, function()
    local bufnr = create_buffer({ "draft", "second line" })
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    editprompt.pull()
    flush()

    MiniTest.expect.equality(
      vim.api.nvim_buf_get_lines(bufnr, 0, -1, false),
      { "draft", "second line", "", "next prompt" }
    )
    -- Normal mode clamps the column to the last character
    MiniTest.expect.equality(vim.api.nvim_win_get_cursor(0), { 4, 10 })
  end)
end

T["pull()"]["warns and keeps the buffer when there is nothing to pull"] = function()
  with_stubs({ { code = 0, stdout = "", stderr = "" } }, function(_, notifications)
    local bufnr = create_buffer({ "draft" })

    editprompt.pull()
    flush()

    MiniTest.expect.equality(
      vim.api.nvim_buf_get_lines(bufnr, 0, -1, false),
      { "draft" }
    )
    MiniTest.expect.equality(notifications, {
      { msg = "Nothing to pull", level = vim.log.levels.WARN },
    })
  end)
end

T["pull()"]["notifies an error when the CLI fails"] = function()
  with_stubs({ { code = 1, stdout = "", stderr = "boom" } }, function(_, notifications)
    local bufnr = create_buffer({})

    editprompt.pull()
    flush()

    MiniTest.expect.equality(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), { "" })
    MiniTest.expect.equality(notifications, {
      { msg = "editprompt error: boom", level = vim.log.levels.ERROR },
    })
  end)
end

T["pull_auto_send()"] = MiniTest.new_set({ hooks = { pre_case = reset } })

T["pull_auto_send()"]["sends the pulled text and records it in history"] = function()
  with_stubs({
    { code = 0, stdout = "next prompt", stderr = "" },
    { code = 0, stdout = "", stderr = "" },
  }, function(calls)
    local bufnr = create_buffer({})

    editprompt.pull_auto_send()
    flush()

    MiniTest.expect.equality(#calls, 2)
    MiniTest.expect.equality(calls[1].args, { "editprompt", "pull" })
    MiniTest.expect.equality(calls[2].args, {
      "editprompt",
      "input",
      "--auto-send",
      "--",
      "next prompt",
    })
    MiniTest.expect.equality(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), { "" })
    MiniTest.expect.equality(history.list(), { "next prompt" })
  end)
end

T["pull_auto_send()"]["sends the buffer content together with the pulled text"] = function()
  with_stubs({
    { code = 0, stdout = "next prompt", stderr = "" },
    { code = 0, stdout = "", stderr = "" },
  }, function(calls)
    create_buffer({ "draft" })

    editprompt.pull_auto_send()
    flush()

    MiniTest.expect.equality(calls[2].args[#calls[2].args], "draft\n\nnext prompt")
  end)
end

T["pull_auto_send()"]["sends nothing when there is nothing to pull"] = function()
  with_stubs({ { code = 0, stdout = "", stderr = "" } }, function(calls)
    local bufnr = create_buffer({ "draft" })

    editprompt.pull_auto_send()
    flush()

    MiniTest.expect.equality(#calls, 1)
    MiniTest.expect.equality(
      vim.api.nvim_buf_get_lines(bufnr, 0, -1, false),
      { "draft" }
    )
  end)
end

T[":Editprompt pull"] = MiniTest.new_set({ hooks = { pre_case = reset } })

T[":Editprompt pull"]["inserts the pulled text via the command"] = function()
  with_stubs({ { code = 0, stdout = "next prompt", stderr = "" } }, function(calls)
    editprompt.setup()
    local bufnr = create_buffer({})

    vim.cmd("Editprompt pull")
    flush()

    MiniTest.expect.equality(calls[1].args, { "editprompt", "pull" })
    MiniTest.expect.equality(
      vim.api.nvim_buf_get_lines(bufnr, 0, -1, false),
      { "next prompt" }
    )
  end)
end

T[":Editprompt pull"]["passes --keep"] = function()
  with_stubs({ { code = 0, stdout = "next prompt", stderr = "" } }, function(calls)
    editprompt.setup()
    create_buffer({})

    vim.cmd("Editprompt pull --keep")
    flush()

    MiniTest.expect.equality(calls[1].args, { "editprompt", "pull", "--keep" })
  end)
end

T[":Editprompt pull"]["sends right away with --auto-send"] = function()
  with_stubs({
    { code = 0, stdout = "next prompt", stderr = "" },
    { code = 0, stdout = "", stderr = "" },
  }, function(calls)
    editprompt.setup()
    create_buffer({})

    vim.cmd("Editprompt pull --auto-send")
    flush()

    MiniTest.expect.equality(#calls, 2)
    MiniTest.expect.equality(calls[2].args[3], "--auto-send")
  end)
end

T[":Editprompt pull"]["rejects --keep with --auto-send"] = function()
  with_stubs({}, function(calls, notifications)
    editprompt.setup()
    create_buffer({})

    vim.cmd("Editprompt pull --keep --auto-send")
    flush()

    MiniTest.expect.equality(#calls, 0)
    MiniTest.expect.equality(notifications, {
      {
        msg = "Editprompt: --keep cannot be used with --auto-send",
        level = vim.log.levels.ERROR,
      },
    })
  end)
end

return T
