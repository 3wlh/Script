#!/bin/bash

# ==============================
# 全局 App Nap 禁用工具（macOS）
# 功能：禁用/恢复 App Nap（后台休眠）、查看状态
# 原理：NSAppSleepDisabled 写入全局偏好域 NSGlobalDomain，
#       默认作用于全部应用（应用自身域的设置优先于全局）
# 注意：修改后需完全退出并重新打开应用才生效
# ==============================

if [ $UID -ne 0 ]; then
    echo "需要管理员权限，请重新运行：sudo $0"
    exit 1
fi

clear

# 图形菜单
CHOICE=$(osascript <<'EOF'
set options to {"🔋 一键开启保活（禁用App Nap）", "🔓 一键关闭保活", "👀 查看保活状态"}
choose from list options with title "App Nap 全局保活工具" with prompt "选择一个操作：" default items {"🔋 一键开启保活（禁用App Nap）"}
EOF
)

if [ "$CHOICE" = "false" ]; then
    exit 0
fi

# ======================
# 1. 开启保活（禁用 App Nap）
# ======================
if [[ $CHOICE == *"开启保活"* ]]; then

sudo defaults write NSGlobalDomain NSAppSleepDisabled -bool YES

osascript -e 'display dialog "✅ 已开启全局保活（App Nap 已对全部应用禁用）！需完全退出并重新打开应用后生效。" buttons {"OK"}'

# ======================
# 2. 关闭保活（恢复默认）
# ======================
elif [[ $CHOICE == *"关闭保活"* ]]; then

sudo defaults delete NSGlobalDomain NSAppSleepDisabled 2>/dev/null

osascript -e 'display dialog "✅ 已关闭全局保活（恢复系统默认）！" buttons {"OK"}'

# ======================
# 3. 查看保活状态
# ======================
elif [[ $CHOICE == *"查看保活状态"* ]]; then

if [ "$(sudo defaults read NSGlobalDomain NSAppSleepDisabled 2>/dev/null)" = "1" ]; then
    STATUS="全局保活已开启（App Nap 已禁用）"
else
    STATUS="全局保活未开启（系统默认，后台可能被休眠降速）"
fi

osascript -e "display dialog \"当前状态：$STATUS\" buttons {\"OK\"}"

fi

exit 0
