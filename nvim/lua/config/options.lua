-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.spelllang = { "en", "cjk" }

-- OSC 52 clipboard over SSH: yank in nvim → local laptop clipboard
-- How it works: nvim yank → OSC 52 escape seq → tmux forwards → local terminal writes to clipboard
-- LazyVim disables clipboard sync (vim.opt.clipboard = "") in SSH by default;
-- we re-enable it with the OSC 52 provider so yanks reach your local machine.
if vim.env.SSH_CONNECTION or vim.env.SSH_CLIENT or vim.env.SSH_TTY then
  local ok, osc52 = pcall(require, "vim.ui.clipboard.osc52")
  if ok then
    vim.g.clipboard = {
      name = "OSC 52",
      copy = {
        ["+"] = osc52.copy("+"),
        ["*"] = osc52.copy("*"),
      },
      -- No OSC 52 paste — the terminal (WezTerm) sends pasted text
      -- directly via bracketed paste, which is orders of magnitude
      -- faster than base64 roundtripping the clipboard through OSC 52.
      paste = {
        ["+"] = function() return vim.fn.getreg("+") end,
        ["*"] = function() return vim.fn.getreg("*") end,
      },
    }
    vim.opt.clipboard = "unnamedplus" -- yank → + register → OSC 52 → local clipboard
  end
end
