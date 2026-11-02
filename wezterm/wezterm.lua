-- ============================================================
-- WezTerm 配置 — 键位与 VSCode / tmux 统一
--
-- 统一方案（2026-10）：
--     Ctrl+1..8     → 直接切到第 N 个标签；Ctrl+9 → 最后一个标签
--     Ctrl+Tab      → 下一个标签；Ctrl+Shift+Tab → 上一个
--     Ctrl+Shift+5  → 上下分屏（VSCode: Ctrl+Shift+5 分屏终端）
--     Ctrl+\        → 左右分屏
--     Alt+←/→/↑/↓   → 切换 WezTerm 窗格
--     Alt+1..9      → 不拦截，透传给 tmux，用于切换 tmux pane（见 ~/.tmux.conf）
--     Ctrl+w        → 透传给 shell（终端里必须透传）
--
-- 注意：WezTerm 内置默认的标签切换是 Ctrl+Shift+数字 / Super+数字，不是 Ctrl+数字；
-- 而且 Super+数字在 Ubuntu 上被 Dock 的全局快捷键占用。
-- 所以下面显式把裸 Ctrl+数字绑定为标签切换 —— 代价是 tmux 收不到 Ctrl+数字。
-- tmux 里：Alt+数字 / Alt+hjkl 切 pane；Ctrl+b 数字 切 window。
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
	-- VSCode 里 Ctrl+Shift+5 = 分屏终端；这里给同样的键做「上下分屏」。
	-- 注意：Ctrl+Shift+5 也是 WezTerm 默认的 SplitVertical，写出来只是为了让
	-- 语义在配置里自解释，行为与默认一致。
	{ key = "5", mods = "CTRL|SHIFT", action = act.SplitVertical({}) },
	-- VSCode 里 Ctrl+Shift+5 的「正交」是 Ctrl+Shift+Alt+5；这里补左右分屏
	{ key = "e", mods = "CTRL|SHIFT", action = act.SplitHorizontal({}) },
	-- VSCode: Ctrl+\ = 向右拆分编辑器。这里给 WezTerm 同样的键做左右分屏
	{ key = "\\", mods = "CTRL", action = act.SplitHorizontal({}) },
	-- 兼容：保留 WezTerm 默认的 Ctrl+Alt+% / Ctrl+Alt+" 两个 tmux 风格分屏键，无需自定义

	-- ---------- 标签页 ----------
	-- Ctrl+Shift+T 是 WezTerm 默认（新建标签），与浏览器/VSCode 习惯一致，保留默认。
	-- 额外支持 Ctrl+T：默认表里没有，且原配置里 Ctrl+T 曾被 WezTerm 抢走导致
	-- PowerShell 侧 fzf 的 Ctrl+t（历史搜索）失效 —— 这里显式声明，行为可预期。
	{ key = "t", mods = "CTRL", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "T", mods = "CTRL", action = act.SpawnTab("CurrentPaneDomain") },

	-- 关闭标签页：Ctrl+Shift+W（浏览器习惯）与 Ctrl+F4（Windows 习惯）
	-- 不能用 Ctrl+W —— 那个必须透传给 shell 做「删除前一个单词」。
	-- WezTerm 默认没有 Ctrl+W 绑定，所以它本来就会透传，无需显式声明。
	{ key = "w", mods = "CTRL|SHIFT", action = act.EmitEvent("close-tab-safe") },
	{ key = "F4", mods = "CTRL", action = act.EmitEvent("close-tab-safe") },

	-- ---------- 窗格 ----------
	-- Alt+方向键 切换窗格是 WezTerm 默认，保留。
	-- Alt+数字 故意不绑定：透传给 tmux，用来切 tmux pane（见 ~/.tmux.conf）。
	-- 关闭当前窗格：Ctrl+Shift+Alt+W（比默认的 Ctrl+Shift+W 更明确，避免误关标签）
	{ key = "w", mods = "CTRL|SHIFT|ALT", action = act.CloseCurrentPane({ confirm = true }) },
	-- 放大/还原当前窗格（对应 VSCode 把某个编辑器组最大化的"专注"语义）
	{ key = "z", mods = "CTRL|SHIFT|ALT", action = act.TogglePaneZoomState },
}

-- ---------- 标签页直接跳转（Ctrl+数字）----------
-- WezTerm 默认只绑了 Ctrl+Shift+数字 / Super+数字；这里按统一方案改成裸 Ctrl+数字：
--   Ctrl+1..8 → 第 1..8 个标签；Ctrl+9 → 最后一个标签（和浏览器/VSCode 一致）
-- 注意：Super+数字 在 Ubuntu 上被 Dock 的全局快捷键占用，不能用。
for i = 1, 8 do
	table.insert(config.keys, {
		key = tostring(i),
		mods = "CTRL",
		action = act.ActivateTab(i - 1),
	})
end
table.insert(config.keys, { key = "9", mods = "CTRL", action = act.ActivateTab(-1) })

return config
