return {
  "mfussenegger/nvim-lint",
  opts = {
    linters = {
      -- 注意：LazyVim 较新版本默认使用 markdownlint-cli2
      ["markdownlint-cli2"] = {
        args = { "--disable", "MD033", "--" },
      },
    },
  },
}
