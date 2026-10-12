return {

  {
    "bjarneo/lazyvim-cheatsheet.nvim",
    keys = {
      {
        "<leader>ch",
        function()
          require("lazyvim-cheatsheet").show()
        end,
        desc = "Show LazyVim Cheatsheet",
      },
    },
  },
  -- 使用 lazy.nvim 安装
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = "nvim-tree/nvim-web-devicons",
    opts = {
      options = {
        always_show_bufferline = true, -- 只有一个 buffer 时也始终显示
      },
    },
  },
}
