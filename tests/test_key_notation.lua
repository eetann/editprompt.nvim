local T = MiniTest.new_set()

local key_notation = require("editprompt.key_notation")

local function with_mux(mux, fn)
  local original = vim.env.EDITPROMPT_MUX
  vim.env.EDITPROMPT_MUX = mux
  local ok, err = pcall(fn)
  vim.env.EDITPROMPT_MUX = original
  if not ok then
    error(err)
  end
end

T["tmux"] = MiniTest.new_set()

T["tmux"]["plain characters pass through unchanged"] = function()
  with_mux("tmux", function()
    MiniTest.expect.equality(key_notation.convert("1"), "1")
    MiniTest.expect.equality(key_notation.convert("a"), "a")
    MiniTest.expect.equality(key_notation.convert("Z"), "Z")
  end)
end

T["tmux"]["<CR> converts to C-m"] = function()
  with_mux("tmux", function()
    MiniTest.expect.equality(key_notation.convert("<CR>"), "C-m")
  end)
end

T["tmux"]["<Tab> converts to Tab"] = function()
  with_mux("tmux", function()
    MiniTest.expect.equality(key_notation.convert("<Tab>"), "Tab")
  end)
end

T["tmux"]["<Esc> converts to Escape"] = function()
  with_mux("tmux", function()
    MiniTest.expect.equality(key_notation.convert("<Esc>"), "Escape")
  end)
end

T["tmux"]["arrow keys convert correctly"] = function()
  with_mux("tmux", function()
    MiniTest.expect.equality(key_notation.convert("<Up>"), "Up")
    MiniTest.expect.equality(key_notation.convert("<Down>"), "Down")
    MiniTest.expect.equality(key_notation.convert("<Left>"), "Left")
    MiniTest.expect.equality(key_notation.convert("<Right>"), "Right")
  end)
end

T["tmux"]["<C-c> converts to C-c"] = function()
  with_mux("tmux", function()
    MiniTest.expect.equality(key_notation.convert("<C-c>"), "C-c")
    MiniTest.expect.equality(key_notation.convert("<C-a>"), "C-a")
  end)
end

T["wezterm"] = MiniTest.new_set()

T["wezterm"]["plain characters pass through unchanged"] = function()
  with_mux("wezterm", function()
    MiniTest.expect.equality(key_notation.convert("1"), "1")
    MiniTest.expect.equality(key_notation.convert("a"), "a")
  end)
end

T["wezterm"]["<CR> converts to \\r"] = function()
  with_mux("wezterm", function()
    MiniTest.expect.equality(key_notation.convert("<CR>"), "\r")
  end)
end

T["wezterm"]["<Tab> converts to \\t"] = function()
  with_mux("wezterm", function()
    MiniTest.expect.equality(key_notation.convert("<Tab>"), "\t")
  end)
end

T["wezterm"]["<Esc> converts to \\x1b"] = function()
  with_mux("wezterm", function()
    MiniTest.expect.equality(key_notation.convert("<Esc>"), "\x1b")
  end)
end

T["wezterm"]["arrow keys convert correctly"] = function()
  with_mux("wezterm", function()
    MiniTest.expect.equality(key_notation.convert("<Up>"), "\x1b[A")
    MiniTest.expect.equality(key_notation.convert("<Down>"), "\x1b[B")
    MiniTest.expect.equality(key_notation.convert("<Left>"), "\x1b[D")
    MiniTest.expect.equality(key_notation.convert("<Right>"), "\x1b[C")
  end)
end

T["wezterm"]["<C-c> converts to control character"] = function()
  with_mux("wezterm", function()
    MiniTest.expect.equality(key_notation.convert("<C-c>"), "\x03")
    MiniTest.expect.equality(key_notation.convert("<C-a>"), "\x01")
  end)
end

T["herdr"] = MiniTest.new_set()

T["herdr"]["plain characters pass through unchanged"] = function()
  with_mux("herdr", function()
    MiniTest.expect.equality(key_notation.convert("1"), "1")
    MiniTest.expect.equality(key_notation.convert("a"), "a")
    MiniTest.expect.equality(key_notation.convert("Z"), "Z")
  end)
end

T["herdr"]["special keys convert correctly"] = function()
  with_mux("herdr", function()
    local cases = {
      { "<CR>", "enter" },
      { "<Tab>", "tab" },
      { "<S-Tab>", "shift+tab" },
      { "<Esc>", "esc" },
      { "<BS>", "backspace" },
      { "<Space>", "space" },
      { "<Up>", "up" },
      { "<Down>", "down" },
      { "<Left>", "left" },
      { "<Right>", "right" },
    }

    for _, case in ipairs(cases) do
      MiniTest.expect.equality(key_notation.convert(case[1]), case[2])
    end
  end)
end

T["herdr"]["<C-c> converts to ctrl+c"] = function()
  with_mux("herdr", function()
    MiniTest.expect.equality(key_notation.convert("<C-c>"), "ctrl+c")
    MiniTest.expect.equality(key_notation.convert("<C-a>"), "ctrl+a")
  end)
end

return T
