#!/bin/bash

# ==============================
# 系统更新屏蔽工具（macOS，终端菜单版）
# 支持：macOS 12+ / 13+ / 14+ / 15 / 26 Tahoe
# 功能：屏蔽更新 / 恢复更新 / 清除小红点 /
#       只屏蔽大版本（无限期 / 描述文件90天 两种方式可叠加）
# Tahoe 增强说明：
#   - hosts 屏蔽 appldnld.apple.com（旧下载通道兜底）
#   - MobileAsset 更新目录重定向（挡住系统设置手动检查）
#   - 大版本屏蔽双方案：MajorOSUserNotificationDate（无限期）
#     + forceDelayedMajorSoftwareUpdate 描述文件（90天）
# 菜单：终端数字键操作（无 GUI 弹窗），执行完按任意键返回主菜单
# ==============================
RED='\033[0;31m'
GRN='\033[0;32m'
BLU='\033[0;34m'
YEL='\033[0;33m'
NC='\033[0m'

# 自动提权：非 root 运行时自动以 sudo 重新执行本脚本（密码在终端窗口输入，无需手动 sudo）
if [ $UID -ne 0 ]; then
    printf '\n需要管理员权限，正在自动提权，请在下方输入管理员密码...\n\n'
    exec sudo /bin/bash "$0"
fi

# 清空 hosts 中本工具写入的屏蔽条目（兼容旧版脚本残留，可重复执行）
CleanHosts() {
    sudo sed -i '' -E '/^127\.0\.0\.1[[:space:]]+(swscan|swdist|swcdn|swdownload|gdmf|mesu|xp|appldnld)\.apple\.com$/d; /^127\.0\.0\.1[[:space:]]+updates(-http)?\.cdn-apple\.com$/d; /屏蔽macOS/d' /etc/hosts
}

# ======================
# 1) 屏蔽所有系统更新（含 Tahoe 增强）
# ======================
DoBlockAll() {
    echo "正在关闭自动更新..."
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool FALSE
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool FALSE
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool FALSE
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall -bool FALSE
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool FALSE
    sudo softwareupdate --schedule off

    sudo launchctl disable system/com.apple.softwareupdated
    sudo killall -9 softwareupdated 2>/dev/null

    # MobileAsset 目录重定向：资产受众指向 seed 通道 + 指向无效目录
    # （macOS 26 上打开系统设置手动检查更新也会因此失败）
    sudo defaults write com.apple.MobileAsset MobileAssetAssetAudience -string "92897351-9c90-4132-84a8-2c4b3b5fced5"
    sudo defaults write com.apple.MobileAsset MobileAssetServerURL-com.apple.MobileAsset.SoftwareUpdate -string "https://swscan.apple.com/content/catalogs/others/index-seed-26-15-14-13-12-10.16-10.15-10.14-10.13-10.12-10.11-10.10-10.9-mountainlion-lion-snowleopard-leopard.merged-1.sucatalog.gz"
    sudo killall -HUP mobileassetd 2>/dev/null
    sudo killall -HUP betaenrollmentd 2>/dev/null

    # 写入 hosts（先清旧条目再追加，保证可重复执行）
    CleanHosts
    sudo tee -a /etc/hosts <<'EOF'

# 屏蔽macOS系统更新服务器
127.0.0.1 swscan.apple.com
127.0.0.1 swdist.apple.com
127.0.0.1 swcdn.apple.com
127.0.0.1 gdmf.apple.com
127.0.0.1 mesu.apple.com
127.0.0.1 xp.apple.com
127.0.0.1 swdownload.apple.com
127.0.0.1 appldnld.apple.com
127.0.0.1 updates-http.cdn-apple.com
127.0.0.1 updates.cdn-apple.com
EOF

    sudo dscacheutil -flushcache
    sudo killall -HUP mDNSResponder
    sudo rm -rf /Library/Updates/*

    printf '\n%b\n' "${GRN}✅ 所有系统更新已屏蔽（含 macOS 26 增强）！${NC}"
    return 0
}

# ======================
# 2) 恢复系统更新（手动安装模式）
# ======================
DoRestore() {
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool TRUE
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool TRUE
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool FALSE
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall -bool FALSE
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool FALSE
    sudo softwareupdate --schedule on

    sudo launchctl enable system/com.apple.softwareupdated
    sudo launchctl start com.apple.softwareupdated

    # 还原 MobileAsset 配置（删除键 = 回到系统默认）
    sudo defaults delete com.apple.MobileAsset MobileAssetAssetAudience 2>/dev/null
    sudo defaults delete com.apple.MobileAsset MobileAssetServerURL-com.apple.MobileAsset.SoftwareUpdate 2>/dev/null
    sudo killall -HUP mobileassetd 2>/dev/null
    sudo killall -HUP betaenrollmentd 2>/dev/null

    # 还原大版本提醒日期
    sudo defaults delete /Library/Preferences/com.apple.SoftwareUpdate MajorOSUserNotificationDate 2>/dev/null

    # 彻底清空 hosts 屏蔽条目（含旧版脚本残留）
    CleanHosts
    sudo dscacheutil -flushcache
    sudo killall -HUP mDNSResponder

    printf '\n%b\n' "${GRN}✅ 系统更新已恢复（手动安装模式）！${NC}"
    printf '   更新会自动检查和下载，但不会自动安装，需手动确认；安全响应同样改为手动\n'
    printf '   如安装过「推迟大版本描述文件」，请到 系统设置 > 隐私与安全性 > 描述文件 中删除\n'
    return 0
}

# ======================
# 3) 清除更新小红点
# ======================
DoClearBadge() {
    sudo killall -9 softwareupdated System\ Settings Dock NotificationCenter 2>/dev/null

    sudo rm -rf ~/Library/Caches/com.apple.preferences.softwareupdate
    sudo rm -rf /Library/Caches/com.apple.softwareupdate
    sudo rm -rf /private/var/db/com.apple.softwareupdate
    sudo rm -rf ~/Library/Preferences/com.apple.SoftwareUpdate.plist

    defaults write com.apple.systempreferences AttentionPrefBundleIDs 0
    killall Dock

    printf '\n%b\n' "${GRN}✅ 小红点已清除！如仍显示请重启电脑${NC}"
    return 0
}

# ======================
# 4) 只屏蔽大版本，保留安全更新（无限期）
# ======================
DoBlockMajor() {
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool TRUE
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool TRUE
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool FALSE
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall -bool TRUE
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool TRUE
    sudo softwareupdate --schedule on

    # 大版本升级提醒推迟到 2099 年（无 90 天限制）
    sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate MajorOSUserNotificationDate -date "2099-01-01 00:00:00"
    sudo killall -9 softwareupdated 2>/dev/null

    CleanHosts
    sudo dscacheutil -flushcache
    sudo killall -HUP mDNSResponder

    printf '\n%b\n' "${GRN}✅ 已设置：仅屏蔽大版本，保留安全更新（无限期）${NC}"
    printf '   注意：大版本提醒已推迟到 2099 年；尽量少手动打开「软件更新」页面，避免系统重置该日期\n'
    printf '   如需更彻底，可再选「5) 安装大版本推迟描述文件」，两种方式可叠加\n'
    return 0
}

# ======================
# 5) 安装大版本推迟描述文件（最长 90 天）
# ======================
DoDeferProfile() {
    PROFILE="/tmp/defer-major-update.mobileconfig"
    UUID_PAYLOAD=$(uuidgen)
    UUID_ROOT=$(uuidgen)

    cat > "$PROFILE" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>PayloadContent</key>
	<array>
		<dict>
			<key>PayloadType</key>
			<string>com.apple.applicationaccess</string>
			<key>PayloadIdentifier</key>
			<string>local.update-blocker.defer-major</string>
			<key>PayloadUUID</key>
			<string>$UUID_PAYLOAD</string>
			<key>PayloadVersion</key>
			<integer>1</integer>
			<key>forceDelayedMajorSoftwareUpdate</key>
			<true/>
		</dict>
	</array>
	<key>PayloadDisplayName</key>
	<string>推迟大版本更新（90天）</string>
	<key>PayloadDescription</key>
	<string>推迟 macOS 大版本升级提示，最长 90 天，到期重新安装。</string>
	<key>PayloadIdentifier</key>
	<string>local.update-blocker.defer-major</string>
	<key>PayloadRemovalDisallowed</key>
	<false/>
	<key>PayloadScope</key>
	<string>System</string>
	<key>PayloadType</key>
	<string>Configuration</string>
	<key>PayloadUUID</key>
	<string>$UUID_ROOT</string>
	<key>PayloadVersion</key>
	<integer>1</integer>
</dict>
</plist>
EOF

    open "$PROFILE"

    printf '\n%b\n' "${GRN}✅ 描述文件已生成并打开！${NC}"
    printf '   请在 系统设置 > 隐私与安全性 > 描述文件 中点击「安装」\n'
    printf '   注意：最长有效 90 天，到期后重新运行本工具；卸载也在同一位置\n'
    return 0
}

# ======================
# 主菜单（终端数字键操作，执行完按任意键返回）
# ======================
while true; do
    clear
    echo ""
    echo "================================"
    echo -e "  ${BLU}系统更新屏蔽工具${NC}"
    echo "================================"
    echo ""
    echo "  1) 🔒 屏蔽所有系统更新"
    echo "  2) 🔓 恢复系统更新（手动安装）"
    echo "  3) 🧹 清除更新小红点"
    echo "  4) ⚙️ 只屏蔽大版本（保留安全更新，无限期）"
    echo "  5) 🛡️ 安装大版本推迟描述文件（90天）"
    echo "  0) 退出"
    echo ""
    read -n 1 -p "请直接按下数字键 (0-5): " choice </dev/tty || break
    echo ""
    case "$choice" in
        1) DoBlockAll ;;
        2) DoRestore ;;
        3) DoClearBadge ;;
        4) DoBlockMajor ;;
        5) DoDeferProfile ;;
        0|q) echo ""; echo "再见！"; break ;;
        "") printf '%b\n' "${RED}未输入任何内容，请输入数字 0-5！${NC}" ;;
        *) printf '%b\n' "${RED}错误的选项：${choice}，请输入数字 0-5！${NC}" ;;
    esac
    echo ""
    read -n 1 -s -p "按任意键返回主菜单..." _KEY </dev/tty || break
    echo ""
done
