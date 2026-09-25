#!/bin/bash

# ==============================
# MuMu 模拟器保活工具（macOS）
# 功能：禁用/恢复 App Nap（后台休眠）、查看状态
# 原理：NSAppSleepDisabled 写入应用偏好域，
#       阻止 macOS 在后台冻结/降速模拟器
# 流程：自动查找 MuMu 应用 → 读取 bundle ID → 写入设置
# 注意：修改后需完全退出并重新打开应用才生效
# ==============================

if [ $UID -ne 0 ]; then
    echo "需要管理员权限，请重新运行：sudo $0"
    exit 1
fi

clear

# 查找 MuMu 应用并读取 bundle ID（多个匹配时弹窗选择）
FindMumu() {
    APP_LIST=$(ls -d /Applications/*[Mm][Uu][Mm][Uu]*.app 2>/dev/null)
    if [ -z "$APP_LIST" ]; then
        return 1
    fi

    COUNT=$(echo "$APP_LIST" | wc -l | tr -d ' ')
    if [ "$COUNT" -gt 1 ]; then
        APP_ITEMS=$(echo "$APP_LIST" | sed 's/.*/"&"/' | tr '\n' ',' | sed 's/,$//')
        APP_PATH=$(osascript 2>/dev/null <<EOF
choose from list {$APP_ITEMS} with title "选择应用" with prompt "找到多个 MuMu 相关应用，请选择："
EOF
)
        if [ -z "$APP_PATH" ] || [ "$APP_PATH" = "false" ]; then
            return 1
        fi
    else
        APP_PATH=$APP_LIST
    fi

    APP_NAME=$(basename "$APP_PATH" .app)
    BUNDLE_ID=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$APP_PATH/Contents/Info.plist" 2>/dev/null)
    [ -n "$BUNDLE_ID" ]
}

# 图形菜单
CHOICE=$(osascript <<'EOF'
set options to {"🔋 一键开启保活（禁用App Nap）", "🔓 一键关闭保活", "👀 查看保活状态"}
choose from list options with title "MuMu 模拟器保活工具" with prompt "选择一个操作：" default items {"🔋 一键开启保活（禁用App Nap）"}
EOF
)

if [ "$CHOICE" = "false" ]; then
    exit 0
fi

# 定位应用：找不到或取消则退出
if ! FindMumu; then
    osascript <<'EOF'
display dialog "❌ 未在 /Applications 找到 MuMu 相关应用！" buttons {"OK"}
EOF
    exit 1
fi

# ======================
# 1. 开启保活（禁用 App Nap）
# ======================
if [[ $CHOICE == *"开启保活"* ]]; then

sudo defaults write "$BUNDLE_ID" NSAppSleepDisabled -bool YES

osascript <<EOF
display dialog ("✅ 已为「$APP_NAME」开启保活（App Nap 已禁用）！" & return & return & "Bundle ID：$BUNDLE_ID" & return & return & "注意：需完全退出并重新打开应用后生效。") buttons {"OK"}
EOF

# ======================
# 2. 关闭保活（恢复默认）
# ======================
elif [[ $CHOICE == *"关闭保活"* ]]; then

sudo defaults delete "$BUNDLE_ID" NSAppSleepDisabled 2>/dev/null

osascript <<EOF
display dialog "✅ 已关闭「$APP_NAME」保活（恢复系统默认）！" buttons {"OK"}
EOF

# ======================
# 3. 查看保活状态
# ======================
elif [[ $CHOICE == *"查看保活状态"* ]]; then

if [ "$(sudo defaults read "$BUNDLE_ID" NSAppSleepDisabled 2>/dev/null)" = "1" ]; then
    STATUS="保活已开启（App Nap 已禁用）"
else
    STATUS="保活未开启（系统默认，后台可能被休眠降速）"
fi

osascript <<EOF
display dialog "「$APP_NAME」当前状态：$STATUS" buttons {"OK"}
EOF

fi

exit 0
