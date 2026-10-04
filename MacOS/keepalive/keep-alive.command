#!/bin/bash

# ==============================
# 全局 App Nap 禁用工具（macOS）
# 功能：禁用/恢复 App Nap（后台休眠）、查看状态
# 原理：NSAppSleepDisabled 写入全局偏好域 NSGlobalDomain，
#       默认作用于全部应用（应用自身域的设置优先于全局）
# 注意：修改后需完全退出并重新打开应用才生效
# 说明：图形菜单用静态中文 heredoc 走 stdin（原先菜单的写法，从未乱码）；
#       含变量的结果/错误输出一律走终端 printf（终端显示一直正常）。
#       勿用 osascript -e / 环境变量 / do shell script 传中文变量，实测均乱码
# ==============================

export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8

CHOICE_FILE="/tmp/.keepalive-choice"

# 自动提权：非 root 运行时自动以 sudo 重新执行本脚本（密码在终端窗口输入，无需手动 sudo）
if [ $UID -ne 0 ]; then
    printf '\n需要管理员权限，正在自动提权，请在下方输入管理员密码...\n\n'
    exec sudo /bin/bash "$0"
fi

clear

# 图形菜单（静态中文，原先菜单的原样写法）
osascript > "$CHOICE_FILE" <<'EOF'
set options to {"🔋 一键开启保活（禁用App Nap）", "🔓 一键关闭保活", "👀 查看保活状态"}
choose from list options with title "App Nap 全局保活工具" with prompt "选择一个操作：" default items {item 1 of options}
EOF
CHOICE=$(cat "$CHOICE_FILE")
rm -f "$CHOICE_FILE"

if [ -z "$CHOICE" ] || [ "$CHOICE" = "false" ]; then
    exit 0
fi

# ======================
# 1. 开启保活（禁用 App Nap）
# ======================
if [[ $CHOICE == *"开启保活"* ]]; then

sudo defaults write NSGlobalDomain NSAppSleepDisabled -bool YES

printf '\n✅ 已开启全局保活（App Nap 已对全部应用禁用）！\n\n注意：需完全退出并重新打开应用后生效。\n'

# ======================
# 2. 关闭保活（恢复默认）
# ======================
elif [[ $CHOICE == *"关闭保活"* ]]; then

sudo defaults delete NSGlobalDomain NSAppSleepDisabled 2>/dev/null

printf '\n✅ 已关闭全局保活（恢复系统默认）！\n'

# ======================
# 3. 查看保活状态
# ======================
elif [[ $CHOICE == *"查看保活状态"* ]]; then

if [ "$(sudo defaults read NSGlobalDomain NSAppSleepDisabled 2>/dev/null)" = "1" ]; then
    STATUS="全局保活已开启（App Nap 已禁用）"
else
    STATUS="全局保活未开启（系统默认，后台可能被休眠降速）"
fi

printf '\n当前状态：%s\n' "$STATUS"

fi

exit 0
