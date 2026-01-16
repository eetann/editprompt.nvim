<!-- panvimdoc-ignore-start -->
# editprompt.nvim
<!-- panvimdoc-ignore-end -->

## ✨ Features

- Neovim frontend for the [editprompt](https://github.com/eetann/editprompt) CLI tool
- Send buffer content to clipboard or target pane
- Capture output from editprompt CLI into buffer
- Stash/restore buffer content with picker UI

## 📦 Installation
```txt
eetann/editprompt.nvim
```

with [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
  "eetann/editprompt.nvim",
  dependencies = {
    "folke/snacks.nvim", -- optional, for snacks.picker
  },
  opts = {}
}
```

**Example of lazy.nvim lazy loading**

```lua
{
  "eetann/editprompt.nvim",
  -- ...
  keys = {
    { "<Space>ei", "<Cmd>Editprompt input --auto-send<CR>" },
    { "<Space>eI", "<Cmd>Editprompt input<CR>" },
    { "<Space>ec", "<Cmd>Editprompt capture<CR>" },
    { "<Space>es", "<Cmd>Editprompt stash pop<CR>" },
    { "<Space>eS", "<Cmd>Editprompt stash push<CR>" },
  },
  cmd = "Editprompt",
}
```

## ⚙️ Default Config

<!-- auto-generate-s:default_config -->
```lua
{
  cmd = "editprompt",
  picker = "native"
}
```
<!-- auto-generate-e:default_config -->

## 🚀 Usage

## Command
`:Editprompt {subcommand}`

<!-- auto-generate-s:command -->

### capture
```
:Editprompt capture
```

Capture quoted content from editprompt CLI

_No arguments_
&nbsp;


### input
```
:Editprompt input
```

Send buffer content to clipboard (--auto-send for auto paste)


| Name | Description |
|------|-------------|
| --auto-send | Auto send to target pane |

&nbsp;


### stash
```
:Editprompt stash
```

Stash operations (push/pop/drop)


| Name | Description |
|------|-------------|
| push\|pop\|drop | push: save buffer to stash, pop: restore from stash, drop: delete from stash |

&nbsp;

<!-- auto-generate-e:command -->

## API

<!-- auto-generate-s:api -->

### capture
Capture quoted content from editprompt CLI.
Executes `editprompt dump`.

_No arguments_
&nbsp;


### input
Send buffer content to clipboard.
Executes `editprompt input --always-copy`.

_No arguments_
&nbsp;


### input_auto_send
Send buffer content to target pane automatically.
Executes `editprompt input --auto-send`.

_No arguments_
&nbsp;


### setup
```lua
editprompt.setup({...})
```
Setup editprompt


| Name | Type | Description |
|------|------|-------------|
| config | \|`editprompt.Config`\| | Setup editprompt |

&nbsp;


### stash_pop
Pop stash content with picker.
Executes `editprompt stash list` then `editprompt stash pop --key`.

_No arguments_
&nbsp;


### stash_push
Push buffer content to stash.
Executes `editprompt stash push`.

_No arguments_
&nbsp;

<!-- auto-generate-e:api -->
