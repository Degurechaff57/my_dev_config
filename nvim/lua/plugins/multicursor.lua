-- Multiple cursors, keyed around a dedicated <leader>m prefix.
--
-- Why not the upstream example keys: it binds <leader>n / <leader>s / <leader>x and the
-- arrow keys, which LazyVim already uses (notification history, the search group, the
-- diagnostics group, plain vertical motion). <C-Down>/<C-Up> are also avoided: this
-- config already binds them to window resizing and tmux does not deliver them.
return {
  "jake-stewart/multicursor.nvim",
  branch = "1.0",
  event = "VeryLazy",
  config = function()
    local mc = require("multicursor-nvim")
    mc.setup()

    local set = vim.keymap.set
    local opts = function(desc)
      return { desc = "Multicursor: " .. desc }
    end

    -- Add a cursor on the next/previous match of the word or selection under the cursor.
    set({ "n", "x" }, "<C-n>", function() mc.matchAddCursor(1) end, opts("add cursor on next match"))
    set({ "n", "x" }, "<C-p>", function() mc.matchAddCursor(-1) end, opts("add cursor on previous match"))

    -- Add a cursor on the line below/above, or skip a line while matching.
    set({ "n", "x" }, "<leader>md", function() mc.lineAddCursor(1) end, opts("add cursor below"))
    set({ "n", "x" }, "<leader>mu", function() mc.lineAddCursor(-1) end, opts("add cursor above"))
    set({ "n", "x" }, "<leader>mD", function() mc.lineSkipCursor(1) end, opts("skip line down"))
    set({ "n", "x" }, "<leader>mU", function() mc.lineSkipCursor(-1) end, opts("skip line up"))

    -- Move past matches instead of adding a cursor on them.
    set({ "n", "x" }, "<leader>mn", function() mc.matchSkipCursor(1) end, opts("skip match forwards"))
    set({ "n", "x" }, "<leader>mN", function() mc.matchSkipCursor(-1) end, opts("skip match backwards"))

    -- Add and remove cursors with ctrl + left mouse button.
    set("n", "<C-leftmouse>", mc.handleMouse, opts("add cursor (mouse)"))
    set("n", "<C-leftdrag>", mc.handleMouseDrag, opts("drag cursors (mouse)"))
    set("n", "<C-leftrelease>", mc.handleMouseRelease, opts("release cursors (mouse)"))

    -- Disable/enable cursors: while disabled only the main cursor moves.
    set({ "n", "x" }, "<leader>mq", mc.toggleCursor, opts("toggle cursors"))

    -- This layer only exists while multiple cursors are present.
    mc.addKeymapLayer(function(layerSet)
      layerSet({ "n", "x" }, "<left>", mc.prevCursor, opts("previous cursor"))
      layerSet({ "n", "x" }, "<right>", mc.nextCursor, opts("next cursor"))
      layerSet({ "n", "x" }, "<leader>mx", mc.deleteCursor, opts("delete main cursor"))
      layerSet("n", "<esc>", function()
        if not mc.cursorsEnabled() then
          mc.enableCursors()
        else
          mc.clearCursors()
        end
      end, opts("collapse cursors"))
    end)

    -- Group the prefix in which-key so the keys are discoverable.
    pcall(function()
      require("which-key").add({ { "<leader>m", group = "multicursor" } })
    end)
  end,
}
