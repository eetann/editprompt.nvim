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
  desc = "Send buffer content to clipboard (--auto-send for auto paste)"

  [[args]]
  name = "--auto-send"
  desc = "Auto send to target pane"
  --]=]
  input = {
    impl = function(args)
      if args[1] == "--auto-send" then
        require("editprompt.modes.input").execute_auto_send()
      else
        require("editprompt.modes.input").execute()
      end
    end,
    complete = function(subcmd_arg_lead)
      return CommandRegister.get_complete(subcmd_arg_lead, { "--auto-send" })
    end,
  },
  --[=[@doc
  category = "command"
  name = "capture"
  desc = "Capture quoted content from editprompt CLI"
  --]=]
  capture = {
    impl = function()
      require("editprompt.modes.capture").execute()
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
      return CommandRegister.get_complete(subcmd_arg_lead, { "push", "pop", "drop" })
    end,
  },
}

CommandRegister.regist(subcmd_tbl)
