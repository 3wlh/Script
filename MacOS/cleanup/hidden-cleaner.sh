#!/bin/bash

# ==============================
# macOS 隐藏文件屏蔽工具
# 功能：禁止/恢复在网络盘和U盘生成 .DS_Store
# 说明：系统只提供 DSDontWriteNetworkStores /
#       DSDontWriteUSBStores 两个开关，仅对网络盘
#       和U盘有效，内置硬盘无法禁止
# ==============================

if [ $UID -ne 0 ]; then
    echo "需要管理员权限，请重新运行：sudo $0"
    exit 1
fi

clear

# 当前登录用户（defaults 必须写入用户域，写到 root 域无效）
USER_NAME=$(stat -f %Su /dev/console)

# 图形菜单
CHOICE=$(osascript <<'EOF'
set options to {"🔒 一键禁止生成隐藏文件（网络盘+U盘）", "🔓 一键恢复默认（允许生成）"}
choose from list options with title "macOS 隐藏文件屏蔽工具" with prompt "选择一个操作：" default items {"🔒 一键禁止生成隐藏文件（网络盘+U盘）"}
EOF
)

if [ "$CHOICE" = "false" ]; then
    exit 0
fi

# ======================
# 1. 禁止生成（网络盘 + U盘）
# ======================
if [[ $CHOICE == *"禁止生成隐藏文件"* ]]; then

sudo -u "$USER_NAME" defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool TRUE
sudo -u "$USER_NAME" defaults write com.apple.desktopservices DSDontWriteUSBStores -bool TRUE
sudo -u "$USER_NAME" killall Finder 2>/dev/null

osascript -e 'display dialog "✅ 已禁止在网络盘和U盘生成 .DS_Store（Finder 已重启生效）！注意：内置硬盘上的 .DS_Store 是系统固有行为，无法禁止。" buttons {"OK"}'

# ======================
# 2. 恢复默认
# ======================
elif [[ $CHOICE == *"恢复默认"* ]]; then

sudo -u "$USER_NAME" defaults delete com.apple.desktopservices DSDontWriteNetworkStores 2>/dev/null
sudo -u "$USER_NAME" defaults delete com.apple.desktopservices DSDontWriteUSBStores 2>/dev/null
sudo -u "$USER_NAME" killall Finder 2>/dev/null

osascript -e 'display dialog "✅ 已恢复默认设置！" buttons {"OK"}'

fi

exit 0
