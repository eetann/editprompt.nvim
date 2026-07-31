local T = MiniTest.new_set()

local history_list = require("editprompt.modes.history_list")

T["truncate_content()"] = MiniTest.new_set()

T["truncate_content()"]["replaces newlines with \\n"] = function()
  local content = "line1\nline2\nline3"

  local result = history_list.truncate_content(content)

  MiniTest.expect.equality(result, "line1\\nline2\\nline3")
end

T["truncate_content()"]["truncates content over 40 characters"] = function()
  local content = "12345678901234567890123456789012345678901234567890"

  local result = history_list.truncate_content(content)

  MiniTest.expect.equality(
    result,
    "1234567890123456789012345678901234567890..."
  )
  MiniTest.expect.equality(#result, 43)
end

return T
