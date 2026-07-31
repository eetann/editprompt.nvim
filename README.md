<!-- panvimdoc-ignore-start -->
# editprompt.nvim
<!-- panvimdoc-ignore-end -->

## ✨ Features

- Neovim frontend for the [editprompt](https://github.com/eetann/editprompt) CLI tool
- Send buffer content or selected lines to clipboard or target pane
- Navigate previously sent prompts from history
- List and insert prompts from history via picker UI
- Dump output from editprompt CLI into buffer
- Stash/restore buffer content with picker UI
- Send key inputs to target pane (press mode for continuous input)

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
    { "<Space>eh", "<Cmd>Editprompt history list<CR>" },
    { "<Space>ed", "<Cmd>Editprompt dump<CR>" },
    { "<Space>es", "<Cmd>Editprompt stash pop<CR>" },
    { "<Space>eS", "<Cmd>Editprompt stash push<CR>" },
    { "<Space>ek", "<Cmd>Editprompt press_mode<CR>" },
  },
  cmd = "Editprompt",
}
```

## ⚙️ Default Config

<!-- auto-generate-s:default_config -->
```lua
{
  cmd = "editprompt",
  picker = "native",
  press_mode = {
    exit_key = "q"
  }
}
```
<!-- auto-generate-e:default_config -->

## 🚀 Usage

`--visual` is intended for visual-mode mappings such as `xmap <Cmd>Editprompt input --visual<CR>`.
It sends and removes all lines touched by the selection.

### Press key binding examples

**Pattern 1: Direct number key mapping**

Map number keys directly for responding to AskUserQuestion selections:

```lua
keys = {
  { "1", function() require("editprompt").press("1") end },
  { "2", function() require("editprompt").press("2") end },
  { "3", function() require("editprompt").press("3") end },
  { "4", function() require("editprompt").press("4") end },
  { "<CR>", function() require("editprompt").press("<CR>") end },
}
```

**Pattern 2: Prefix key mapping**

Use a prefix key to avoid conflicts with normal editing:

```lua
keys = {
  { "<Space>k1", function() require("editprompt").press("1") end },
  { "<Space>k2", function() require("editprompt").press("2") end },
  { "<Space>k<CR>", function() require("editprompt").press("<CR>") end },
  { "<Space>kk", function() require("editprompt").press_mode() end },
}
```

**Pattern 3: Press mode**

Enter press mode where all keys are forwarded to the target pane.
Press `q` to exit (configurable via `press_mode.exit_key`). Double-press `q` to send `q` instead.

```lua
keys = {
  { "<Space>kk", function() require("editprompt").press_mode() end },
}
```

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
| prev\|next\|list | prev: older prompt, next: newer prompt or current draft, list: pick a prompt from history and insert it |

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


### press
```
:Editprompt press
```

Send a key to target pane without Enter


| Name | Description |
|------|-------------|
| key | Key to send (e.g., 1, Tab, Enter) |

&nbsp;


### press_mode
```
:Editprompt press_mode
```

Enter press mode for continuous key sending

_No arguments_
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


### history_list
Show a picker of prompts sent this session and insert the selected one.
Inserts into an empty buffer, or appends after a blank line if the buffer already has content.
No CLI subprocess is executed; history is kept in memory for the session.

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


### press
Send a key to the target pane without Enter.
Executes `editprompt press -- {key}`.
Key notation is automatically converted from Neovim format to the multiplexer format.


| Name | Type | Description |
|------|------|-------------|
| key | string | Key to send in Neovim notation (e.g., '1', '<CR>', '<Tab>', '<C-c>') |

&nbsp;


### press_mode
Enter press mode for continuous key sending.
All key inputs are forwarded to the target pane.
Press the exit key (default: `q`) to leave press mode.
Double-press the exit key to send it instead.

_No arguments_
&nbsp;


### press_mode_stop
Exit press mode.

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
