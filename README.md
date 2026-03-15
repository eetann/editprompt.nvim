<!-- panvimdoc-ignore-start -->
# editprompt.nvim
<!-- panvimdoc-ignore-end -->

## ✨ Features

- Neovim frontend for the [editprompt](https://github.com/eetann/editprompt) CLI tool
- Send buffer content or selected lines to clipboard or target pane
- Navigate previously sent prompts from history
- Dump output from editprompt CLI into buffer
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
    { "<Space>ei", "<Cmd>Editprompt input --visual --auto-send<CR>", mode = "x" },
    { "<Space>ep", "<Cmd>Editprompt history prev<CR>" },
    { "<Space>en", "<Cmd>Editprompt history next<CR>" },
    { "<Space>ed", "<Cmd>Editprompt dump<CR>" },
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

`--visual` is intended for visual-mode mappings such as `xmap <Cmd>Editprompt input --visual<CR>`.
It sends and removes all lines touched by the selection.

### Input Hooks

`require("editprompt").input_content(content)` sends provided content without reading the current buffer.

Source-specific behavior:

- `input()` sends the current buffer and clears it on success
- `input_auto_send()` sends the current buffer with `--auto-send` and clears it on success
- `input_visual()` sends all lines touched by the current visual selection and deletes them on success
- `input_visual_auto_send()` sends the current visual selection with `--auto-send` and deletes it on success
- `input_content(content)` sends the provided content with `--always-copy`
- `input_content_auto_send(content)` sends the provided content with `--auto-send`

You can customize input behavior globally via `setup()`:

```lua
require("editprompt").setup({
  before_input = function(content, ctx)
    local normalized = content:gsub("\t", "  ")
    if not normalized:find("\n$") then
      normalized = normalized .. "\n"
    end
    return normalized
  end,
  should_copy = function(content, ctx)
    return not vim.startswith(content, "/")
  end,
  on_success = function(content, bufnr, ctx)
    if ctx.auto_send then
      require("editprompt").stash_pop_latest()
    end
  end,
  on_error = function(content, bufnr, result, ctx)
    vim.notify("editprompt error: " .. (result.stderr or "Unknown error"), vim.log.levels.ERROR)
  end,
})
```

### Execution Order

1. `before_input`
2. CLI execution
3. built-in cleanup for the called `input*`
4. history push when enabled
5. `on_success`

If `on_error` is configured, the plugin does not emit its default error notification.

## Command
`:Editprompt {subcommand}`

<!-- auto-generate-s:command -->

### dump
```
:Editprompt dump
```

Dump quoted content from editprompt CLI

_No arguments_
&nbsp;


### history
```
:Editprompt history
```

History navigation for previously sent prompts


| Name | Description |
|------|-------------|
| prev\|next | prev: older prompt, next: newer prompt or current draft |

&nbsp;


### input
```
:Editprompt input
```

Send buffer content or selected lines to clipboard (--auto-send for auto paste)


| Name | Description |
|------|-------------|
| --auto-send | Auto send to target pane |
| --visual | Send all lines touched by the current visual selection |

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

### dump
Dump quoted content from editprompt CLI.
Executes `editprompt dump`.

_No arguments_
&nbsp;


### history_next
Replace current buffer content with the next prompt in history.

_No arguments_
&nbsp;


### history_prev
Replace current buffer content with the previous sent prompt.

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


### input_content
Send provided content to clipboard.
Executes `editprompt input --always-copy` with the given content.


| Name | Type | Description |
|------|------|-------------|
| content | string | Content to send |

&nbsp;


### input_content_auto_send
Send provided content to target pane automatically.
Executes `editprompt input --auto-send` with the given content.


| Name | Type | Description |
|------|------|-------------|
| content | string | Content to send |

&nbsp;


### input_visual
Send lines touched by the visual selection to clipboard.
Executes `editprompt input --always-copy` with the selected lines.

_No arguments_
&nbsp;


### input_visual_auto_send
Send lines touched by the visual selection to target pane automatically.
Executes `editprompt input --auto-send` with the selected lines.

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


### stash_pop_latest
Pop the latest stash content without showing picker.
Executes `editprompt stash list` then `editprompt stash pop --key` for the newest entry.

_No arguments_
&nbsp;


### stash_push
Push buffer content to stash.
Executes `editprompt stash push`.

_No arguments_
&nbsp;

<!-- auto-generate-e:api -->
