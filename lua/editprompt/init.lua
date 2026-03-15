local editprompt = {}

--[=[@doc
  category = "api"
  name = "input_content"
  desc = """
Send provided content to clipboard.
Executes `editprompt input --always-copy` with the given content.
"""

  [[args]]
  name = "content"
  type = "string"
  desc = "Content to send"
--]=]
editprompt.input_content = function(content)
  require("editprompt.modes.input").execute_content(content)
end

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
  name = "input_content_auto_send"
  desc = """
Send provided content to target pane automatically.
Executes `editprompt input --auto-send` with the given content.
"""

  [[args]]
  name = "content"
  type = "string"
  desc = "Content to send"
--]=]
editprompt.input_content_auto_send = function(content)
  require("editprompt.modes.input").execute_content_auto_send(content)
end

--[=[@doc
  category = "api"
  name = "input_visual"
  desc = """
Send lines touched by the visual selection to clipboard.
Executes `editprompt input --always-copy` with the selected lines.
"""
--]=]
editprompt.input_visual = function()
  require("editprompt.modes.input").execute_visual()
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
  name = "input_visual_auto_send"
  desc = """
Send lines touched by the visual selection to target pane automatically.
Executes `editprompt input --auto-send` with the selected lines.
"""
--]=]
editprompt.input_visual_auto_send = function()
  require("editprompt.modes.input").execute_visual_auto_send()
end

--[=[@doc
  category = "api"
  name = "press"
  desc = """
Send a key to the target pane without Enter.
Executes `editprompt press -- {key}`.
Key notation is automatically converted from Neovim format to the multiplexer format.
"""

  [[args]]
  name = "key"
  type = "string"
  desc = "Key to send in Neovim notation (e.g., '1', '<CR>', '<Tab>', '<C-c>')"
--]=]
editprompt.press = function(key)
  require("editprompt.modes.press").execute(key)
end

--[=[@doc
  category = "api"
  name = "press_mode"
  desc = """
Enter press mode for continuous key sending.
All key inputs are forwarded to the target pane.
Press the exit key (default: `q`) to leave press mode.
Double-press the exit key to send it instead.
"""
--]=]
editprompt.press_mode = function()
  require("editprompt.modes.press_mode").start()
end

--[=[@doc
  category = "api"
  name = "press_mode_stop"
  desc = """
Exit press mode.
"""
--]=]
editprompt.press_mode_stop = function()
  require("editprompt.modes.press_mode").stop()
end

--[=[@doc
  category = "api"
  name = "dump"
  desc = """
Dump quoted content from editprompt CLI.
Executes `editprompt dump`.
"""
--]=]
editprompt.dump = function()
  require("editprompt.modes.dump").execute()
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
  name = "stash_pop_latest"
  desc = """
Pop the latest stash content without showing picker.
Executes `editprompt stash list` then `editprompt stash pop --key` for the newest entry.
"""
--]=]
editprompt.stash_pop_latest = function()
  require("editprompt.modes.stash").pop_latest()
end

--[=[@doc
  category = "api"
  name = "history_prev"
  desc = """
Replace current buffer content with the previous sent prompt.
"""
--]=]
editprompt.history_prev = function()
  require("editprompt.history").prev()
end

--[=[@doc
  category = "api"
  name = "history_next"
  desc = """
Replace current buffer content with the next prompt in history.
"""
--]=]
editprompt.history_next = function()
  require("editprompt.history").next()
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
