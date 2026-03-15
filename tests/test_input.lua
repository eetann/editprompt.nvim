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

local function with_stubbed_system(results, fn)
  local original_system = vim.system
  local calls = {}
  local index = 0

  vim.system = function(args, opts, callback)
    index = index + 1
    table.insert(calls, {
      args = vim.deepcopy(args),
      opts = vim.deepcopy(opts),
    })

    local result = results[index]
      or results.default
      or { code = 0, stdout = "", stderr = "" }
    callback(vim.deepcopy(result))
  end

  local ok, err = pcall(fn, calls)
  vim.system = original_system
  if not ok then
    error(err)
  end
end

T["input_content()"] = MiniTest.new_set({
  hooks = {
    pre_case = function()
      config._reset()
      history._reset()
    end,
  },
})

T["input_content()"]["uses --always-copy by default"] = function()
  with_stubbed_system({}, function(calls)
    editprompt.input_content("sent text")

    vim.wait(100, function()
      return #calls == 1
    end)

    MiniTest.expect.equality(calls[1].args, {
      "editprompt",
      "input",
      "--always-copy",
      "--",
      "sent text",
    })
  end)
end

T["input_content_auto_send()"] = MiniTest.new_set({
  hooks = {
    pre_case = function()
      config._reset()
      history._reset()
    end,
  },
})

T["input_content_auto_send()"]["uses --auto-send"] = function()
  with_stubbed_system({}, function(calls)
    editprompt.input_content_auto_send("sent text")

    MiniTest.expect.equality(calls[1].args, {
      "editprompt",
      "input",
      "--auto-send",
      "--",
      "sent text",
    })
  end)
end

T["input()"] = MiniTest.new_set({
  hooks = {
    pre_case = function()
      config._reset()
      history._reset()
    end,
  },
})

T["input()"]["stores successful sends in history"] = function()
  with_stubbed_system({}, function(calls)
    local bufnr = create_buffer({ "sent text" })

    editprompt.input()

    vim.wait(100, function()
      return #calls == 1
        and vim.deep_equal(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), {})
    end)

    MiniTest.expect.equality(calls[1].args, {
      "editprompt",
      "input",
      "--always-copy",
      "--",
      "sent text",
    })

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "draft" })

    history.prev()
    MiniTest.expect.equality(
      vim.api.nvim_buf_get_lines(bufnr, 0, -1, false),
      { "sent text" }
    )

    history.next()
    MiniTest.expect.equality(
      vim.api.nvim_buf_get_lines(bufnr, 0, -1, false),
      { "draft" }
    )
  end)
end

T["input_visual()"] = MiniTest.new_set({
  hooks = {
    pre_case = function()
      config._reset()
      history._reset()
    end,
  },
})

T["input_visual()"]["sends touched lines and removes them on success"] = function()
  with_stubbed_system({}, function(calls)
    local bufnr = create_buffer({ "alpha", "beta", "gamma" })

    local original_mode = vim.fn.mode
    local original_getpos = vim.fn.getpos

    vim.fn.mode = function()
      return "v"
    end

    vim.fn.getpos = function(mark)
      if mark == "v" then
        return { bufnr, 1, 1, 0 }
      end
      if mark == "." then
        return { bufnr, 2, 4, 0 }
      end
      return original_getpos(mark)
    end

    editprompt.input_visual()

    vim.fn.mode = original_mode
    vim.fn.getpos = original_getpos

    vim.wait(100, function()
      return #calls == 1
        and vim.deep_equal(
          vim.api.nvim_buf_get_lines(bufnr, 0, -1, false),
          { "gamma" }
        )
    end)

    MiniTest.expect.equality(calls[1].args, {
      "editprompt",
      "input",
      "--always-copy",
      "--",
      "alpha\nbeta",
    })
    MiniTest.expect.equality(
      vim.api.nvim_buf_get_lines(bufnr, 0, -1, false),
      { "gamma" }
    )
  end)
end

return T
