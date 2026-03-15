local CommandRegister = require("editprompt.command_register")

---@class Editprompt.Subcommand
---@field impl fun(args:string[], opts: table) The command implementation
---@field complete? fun(subcmd_arg_lead: string): string[] (optional) Command completions callback
---@private

---@type table<string, Editprompt.Subcommand>
---@private
local subcmd_tbl = {
  --[=[@doc
  category = "command"
  name = "input"
  desc = "Send buffer content or selected lines to clipboard (--auto-send for auto paste)"

  [[args]]
  name = "--auto-send"
  desc = "Auto send to target pane"

  [[args]]
  name = "--visual"
  desc = "Send all lines touched by the current visual selection"
  --]=]
  input = {
    impl = function(args)
      local has_auto_send = false
      local has_visual = false

      for _, arg in ipairs(args) do
        if arg == "--auto-send" then
          has_auto_send = true
        elseif arg == "--visual" then
          has_visual = true
        end
      end

      if has_visual and has_auto_send then
        require("editprompt.modes.input").execute_visual_auto_send()
      elseif has_visual then
        require("editprompt.modes.input").execute_visual()
      elseif has_auto_send then
        require("editprompt.modes.input").execute_auto_send()
      else
        require("editprompt.modes.input").execute()
      end
    end,
    complete = function(subcmd_arg_lead)
      return CommandRegister.get_complete(
        subcmd_arg_lead,
        { "--auto-send", "--visual" }
      )
    end,
  },
  --[=[@doc
  category = "command"
  name = "history"
  desc = "History navigation for previously sent prompts"

  [[args]]
  name = "prev|next"
  desc = "prev: older prompt, next: newer prompt or current draft"
  --]=]
  history = {
    impl = function(args)
      local subcmd = args[1]
      if subcmd == "prev" then
        require("editprompt.history").prev()
      elseif subcmd == "next" then
        require("editprompt.history").next()
      else
        vim.notify(
          "Editprompt: Unknown history command: " .. (subcmd or ""),
          vim.log.levels.ERROR
        )
      end
    end,
    complete = function(subcmd_arg_lead)
      return CommandRegister.get_complete(subcmd_arg_lead, { "prev", "next" })
    end,
  },
  --[=[@doc
  category = "command"
  name = "dump"
  desc = "Dump quoted content from editprompt CLI"
  --]=]
  dump = {
    impl = function()
      require("editprompt.modes.dump").execute()
    end,
  },
  --[=[@doc
  category = "command"
  name = "press"
  desc = "Send a key to target pane without Enter"

  [[args]]
  name = "key"
  desc = "Key to send (e.g., 1, Tab, Enter)"
  --]=]
  press = {
    impl = function(args)
      if not args[1] then
        vim.notify("Editprompt: Key is required for press command", vim.log.levels.ERROR)
        return
      end
      require("editprompt.modes.press").execute(args[1])
    end,
  },
  --[=[@doc
  category = "command"
  name = "press_mode"
  desc = "Enter press mode for continuous key sending"
  --]=]
  press_mode = {
    impl = function()
      require("editprompt.modes.press_mode").start()
    end,
  },
  --[=[@doc
  category = "command"
  name = "stash"
  desc = "Stash operations (push/pop/drop)"

  [[args]]
  name = "push|pop|drop"
  desc = "push: save buffer to stash, pop: restore from stash, drop: delete from stash"
  --]=]
  stash = {
    impl = function(args)
      local subcmd = args[1]
      if subcmd == "push" then
        require("editprompt.modes.stash").push()
      elseif subcmd == "pop" then
        require("editprompt.modes.stash").pop()
      elseif subcmd == "drop" then
        require("editprompt.modes.stash").drop()
      else
        vim.notify(
          "Editprompt: Unknown stash command: " .. (subcmd or ""),
          vim.log.levels.ERROR
        )
      end
    end,
    complete = function(subcmd_arg_lead)
      return CommandRegister.get_complete(
        subcmd_arg_lead,
        { "push", "pop", "drop" }
      )
    end,
  },
}

CommandRegister.regist(subcmd_tbl)
