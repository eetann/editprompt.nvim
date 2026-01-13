local editprompt = {}

--[=[@doc
  category = "api"
  name = "input"
  desc = """
Send buffer content to clipboard.
Executes `editprompt input --always-copy`.
"""
--]=]
editprompt.input = function()
  require("editprompt.modes.input").execute()
end

--[=[@doc
  category = "api"
  name = "input_auto_send"
  desc = """
Send buffer content to target pane automatically.
Executes `editprompt input --auto-send`.
"""
--]=]
editprompt.input_auto_send = function()
  require("editprompt.modes.input").execute_auto_send()
end

--[=[@doc
  category = "api"
  name = "capture"
  desc = """
Capture quoted content from editprompt CLI.
Executes `editprompt dump`.
"""
--]=]
editprompt.capture = function()
  require("editprompt.modes.capture").execute()
end

--[=[@doc
  category = "api"
  name = "stash_push"
  desc = """
Push buffer content to stash.
Executes `editprompt stash push`.
"""
--]=]
editprompt.stash_push = function()
  require("editprompt.modes.stash").push()
end

--[=[@doc
  category = "api"
  name = "stash_pop"
  desc = """
Pop stash content with picker.
Executes `editprompt stash list` then `editprompt stash pop --key`.
"""
--]=]
editprompt.stash_pop = function()
  require("editprompt.modes.stash").pop()
end

--[=[@doc
  category = "api"
  name = "setup"
  desc = """
```lua
editprompt.setup({...})
```
Setup editprompt
"""

  [[args]]
  name = "config"
  type = "|`editprompt.Config`|"
  desc = "Setup editprompt"
--]=]
editprompt.setup = function(opts)
  require("editprompt.config").setup(opts)
  require("editprompt.command")
end

return editprompt
