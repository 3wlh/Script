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

# 查找所有 MuMu 应用并逐个读取 bundle ID（不再选择，全部处理）
FindMumu() {
    APP_LIST=$(ls -d /Applications/*[Mm][Uu][Mm][Uu]*.app 2>/dev/null)
    [ -z "$APP_LIST" ] && return 1

    BUNDLE_IDS=""
    for APP_PATH in $APP_LIST; do
        BUNDLE_ID=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$APP_PATH/Contents/Info.plist" 2>/dev/null)
        if [ -n "$BUNDLE_ID" ]; then
            BUNDLE_IDS="$BUNDLE_IDS$BUNDLE_ID "
        fi
    done

    [ -n "$BUNDLE_IDS" ]
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
    osascript -e 'display dialog "❌ 未在 /Applications 找到 MuMu 相关应用！" buttons {"OK"}'
    exit 1
fi

# ======================
# 1. 开启保活（禁用 App Nap）
# ======================
if [[ $CHOICE == *"开启保活"* ]]; then

for BUNDLE_ID in $BUNDLE_IDS; do
    sudo defaults write "$BUNDLE_ID" NSAppSleepDisabled -bool YES
done

osascript -e "display dialog (\"✅ 已为所有 MuMu 应用开启保活（App Nap 已禁用）！\" & return & return & \"共 $(echo $BUNDLE_IDS | wc -w | tr -d ' ') 个应用：$(echo $BUNDLE_IDS | sed 's/ $//; s/ /、/g')\" & return & return & \"注意：需完全退出并重新打开应用后生效。\") buttons {\"OK\"}"

# ======================
# 2. 关闭保活（恢复默认）
# ======================
elif [[ $CHOICE == *"关闭保活"* ]]; then

for BUNDLE_ID in $BUNDLE_IDS; do
    sudo defaults delete "$BUNDLE_ID" NSAppSleepDisabled 2>/dev/null
done

osascript -e 'display dialog "✅ 已关闭所有 MuMu 应用保活（恢复系统默认）！" buttons {"OK"}'

# ======================
# 3. 查看保活状态
# ======================
elif [[ $CHOICE == *"查看保活状态"* ]]; then

LINES=""
for BUNDLE_ID in $BUNDLE_IDS; do
    if [ "$(sudo defaults read "$BUNDLE_ID" NSAppSleepDisabled 2>/dev/null)" = "1" ]; then
        STATUS="保活已开启"
    else
        STATUS="保活未开启"
    fi
    LINES="$LINES\"$BUNDLE_ID：$STATUS\" & return & "
done
LINES=${LINES% & return & }

osascript -e "display dialog \"各应用保活状态：\" & return & return & $LINES buttons {\"OK\"}"

fi

exit 0
