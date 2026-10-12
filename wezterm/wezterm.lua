-- ============================================================
-- WezTerm 配置 — 与 VSCode 操作对齐
--
-- 设计原则：优先使用 WezTerm 内置默认键位，因为它们已经和 VSCode 一致：
--     Ctrl+Shift+5   → 分屏（VSCode: 终端分屏也是这个）
--     Ctrl+1/2/3     → 切换标签（VSCode: 切换编辑器组也是这个）
--     Ctrl+Tab       → 下一个标签（VSCode: 下一个编辑器）
--     Alt+←/→/↑/↓    → 切换窗格（VSCode: 无直接对应，但语义一致）
--     Ctrl+w         → 透传给 shell（VSCode: 关闭编辑器，但终端里必须透传）
--
-- 只覆盖默认中不好用的部分，其余一律不写 —— 配置越少越不容易和别的工具冲突。
--
-- 同步到 $HOME/.wezterm.lua 使用（bootstrap.sh 会建软链）
-- ============================================================
local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- ==================== 启动程序 ====================
-- Windows 用 PowerShell 7；Linux/macOS 交给登录 shell（现为 zsh）
if wezterm.target_triple:find("windows") then
	config.default_prog = { "pwsh", "-NoLogo" }
end

-- ==================== 字体 ====================
-- 首选 MesloLGM Nerd Font —— 这是 Linux 侧实际安装的 Nerd Font。
-- 注意：apt 的 `fonts-jetbrains-mono` 装的是【非 Nerd 版】，没有图标字形，
-- 所以它只能作为后备，不能当首选。
config.font = wezterm.font_with_fallback({
	"MesloLGM Nerd Font",
	"JetBrains Mono",
	"Cascadia Code",
	"Fira Code",
	"monospace",
})
config.font_size = 16.0

-- ==================== 主题 ====================
config.color_scheme = "Tokyo Night"
-- 背景透明度（1.0 = 完全不透明）
config.window_background_opacity = 0.96

-- ==================== 窗口 ====================
config.window_padding = { left = 10, right = 10, top = 10, bottom = 10 }
config.initial_cols = 130
config.initial_rows = 36
config.scrollback_lines = 10000
config.hide_mouse_cursor_when_typing = true

-- ==================== 标签栏 ====================
config.use_fancy_tab_bar = true
config.window_frame = {
	active_titlebar_bg = "#1a1b26",
	inactive_titlebar_bg = "#16161e",
	-- 注意：这里用 font_with_fallback，否则字体缺失时标题栏会回退成难看的默认字体
	font = wezterm.font_with_fallback({ "MesloLGM Nerd Font", "JetBrains Mono", "monospace" }),
	font_size = 10.5,
}

-- ==================== 光标 ====================
config.default_cursor_style = "BlinkingBar"
config.cursor_blink_rate = 500

-- ==================== 关闭标签页：最后一个是安全的 ====================
-- 关掉最后一个标签时 WezTerm 默认会退出整个进程。这里改成「先开个干净的再关」，
-- 让窗口和进程都活着，避免手滑关掉整个终端。
-- 注意：不能用 tab:close()（Tab 对象没有此方法），要用 window:perform_action()。
wezterm.on("close-tab-safe", function(window, pane)
	local mux_window = window:mux_window()
	if #mux_window:tabs() > 1 then
		window:perform_action(wezterm.action.CloseCurrentTab({ confirm = false }), pane)
	else
		mux_window:spawn_tab({})
		window:perform_action(wezterm.action.CloseCurrentTab({ confirm = false }), pane)
	end
end)
config.quit_when_all_windows_are_closed = false

-- ==================== 快捷键 ====================
local act = wezterm.action

config.keys = {
	-- ---------- 分屏（对齐 VSCode）----------
	-- VSCode: Ctrl+Shift+5 = 终端分屏。这里保持一致。
	-- Ctrl+Shift+5 是 WezTerm 默认的 SplitVertical（上下分），无需自定义。
	-- 补一个「左右分」的等价键，语义与 VSCode 的「向右拆分编辑器」一致。
	{ key = "e", mods = "CTRL|SHIFT", action = act.SplitHorizontal({}) },
	-- VSCode: Ctrl+\ = 向右拆分编辑器。这里给 WezTerm 同样的键
	{ key = "\\", mods = "CTRL", action = act.SplitHorizontal({}) },

	-- ---------- 标签页 ----------
	-- Ctrl+Shift+T 是 WezTerm 默认（新建标签），与浏览器/VSCode 习惯一致，保留默认。
	-- 这里额外支持 Ctrl+T：默认表里没有（会被 Windows 的 PowerShell 吃掉反引号类的键）
	{ key = "t", mods = "CTRL", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "T", mods = "CTRL", action = act.SpawnTab("CurrentPaneDomain") },

	-- 关闭标签页：Ctrl+Shift+W（浏览器习惯）与 Ctrl+F4（Windows 习惯）
	-- 不能用 Ctrl+W —— 那个必须透传给 shell 做「删除前一个单词」
	{ key = "w", mods = "CTRL|SHIFT", action = act.EmitEvent("close-tab-safe") },
	{ key = "F4", mods = "CTRL", action = act.EmitEvent("close-tab-safe") },

	-- ---------- 窗格 ----------
	-- Alt+方向键 切换窗格是 WezTerm 默认，保留（与 VSCode 的 Ctrl+数字 切组语义相近）
	-- 关闭当前窗格：Ctrl+Shift+Alt+W（比默认的 Ctrl+Shift+W 更明确，避免误关标签）
	{ key = "w", mods = "CTRL|SHIFT|ALT", action = act.CloseCurrentPane({ confirm = true }) },
	-- 放大/还原当前窗格（VSCode: Ctrl+B 折叠侧栏的"专注"语义）
	{ key = "z", mods = "CTRL|SHIFT|ALT", action = act.TogglePaneZoomState },
}

return config
