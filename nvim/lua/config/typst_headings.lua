-- Typst heading motions / section selection for plain .typ buffers.
--
--   ]]   next heading
--   [[   previous heading
--   vah  select the whole section (heading + body + subsections)
--   vih  select only the content under the heading (excluding the heading line)
--
-- Headings are detected with the same rules as typst-outline.nvim:
--   = Heading, == Heading, ...
--   #heading(level: 2)[Heading], #heading[Heading]
-- Comments are skipped (line comments and /* block comments */).
local M = {}

local function notify(msg, level)
  vim.notify("[typst-headings] " .. msg, level or vim.log.levels.INFO)
end

local function is_blank(line)
  return line == nil or line:match("^%s*$") ~= nil
end

---@return { lnum: integer, level: integer }[], string[]
local function scan(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local headings = {}
  local in_block = false

  for lnum, raw in ipairs(lines) do
    local line = raw
    if in_block then
      local close = line:find("%*/")
      if not close then
        goto continue
      end
      line = line:sub(close + 2)
      in_block = false
    end

    line = line:gsub("/%*.-%*/", "")
    local open = line:find("/%*")
    if open then
      in_block = true
      line = line:sub(1, open - 1)
    end

    if is_blank(line) or line:match("^%s*//") then
      goto continue
    end

    local level
    local eq = line:match("^(=+)%s+") or line:match("^(=+)$")
    if eq then
      level = math.min(#eq, 9)
    else
      local has_heading = line:match("#heading%s*%(.-%)%s*%[([^%]]*)%]")
        or line:match("#heading%s*%[([^%]]*)%]")
      if has_heading then
        level = math.min(tonumber(line:match("level:%s*(%d+)")) or 1, 9)
      end
    end

    if level then
      headings[#headings + 1] = { lnum = lnum, level = level }
    end

    ::continue::
  end

  return headings, lines
end

local function find_section(headings, lines, cursor_line)
  local current
  for _, h in ipairs(headings) do
    if h.lnum <= cursor_line then
      current = h
    else
      break
    end
  end
  if not current then
    return nil
  end

  local last = #lines
  for _, h in ipairs(headings) do
    if h.lnum > current.lnum and h.level <= current.level then
      last = h.lnum - 1
      break
    end
  end

  while last > current.lnum and is_blank(lines[last]) do
    last = last - 1
  end

  local inner_start = current.lnum + 1
  while inner_start <= last and is_blank(lines[inner_start]) do
    inner_start = inner_start + 1
  end

  return { heading = current.lnum, last = last, inner_start = inner_start }
end

--- Move to the next/previous heading in the current buffer.
--- @param dir integer 1 for next, -1 for previous
function M.move(dir)
  local buf = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)[1]
  local headings = scan(buf)
  local target

  if dir > 0 then
    for _, h in ipairs(headings) do
      if h.lnum > cursor then
        target = h
        break
      end
    end
  else
    for i = #headings, 1, -1 do
      if headings[i].lnum < cursor then
        target = headings[i]
        break
      end
    end
  end

  if not target then
    notify(dir > 0 and "No next heading" or "No previous heading", vim.log.levels.WARN)
    return
  end

  vim.cmd("normal! m'")
  vim.api.nvim_win_set_cursor(0, { target.lnum, 0 })
  vim.cmd("normal! ^zz")
end

--- Select the current section, linewise.
--- @param inner boolean true = only the body below the heading
function M.select(inner)
  local buf = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)[1]
  local headings, lines = scan(buf)
  local section = find_section(headings, lines, cursor)
  if not section then
    notify("Not inside a heading section", vim.log.levels.WARN)
    return
  end

  local first, last
  if inner then
    first, last = section.inner_start, section.last
  else
    first, last = section.heading, section.last
  end

  if not first or first > last then
    notify("Section has no content", vim.log.levels.WARN)
    return
  end

  -- Works both from Normal mode and from a Visual-mode mapping:
  -- :normal! ... would receive a `'<,'>` range in Visual mode, so leave
  -- Visual mode first, then re-create the selection linewise.
  vim.cmd("normal! \27")
  vim.api.nvim_win_set_cursor(0, { first, 0 })
  vim.cmd("normal! V")
  vim.api.nvim_win_set_cursor(0, { last, 0 })
end

local function map(buf, mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, {
    buffer = buf,
    silent = true,
    nowait = true,
    desc = desc,
  })
end

function M.attach(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].filetype ~= "typst" then
    return
  end
  if vim.bo[buf].buftype ~= "" then
    return
  end

  map(buf, { "n", "x" }, "]]", function() M.move(1) end, "Next Typst heading")
  map(buf, { "n", "x" }, "[[", function() M.move(-1) end, "Previous Typst heading")
  map(buf, "x", "ah", function() M.select(false) end, "Select Typst section")
  map(buf, "x", "ih", function() M.select(true) end, "Select Typst section content")
end

local function refresh(buf)
  if not buf or buf == 0 then
    buf = vim.api.nvim_get_current_buf()
  end
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].filetype ~= "typst" then
    return
  end
  -- Run after the current event's other handlers: LSP, gitsigns and friends
  -- install their own buffer-local ]] / [[ / ih mappings and would otherwise
  -- overwrite ours. Snacks installs its LSP ]]/[[ keymaps through a 100ms
  -- debounce, hence the second, delayed pass.
  local function attach()
    if vim.api.nvim_buf_is_valid(buf) then
      M.attach(buf)
    end
  end
  vim.schedule(attach)
  vim.defer_fn(attach, 200)
end

function M.setup()
  local group = vim.api.nvim_create_augroup("TypstHeadings", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "typst",
    callback = function(ev)
      M.attach(ev.buf)
      refresh(ev.buf)
    end,
  })

  -- Re-apply whenever something else may have written the same buffer-local keys.
  vim.api.nvim_create_autocmd({ "BufWinEnter", "BufEnter", "LspAttach" }, {
    group = group,
    callback = function(ev)
      local buf = ev.buf
      if buf and vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "typst" then
        refresh(buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = { "LazyFile", "VeryLazy" },
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      if vim.bo[buf].filetype == "typst" then
        refresh(buf)
      end
    end,
  })

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "typst" then
      M.attach(buf)
    end
  end
end

return M
