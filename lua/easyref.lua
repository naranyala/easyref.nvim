local M = {}

-- EasyRef data
local cheatsheets = {
  neovim = {
    title = "Neovim EasyRef",
    items = {
      { cmd = "<C-w>w", desc = "Switch windows" },
      { cmd = ":w",     desc = "Save file" },
      { cmd = ":q",     desc = "Quit" },
      { cmd = "dd",     desc = "Delete line" },
      { cmd = "yy",     desc = "Yank line" },
    },
  },
  lua = {
    title = "Lua EasyRef",
    items = {
      { cmd = "local",        desc = "Declare local variable" },
      { cmd = "function",     desc = "Define function" },
      { cmd = "if-then",      desc = "Conditional statement" },
      { cmd = "table.insert", desc = "Add to table" },
    },
  },
  typescript = {
    title = "TypeScript EasyRef",
    items = {
      { cmd = "interface", desc = "Define interface" },
      { cmd = "type",      desc = "Create type alias" },
      { cmd = ": string",  desc = "Type annotation" },
      { cmd = "as const",  desc = "Literal type assertion" },
      { cmd = "?",         desc = "Optional property" },
    },
  },
  tailwindcss = {
    title = "TailwindCSS EasyRef",
    items = {
      { cmd = "flex",        desc = "Enable flexbox" },
      { cmd = "grid",        desc = "Enable grid" },
      { cmd = "p-4",         desc = "Padding 1rem" },
      { cmd = "m-2",         desc = "Margin 0.5rem" },
      { cmd = "bg-blue-500", desc = "Blue background" },
    },
  },
}

-- Buffer and window variables
local buf = nil
local win = nil
local current_sheet = "neovim"

-- Create the sidebar content
local function update_content()
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local lines = {}
  local sheet = cheatsheets[current_sheet]
  local max_cmd_width = 12 -- Maximum width for command column

  -- Menu first
  table.insert(lines, "Menu (press number):")
  table.insert(lines, "1. Neovim EasyRef")
  table.insert(lines, "2. Lua EasyRef")
  table.insert(lines, "3. TypeScript EasyRef")
  table.insert(lines, "4. TailwindCSS EasyRef")
  table.insert(lines, string.rep("─", 38))

  -- Current cheatsheet title
  table.insert(lines, sheet.title)
  table.insert(lines, string.rep("─", 38))

  -- Table header
  table.insert(lines, string.format("%-" .. max_cmd_width .. "s│ %s", "Command", "Description"))
  table.insert(lines, string.rep("─", max_cmd_width) .. "┼" .. string.rep("─", 25))

  -- EasyRef items in table format
  for _, item in ipairs(sheet.items) do
    local cmd = item.cmd:sub(1, max_cmd_width) -- Truncate if too long
    table.insert(lines, string.format("%-" .. max_cmd_width .. "s│ %s", cmd, item.desc))
  end

  -- Footer
  table.insert(lines, string.rep("─", 38))
  table.insert(lines, "Press 'q' to close")

  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

-- Open the sidebar
function M.open()
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
    vim.api.nvim_buf_set_option(buf, "filetype", "cheatsheet")
  end

  if not win or not vim.api.nvim_win_is_valid(win) then
    win = vim.api.nvim_open_win(buf, true, {
      relative = "editor",
      width = 40,
      height = vim.o.lines - 5,
      col = vim.o.columns - 40,
      row = 2,
      style = "minimal",
      border = "single",
    })
  end

  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  -- Remove the immediate readonly setting
  -- vim.api.nvim_buf_set_option(buf, 'readonly', true)

  vim.api.nvim_win_set_option(win, "wrap", false)
  vim.api.nvim_win_set_option(win, "number", false)

  -- Set keymaps using native Neovim commands
  vim.api.nvim_buf_set_keymap(buf, "n", "1", ":EasyRefSwitch neovim<CR>", { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, "n", "2", ":EasyRefSwitch lua<CR>", { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, "n", "3", ":EasyRefSwitch typescript<CR>", { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, "n", "4", ":EasyRefSwitch tailwindcss<CR>", { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, "n", "q", ":EasyRefClose<CR>", { noremap = true, silent = true })

  update_content()

  -- Set readonly after content is updated
  vim.api.nvim_create_autocmd("BufWinEnter", {
    buffer = buf,
    once = true,
    callback = function()
      vim.schedule(function()
        vim.api.nvim_buf_set_option(buf, "readonly", true)
      end)
    end,
  })
end

-- Close the sidebar
function M.close()
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
    win = nil
  end
end

-- Switch between cheatsheets
function M.switch(sheet_name)
  if cheatsheets[sheet_name] then
    current_sheet = sheet_name
    update_content()
  end
end

-- Toggle the sidebar
function M.toggle()
  if win and vim.api.nvim_win_is_valid(win) then
    M.close()
  else
    M.open()
  end
end

-- Setup function
function M.setup(opts)
  vim.api.nvim_create_user_command("EasyRef", M.toggle, {})
  vim.api.nvim_create_user_command("EasyRefClose", M.close, {})
  vim.api.nvim_create_user_command("EasyRefSwitch", function(opts)
    M.switch(opts.args)
  end, { nargs = 1 })
end

return M
