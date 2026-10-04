#!/bin/bash

# ==============================
# MuMu 模拟器保活工具（macOS）
# 功能：禁用/恢复 App Nap（后台休眠）、查看状态
# 原理：NSAppSleepDisabled 写入应用偏好域，
#       阻止 macOS 在后台冻结/降速模拟器
# 流程：自动查找 MuMu 应用 → 读取 bundle ID → 写入设置
# 注意：修改后需完全退出并重新打开应用才生效
# 说明：图形菜单用静态中文 heredoc 走 stdin（原先菜单的写法，从未乱码）；
#       含变量的结果/错误输出一律走终端 printf（终端显示一直正常）。
#       勿用 osascript -e / 环境变量 / do shell script 传中文变量，实测均乱码
# ==============================

export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8

LIST_FILE="/tmp/.mumu-keepalive-list"
CHOICE_FILE="/tmp/.mumu-keepalive-choice"

if [ $UID -ne 0 ]; then
    echo "需要管理员权限，请重新运行：sudo $0"
    exit 1
fi

clear

# 查找所有 MuMu 应用并逐个读取 bundle ID（不再选择，全部处理）
# 注意：应用名可能带空格（如 MuMuPlayer Pro.app），必须按行遍历，不能按空格切分
FindMumu() {
    APP_LIST=$(ls -d /Applications/*[Mm][Uu][Mm][Uu]*.app 2>/dev/null)
    [ -z "$APP_LIST" ] && return 1

    printf '%s\n' "$APP_LIST" > "$LIST_FILE"
    BUNDLE_IDS=""
    while IFS= read -r APP_PATH; do
        BUNDLE_ID=""
        if [ -f "$APP_PATH/Contents/Info.plist" ]; then
            BUNDLE_ID=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$APP_PATH/Contents/Info.plist" 2>/dev/null)
        fi
        [ -n "$BUNDLE_ID" ] && BUNDLE_IDS="$BUNDLE_IDS$BUNDLE_ID "
    done < "$LIST_FILE"
    rm -f "$LIST_FILE"

    [ -n "$BUNDLE_IDS" ]
}

# 图形菜单（静态中文，原先菜单的原样写法）
osascript > "$CHOICE_FILE" <<'EOF'
set options to {"🔋 一键开启保活（禁用App Nap）", "🔓 一键关闭保活", "👀 查看保活状态"}
choose from list options with title "MuMu 模拟器保活工具" with prompt "选择一个操作：" default items {item 1 of options}
EOF
CHOICE=$(cat "$CHOICE_FILE")
rm -f "$CHOICE_FILE"

if [ -z "$CHOICE" ] || [ "$CHOICE" = "false" ]; then
    exit 0
fi

# 定位应用：找不到则退出
if ! FindMumu; then
    printf '\n❌ 未在 /Applications 找到 MuMu 相关应用！\n'
    exit 1
fi

# ======================
# 1. 开启保活（禁用 App Nap）
# ======================
if [[ $CHOICE == *"开启保活"* ]]; then

for BUNDLE_ID in $BUNDLE_IDS; do
    sudo defaults write "$BUNDLE_ID" NSAppSleepDisabled -bool YES
done

COUNT=$(echo $BUNDLE_IDS | wc -w | tr -d ' ')
IDS=$(echo "$BUNDLE_IDS" | sed 's/ $//; s/ /、/g')

printf '\n✅ 已为所有 MuMu 应用开启保活（App Nap 已禁用）！\n\n共 %d 个应用：%s\n\n注意：需完全退出并重新打开应用后生效。\n' "$COUNT" "$IDS"

# ======================
# 2. 关闭保活（恢复默认）
# ======================
elif [[ $CHOICE == *"关闭保活"* ]]; then

for BUNDLE_ID in $BUNDLE_IDS; do
    sudo defaults delete "$BUNDLE_ID" NSAppSleepDisabled 2>/dev/null
done

printf '\n✅ 已关闭所有 MuMu 应用保活（恢复系统默认）！\n'

# ======================
# 3. 查看保活状态
# ======================
elif [[ $CHOICE == *"查看保活状态"* ]]; then

printf '\n各应用保活状态：\n'
for BUNDLE_ID in $BUNDLE_IDS; do
    if [ "$(sudo defaults read "$BUNDLE_ID" NSAppSleepDisabled 2>/dev/null)" = "1" ]; then
        STATUS="保活已开启"
    else
        STATUS="保活未开启"
    fi
    printf '  %s：%s\n' "$BUNDLE_ID" "$STATUS"
done

fi

exit 0
