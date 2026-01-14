local T = MiniTest.new_set()

local stash = require("editprompt.modes.stash")

T["format_date()"] = MiniTest.new_set()

T["format_date()"]["today's date is formatted as HH:MM:SS"] = function()
  -- Generate ISO8601 date for today
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
  -- Use a fixed past date
  local iso_date = "2020-06-15T22:18:30.000Z"

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
  -- 50 characters string
  local content = "12345678901234567890123456789012345678901234567890"

  local result = stash.truncate_content(content)

  -- Should be 40 chars + "..."
  MiniTest.expect.equality(result, "1234567890123456789012345678901234567890...")
  MiniTest.expect.equality(#result, 43) -- 40 + 3 for "..."
end

return T
