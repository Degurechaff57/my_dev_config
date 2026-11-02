return {
  { "OXY2DEV/markview.nvim" },

  -- Tinymist 性能：大 Typst 文件里 semanticTokens / inlayHint 等后台请求会
  -- 排到十几秒甚至几十秒，导致看起来像 LSP timeout。
  -- 这里优先保证 completion/hover/definition/format 流畅。
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = { exclude = { "vue", "typst" } },
      servers = {
        tinymist = {
          settings = {
            semanticTokens = "disable", -- tinymist 官方推荐的性能设置
          },
        },
      },
    },
  },

  -- 格式化：LazyVim typst extra 默认给 typst 配的是
  --   { "typstyle", lsp_format = "prefer" }
  -- prefer 会优先使用 tinymist 的 LSP 格式化，但当前 tinymist 对 Typst 返回空
  -- edits，导致外部 typstyle 永远不会被执行。改成 fallback：优先外部 typstyle，
  -- typstyle 不可用时才回退 LSP。
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        typst = { "typstyle", lsp_format = "fallback" },
      },
    },
  },

  {
    "gitefdf/typst-outline.nvim",
    lazy = false,
    -- 必须有 opts（哪怕是空表）：lazy.nvim 才会调用 require("typst-outline").setup()
    -- 否则插件的命令/autocmd 都不会注册，看起来就像“没装上”。
    opts = {},
    config = function(_, opts)
      require("typst-outline").setup(opts)
      require("config.typst_headings").setup()
    end,
    keys = {
      { "<leader>to", "<cmd>TypstOutline<CR>", desc = "Typst Outline" },
    },
  },
}
