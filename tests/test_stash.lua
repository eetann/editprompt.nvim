local T = MiniTest.new_set()

local editprompt = require("editprompt")
local stash = require("editprompt.modes.stash")

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

T["format_date()"] = MiniTest.new_set()

T["format_date()"]["today's date is formatted as HH:MM:SS"] = function()
  local today = os.date("*t")
  local iso_date = string.format(
    "%04d-%02d-%02dT14:30:00.000Z",
    today.year,
    today.month,
    today.day
  )

  local result = stash.format_date(iso_date)

  MiniTest.expect.equality(result, "14:30:00")
end

T["format_date()"]["other dates are formatted as YYYY-MM-DD HH:MM:SS"] = function()
  local iso_date = "2020-06-15T22:18:30.123Z"

  local result = stash.format_date(iso_date)

  MiniTest.expect.equality(result, "2020-06-15 22:18:30")
end

T["truncate_content()"] = MiniTest.new_set()

T["truncate_content()"]["replaces newlines with \\n"] = function()
  local content = "line1\nline2\nline3"

  local result = stash.truncate_content(content)

  MiniTest.expect.equality(result, "line1\\nline2\\nline3")
end

T["truncate_content()"]["truncates content over 40 characters"] = function()
  local content = "12345678901234567890123456789012345678901234567890"

  local result = stash.truncate_content(content)

  MiniTest.expect.equality(
    result,
    "1234567890123456789012345678901234567890..."
  )
  MiniTest.expect.equality(#result, 43)
end

T["stash_pop_latest()"] = MiniTest.new_set()

T["stash_pop_latest()"]["pops the newest stash entry into the current buffer"] = function()
  with_stubbed_system({
    {
      code = 0,
      stdout = vim.json.encode({
        { key = "2026-01-01T00:00:00.000Z", content = "older" },
        { key = "2026-01-02T00:00:00.000Z", content = "newer" },
      }),
      stderr = "",
    },
    {
      code = 0,
      stdout = "restored text\n",
      stderr = "",
    },
  }, function(calls)
    local bufnr = create_buffer({})

    editprompt.stash_pop_latest()

    vim.wait(100, function()
      return #calls == 2
        and vim.deep_equal(
          vim.api.nvim_buf_get_lines(bufnr, 0, -1, false),
          { "restored text" }
        )
    end)

    MiniTest.expect.equality(calls[1].args, {
      "editprompt",
      "stash",
      "list",
    })
    MiniTest.expect.equality(calls[2].args, {
      "editprompt",
      "stash",
      "pop",
      "--key",
      "2026-01-02T00:00:00.000Z",
    })
  end)
end

return T
