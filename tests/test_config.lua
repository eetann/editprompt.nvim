local T = MiniTest.new_set()

local config = require("editprompt.config")

T["setup()"] = MiniTest.new_set()

T["setup()"]["default values are set correctly"] = function()
  config._reset()
  config.setup()

  MiniTest.expect.equality(config.get_cmd(), { "editprompt" })
  MiniTest.expect.equality(config.get_picker(), "native")
end

T["setup()"]["user settings are merged"] = function()
  config._reset()
  config.setup({ cmd = "custom-cmd", picker = "snacks" })

  MiniTest.expect.equality(config.get_cmd(), { "custom-cmd" })
  MiniTest.expect.equality(config.get_picker(), "snacks")
end

T["get_cmd()"] = MiniTest.new_set()

T["get_cmd()"]["converts string to table"] = function()
  config._reset()
  config.setup({ cmd = "my-editprompt" })

  MiniTest.expect.equality(config.get_cmd(), { "my-editprompt" })
end

T["get_cmd()"]["returns table as-is"] = function()
  config._reset()
  config.setup({ cmd = { "npx", "editprompt" } })

  MiniTest.expect.equality(config.get_cmd(), { "npx", "editprompt" })
end

return T
