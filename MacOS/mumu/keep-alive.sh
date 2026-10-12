#!/bin/bash

# ==============================
# MuMu 模拟器保活工具（macOS，终端菜单版）
# 功能：禁用/恢复 App Nap（后台休眠）、查看状态
# 原理：NSAppSleepDisabled 写入应用偏好域，
#       阻止 macOS 在后台冻结/降速模拟器
# 流程：自动查找全部 MuMu 应用 → 读取 bundle ID → 统一写入设置
# 注意：修改后需完全退出并重新打开应用才生效
# 菜单：终端数字键操作（无 GUI 弹窗），执行完按任意键返回主菜单
# ==============================
RED='\033[0;31m'
GRN='\033[0;32m'
BLU='\033[0;34m'
YEL='\033[0;33m'
NC='\033[0m'

if [ $UID -ne 0 ]; then
    printf '\n需要管理员权限，请运行：sudo %s\n\n' "$0"
    exit 1
fi

LIST_FILE="/tmp/.mumu-keepalive-list"

# 查找所有 MuMu 应用并逐个读取 bundle ID（全部处理，无需选择）
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

# ======================
# 1) 开启保活（禁用 App Nap）
# ======================
DoEnable() {
    if ! FindMumu; then
        printf '\n%b\n' "${RED}❌ 未在 /Applications 找到 MuMu 相关应用！${NC}"
        return 1
    fi

    for BUNDLE_ID in $BUNDLE_IDS; do
        sudo defaults write "$BUNDLE_ID" NSAppSleepDisabled -bool YES
    done

    COUNT=$(echo $BUNDLE_IDS | wc -w | tr -d ' ')
    IDS=$(echo "$BUNDLE_IDS" | sed 's/ $//; s/ /、/g')

    printf '\n%b\n' "${GRN}✅ 已为所有 MuMu 应用开启保活（App Nap 已禁用）！${NC}"
    printf '共 %d 个应用：%s\n' "$COUNT" "$IDS"
    printf '注意：需完全退出并重新打开应用后生效\n'
    return 0
}

# ======================
# 2) 关闭保活（恢复默认）
# ======================
DoDisable() {
    if ! FindMumu; then
        printf '\n%b\n' "${RED}❌ 未在 /Applications 找到 MuMu 相关应用！${NC}"
        return 1
    fi

    for BUNDLE_ID in $BUNDLE_IDS; do
        sudo defaults delete "$BUNDLE_ID" NSAppSleepDisabled 2>/dev/null
    done

    printf '\n%b\n' "${GRN}✅ 已关闭所有 MuMu 应用保活（恢复系统默认）！${NC}"
    return 0
}

# ======================
# 3) 查看保活状态
# ======================
DoStatus() {
    if ! FindMumu; then
        printf '\n%b\n' "${RED}❌ 未在 /Applications 找到 MuMu 相关应用！${NC}"
        return 1
    fi

    printf '\n各应用保活状态：\n'
    for BUNDLE_ID in $BUNDLE_IDS; do
        if [ "$(sudo defaults read "$BUNDLE_ID" NSAppSleepDisabled 2>/dev/null)" = "1" ]; then
            STATUS="保活已开启"
        else
            STATUS="保活未开启"
        fi
        printf '  %s：%s\n' "$BUNDLE_ID" "$STATUS"
    done
    return 0
}

# ======================
# 主菜单（终端数字键操作，执行完按任意键返回）
# ======================
while true; do
    clear
    echo ""
    echo "===================================================="
    echo -e "  ${BLU}MuMu 模拟器保活工具${NC}"
    echo "===================================================="
    echo ""
    echo "  1) 🔋 开启保活（禁用App Nap）"
    echo "  2) 🔓 关闭保活（恢复默认）"
    echo "  3) 👀 查看保活状态"
    echo "  0) 退出"
    echo ""
    read -n 1 -p "请直接按下数字键 (0-3): " choice </dev/tty || break
    echo ""
    case "$choice" in
        1) DoEnable ;;
        2) DoDisable ;;
        3) DoStatus ;;
        0|q) echo ""; echo "再见！"; break ;;
        "") printf '%b\n' "${RED}未输入任何内容，请输入数字 0-3！${NC}" ;;
        *) printf '%b\n' "${RED}错误的选项：${choice}，请输入数字 0-3！${NC}" ;;
    esac
    echo ""
    read -n 1 -s -p "按任意键返回主菜单..." _KEY </dev/tty || break
    echo ""
done
