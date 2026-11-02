-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

pcall(vim.api.nvim_del_augroup_by_name, "lazyvim_wrap_spell")

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("custom_wrap_with_spell", { clear = true }),
  pattern = { "text", "plaintex", "typst", "gitcommit", "markdown" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

-- Typst / tinymist: 大文档（尤其 import @preview 包时）里这些后台 LSP 功能
-- 会产生大量慢请求并排队：semanticTokens、inlayHint、foldingRange、
-- documentColor、documentHighlight。completion/hover 也会被堵在后面。
-- 这里关掉 Typst buffer 里最贵的几项，只保留编辑需要的 LSP 功能。
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("custom_typst_lsp_perf", { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client or client.name ~= "tinymist" then
      return
    end

    local buf = args.buf

    -- 不向 tinymist 请求这些可选能力
    client.server_capabilities.semanticTokensProvider = nil
    client.server_capabilities.inlayHintProvider = nil
    client.server_capabilities.documentColorProvider = nil

    local function disable()
      if not vim.api.nvim_buf_is_valid(buf) then
        return
      end
      vim.lsp.semantic_tokens.enable(false, { bufnr = buf })
      vim.lsp.inlay_hint.enable(false, { bufnr = buf })
      vim.lsp.document_color.enable(false, { bufnr = buf })
      -- 关掉 Snacks words 的 documentHighlight（光标移动时触发）
      vim.b[buf].snacks_words = false
    end

    disable()
    -- LazyVim 的 inlay hints 等可能在本 autocmd 之后才启用，再补一次
    vim.schedule(disable)
  end,
})
