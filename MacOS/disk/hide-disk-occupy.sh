#!/bin/bash

# ==============================
# 缓存盘隐藏工具（macOS）
# 功能：隐藏/恢复缓存盘显示、查看挂载状态、开机自动隐藏
# 原理：以 nobrowse 选项重新挂载，卷不再出现在桌面/Finder，
#       用户目录放符号链接作为入口（链接无「推出」按钮）；
#       已隐藏的卷由看门进程占住 cwd——单卷盘整盘推出后系统无法自动挂回，
#       用看门进程让访达「推出」直接失败，从根上防误推（拔线不受影响）；
#       开机持久化用 LaunchDaemon 开机重挂 + 监听 /Volumes 事件，
#       登录时由 LaunchAgent 再触发一次
# 流程：先弹菜单 → 🔒隐藏=当场隐藏+登记进配置；🔓恢复=从配置移除+恢复显示；
#       👀状态=遍历配置所有盘；🚀安装=只装服务；🗑卸载=删服务及所有生成文件
# 说明：图形界面（菜单/选卷）用静态中文 heredoc 走 stdin（从未乱码）；
#       卷名列表经环境变量传入（卷名为英文时安全）；
#       含中文变量的结果/错误输出一律走终端 printf（终端显示一直正常）。
#       勿用 osascript -e / do shell script / 文件参数传中文，实测均乱码
# ==============================

export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8

CHOICE_FILE="/tmp/.hide-disk-choice"

if [ $UID -ne 0 ]; then
    echo "需要管理员权限，请重新运行：sudo $0"
    exit 1
fi

clear

# 自报版本指纹：字节数对不上说明传的是旧文件
printf '脚本字节数：%s（最新版为 21575+）\n' "$(wc -c < "$0" | tr -d ' ')"

# sudo 运行时 $HOME 是 /var/root，入口快捷方式需建到实际用户目录下
# dscl 输出的路径同样被隐形 Unicode 字符包裹（终端显示为 ??，导致链接建到
# 无效路径），tr 只保留可打印 ASCII（\40-\176）；必须 LC_ALL=C，否则
# UTF-8 locale 下 tr 按排序展开字符集，隐形字符会漏网
if [ -n "$SUDO_USER" ]; then
    USER_HOME=$(dscl . -read "/Users/$SUDO_USER" NFSHomeDirectory 2>/dev/null | awk '{print $2}' | LC_ALL=C tr -cd '\40-\176')
    [ -d "$USER_HOME" ] || USER_HOME="/Users/$SUDO_USER"
fi
USER_HOME=${USER_HOME:-$HOME}

# 自动识别外置（USB/雷雳等）磁盘的已挂载卷，多个时终端列表选择
FindVolume() {
    VOL_CANDIDATES=""
    for MP in /Volumes/*; do
        [ -d "$MP" ] || continue
        INFO=$(diskutil info "$MP" 2>/dev/null)
        INTERNAL=$(echo "$INFO" | awk -F': *' '/Internal:/{print $2}')
        PROTOCOL=$(echo "$INFO" | awk -F': *' '/Protocol:/{print $2}')
        # 只保留外置磁盘的卷：Internal 为 No，或协议为 USB/雷雳/火线
        if [ "$INTERNAL" = "No" ] || [[ "$PROTOCOL" == USB || "$PROTOCOL" == Thunderbolt* || "$PROTOCOL" == FireWire* ]]; then
            VOL_CANDIDATES="$VOL_CANDIDATES$(basename "$MP")
"
        fi
    done

    [ -z "$VOL_CANDIDATES" ] && return 1

    # 去掉末尾换行：拼接时每项带换行、echo 又补一个，wc -l 会多数一行
    VOL_CANDIDATES=$(printf '%s' "$VOL_CANDIDATES")

    COUNT=$(echo "$VOL_CANDIDATES" | wc -l | tr -d ' ')
    if [ "$COUNT" -gt 1 ]; then
        # 多卷时 GUI 选择：静态中文走引号 heredoc（与菜单同通道，不乱码），
        # 卷名列表经环境变量传入（卷名为英文时显示正常）
        export VOL_ITEMS="$(echo "$VOL_CANDIDATES")"
        osascript > "$CHOICE_FILE" 2>/dev/null <<'EOF'
set volList to paragraphs of (system attribute "VOL_ITEMS")
choose from list volList with title "选择卷" with prompt "找到多个外置磁盘卷，请选择要操作的卷："
EOF
        VOL_LABEL=$(cat "$CHOICE_FILE")
        rm -f "$CHOICE_FILE"
        if [ -z "$VOL_LABEL" ] || [ "$VOL_LABEL" = "false" ]; then
            return 1
        fi
    else
        VOL_LABEL=$(echo "$VOL_CANDIDATES")
    fi

    MOUNT_POINT="/Volumes/$VOL_LABEL"
    [ -d "$MOUNT_POINT" ]
}

# 图形菜单（静态中文 heredoc 走 stdin，从未乱码）——先选操作，再按需选盘
osascript > "$CHOICE_FILE" <<'EOF'
set options to {"🔒 一键隐藏缓存盘（nobrowse 挂载）", "🔓 一键恢复显示（默认挂载）", "👀 查看挂载状态", "🚀 安装开机自动隐藏（LaunchDaemon）", "🗑 卸载开机自动隐藏"}
choose from list options with title "缓存盘隐藏工具" with prompt "请选择操作：" default items {item 1 of options}
EOF
CHOICE=$(cat "$CHOICE_FILE")
rm -f "$CHOICE_FILE"

if [ -z "$CHOICE" ] || [ "$CHOICE" = "false" ]; then
    exit 0
fi

# ======================
# 卸载开机自动隐藏（无需盘在场：删服务 + 所有本脚本生成的文件）
# ======================
if printf '%s' "$CHOICE" | grep -q '卸载开机自动隐藏'; then

DAEMON_SCRIPT="/Library/HideDisk/hide-disk-remount.sh"
DAEMON_PLIST="/Library/LaunchDaemons/com.user.hide-disk.plist"
CONF_FILE="/Library/HideDisk/hide-disk.conf"

# 按配置清理各盘的用户目录入口链接
if [ -s "$CONF_FILE" ]; then
    while IFS='|' read -r LABEL VUUID; do
        [ -n "$LABEL" ] || continue
        LINK="$USER_HOME/$LABEL"
        [ -L "$LINK" ] && rm -f "$LINK"
    done < "$CONF_FILE"
fi

# 停服务并删除所有生成文件（守护服务、登录触发 Agent、重挂脚本、配置）
pkill -f "HideDiskKeep /Volumes/" 2>/dev/null
launchctl bootout system/com.user.hide-disk 2>/dev/null
launchctl unload -w "$DAEMON_PLIST" 2>/dev/null
[ -n "$SUDO_UID" ] && launchctl bootout "gui/$SUDO_UID/com.user.hide-disk-login" 2>/dev/null
rm -f "$DAEMON_PLIST" "/Library/LaunchAgents/com.user.hide-disk-login.plist" /tmp/.hide-disk-login
rm -f "$DAEMON_SCRIPT" "$CONF_FILE"
# /Library/HideDisk 若为本脚本创建且已空则删除（rmdir 只删空目录，安全）
rmdir /Library/HideDisk 2>/dev/null

printf '\n✅ 已卸载开机自动隐藏，并删除所有生成文件！\n'
printf '   已删：服务（LaunchDaemon）、登录触发器（LaunchAgent）、重挂脚本、配置、用户目录入口链接\n'
printf '   当前会话的挂载状态不受影响（如需恢复显示请重挂）\n'
exit 0
fi

# ======================
# 恢复显示（读配置文件选卷，不要求盘在场：拔掉的盘也能从隐藏机制移除）
# ======================
if printf '%s' "$CHOICE" | grep -q '恢复显示'; then

CONF_FILE="/Library/HideDisk/hide-disk.conf"
if [ ! -s "$CONF_FILE" ]; then
    printf '\n配置中无登记的盘，无需恢复\n'
    exit 0
fi

# 从配置选卷（多条时 GUI 列表选择，一条自动选中）
CONF_COUNT=$(wc -l < "$CONF_FILE" | tr -d ' ')
if [ "$CONF_COUNT" -gt 1 ]; then
    export VOL_ITEMS="$(cut -d'|' -f1 "$CONF_FILE")"
    osascript > "$CHOICE_FILE" 2>/dev/null <<'EOF'
set volList to paragraphs of (system attribute "VOL_ITEMS")
choose from list volList with title "选择卷" with prompt "选择要从隐藏机制中移除的卷："
EOF
    VOL_LABEL=$(cat "$CHOICE_FILE")
    rm -f "$CHOICE_FILE"
    if [ -z "$VOL_LABEL" ] || [ "$VOL_LABEL" = "false" ]; then
        exit 0
    fi
else
    VOL_LABEL=$(cut -d'|' -f1 "$CONF_FILE")
fi

# 从配置行取该卷 UUID（格式 LABEL|UUID）
UUID=$(awk -F'|' -v l="$VOL_LABEL" '$1 == l {print $2}' "$CONF_FILE" | LC_ALL=C tr -dc '0-9A-Fa-f-')
if [ -z "$UUID" ]; then
    printf '\n❌ 配置中未找到「%s」\n' "$VOL_LABEL"
    exit 1
fi

# 从配置移除该卷
awk -v u="$UUID" -F'|' '$2 != u' "$CONF_FILE" > "$CONF_FILE.tmp"
mv "$CONF_FILE.tmp" "$CONF_FILE"

MOUNT_POINT="/Volumes/$VOL_LABEL"
pkill -f "HideDiskKeep $MOUNT_POINT" 2>/dev/null

# 盘在场且 UUID 相符：恢复默认挂载；否则仅移除记录
REAL_UUID=$(diskutil info "$MOUNT_POINT" 2>/dev/null | awk '/Volume UUID/{print $NF}' | LC_ALL=C tr -dc '0-9A-Fa-f-')
if [ -d "$MOUNT_POINT" ] && [ "$REAL_UUID" = "$UUID" ]; then
    # 恢复默认（可浏览）挂载（当前 nobrowse 才需要重挂）
    if mount | grep " on $MOUNT_POINT (" | grep -q nobrowse; then
        DEV=$(diskutil info "$MOUNT_POINT" | awk -F': *' '/Device Node/{print $2}')
        sudo diskutil unmount "$MOUNT_POINT"
        sudo diskutil mount "$DEV"
        REMOUNT_MSG="已恢复默认挂载"
    else
        REMOUNT_MSG="当前已可显示，无需重挂"
    fi
    # 移除用户目录快捷入口
    USER_LINK="$USER_HOME/$VOL_LABEL"
    if [ -L "$USER_LINK" ]; then
        rm "$USER_LINK"
        LINK_MSG="已移除用户目录快捷方式"
    else
        LINK_MSG="无快捷方式，跳过"
    fi
    printf '\n✅ 已从开机自动隐藏移除「%s」，盘已恢复显示！\n\n%s\n%s\n' "$VOL_LABEL" "$REMOUNT_MSG" "$LINK_MSG"
else
    printf '\n✅ 已从开机自动隐藏移除「%s」（盘当前不在场，插入后即正常显示）\n' "$VOL_LABEL"
fi
exit 0
fi

# ======================
# 查看挂载状态（遍历配置文件：盘在则报状态，不在则提示）
# ======================
if printf '%s' "$CHOICE" | grep -q '查看挂载状态'; then

CONF_FILE="/Library/HideDisk/hide-disk.conf"
if [ ! -f /Library/LaunchDaemons/com.user.hide-disk.plist ]; then
    printf '\n开机自动隐藏未安装，无监控的盘\n'
    exit 0
fi
if [ ! -s "$CONF_FILE" ]; then
    printf '\n开机自动隐藏已安装，但配置中无登记的盘\n'
    exit 0
fi

printf '\n—— 监控的盘 ——\n'
while IFS='|' read -r LABEL VUUID; do
    [ -n "$LABEL" ] || continue
    MP="/Volumes/$LABEL"
    if [ ! -d "$MP" ]; then
        printf '\n「%s」盘不存在（未插入）\n' "$LABEL"
        continue
    fi
    REAL_UUID=$(diskutil info "$MP" 2>/dev/null | awk '/Volume UUID/{print $NF}' | LC_ALL=C tr -dc '0-9A-Fa-f-')
    if [ "$REAL_UUID" != "$VUUID" ]; then
        printf '\n「%s」盘名被其他卷占用（UUID 不符，未监控）\n' "$LABEL"
        continue
    fi
    if mount | grep " on $MP (" | grep -q nobrowse; then
        STATUS="已隐藏（nobrowse，不出现在桌面/Finder）"
    else
        STATUS="⚠️ 正常显示（未被隐藏）"
    fi
    printf '\n「%s」当前状态：%s\n' "$LABEL" "$STATUS"
    mount | grep " on $MP ("
done < "$CONF_FILE"
exit 0
fi

# ======================
# 安装开机自动隐藏（LaunchDaemon）：只装服务；登记盘请用「🔒 隐藏」
# ======================
if printf '%s' "$CHOICE" | grep -q '安装开机自动隐藏'; then

DAEMON_SCRIPT="/Library/HideDisk/hide-disk-remount.sh"
DAEMON_PLIST="/Library/LaunchDaemons/com.user.hide-disk.plist"

# 生成重挂脚本：纯 ASCII、静态（遍历配置文件，无写死值），幂等 + 事件驱动
# （配合 plist 的 WatchPaths 监听 /Volumes：只在挂载/卸载事件时被拉起，零轮询；
#   开机/挂载竞态与 unmount 被占用时按真实挂载态判定，最长重试约 6 秒）
mkdir -p /Library/HideDisk
cat > "$DAEMON_SCRIPT" <<'DAEMON'
#!/bin/bash
# Re-mount volumes with nobrowse (idempotent, event-driven). Generated by hide-disk.sh
CONF="/Library/HideDisk/hide-disk.conf"
[ -f "$CONF" ] || exit 0

# Keep the login-trigger file present and user-writable (/tmp is wiped at
# boot); the LaunchAgent touches it at each login to wake this daemon up.
touch /tmp/.hide-disk-login 2>/dev/null && chmod 666 /tmp/.hide-disk-login 2>/dev/null

# Boot races: WatchPaths may fire before mounts finish, and diskutil unmount
# can fail while Spotlight still holds the fresh volume. Retry up to ~6s;
# exit early only when every present+matched volume is confirmed nobrowse.
n=0
while [ $n -lt 3 ]; do
    PENDING=0
    while IFS='|' read -r LABEL VUUID; do
        [ -n "$LABEL" ] || continue
        MP="/Volumes/$LABEL"
        if [ ! -d "$MP" ]; then
            # unmounted but device still attached (unmount, not whole-disk
            # eject): mount it back hidden. Whole-disk eject detaches the
            # device; nothing can auto-remount that, replug re-triggers us.
            DEV=$(diskutil info "$VUUID" 2>/dev/null | awk -F': *' '/Device Node/{print $2}')
            [ -n "$DEV" ] && diskutil mount -mountOptions nobrowse "$DEV" >/dev/null 2>&1
            # device gone (eject/unplug): kill the keeper right away via this
            # /Volumes-watch trigger; don't wait for its 30-min self-check
            [ -d "$MP" ] || { pkill -f "HideDiskKeep $MP" 2>/dev/null; continue; }
        fi
        U=$(diskutil info "$MP" 2>/dev/null | awk '/Volume UUID/{print $NF}' | LC_ALL=C tr -dc '0-9A-Fa-f-')
        [ "$U" = "$VUUID" ] || continue
        if mount | grep " on $MP (" | grep -q nobrowse; then
            # anti-eject keeper: a process with cwd inside the volume makes
            # Finder "Eject" fail loudly. Event-managed by this daemon
            # (/Volumes-watch: pkill + respawn, so a stale keeper from a
            # fast unplug/replug is always replaced); the keeper also re-cds
            # every 30min as a cheap fallback (48 syscalls/day, zero CPU).
            pkill -f "HideDiskKeep $MP" 2>/dev/null
            nohup bash -c 'while :; do cd "$1" 2>/dev/null || exit; sleep 1800; done' HideDiskKeep "$MP" >/dev/null 2>&1 </dev/null &
            continue
        fi
        DEV=$(diskutil info "$MP" | awk -F': *' '/Device Node/{print $2}')
        pkill -f "HideDiskKeep $MP" 2>/dev/null
        diskutil unmount "$MP" >/dev/null 2>&1
        diskutil mount -mountOptions nobrowse "$DEV" >/dev/null 2>&1
        # verify the real mount state: busy unmount must not count as success
        mount | grep " on $MP (" | grep -q nobrowse || PENDING=1
    done < "$CONF"
    [ "$PENDING" = "0" ] && exit 0
    sleep 2
    n=$((n + 1))
done
exit 0
DAEMON

# LaunchDaemon 配置（静态 XML，纯 ASCII）：开机跑 + 监听 /Volumes 及登录触发文件（零轮询）
cat > "$DAEMON_PLIST" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.hide-disk</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>/Library/HideDisk/hide-disk-remount.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>WatchPaths</key>
    <array>
        <string>/Volumes</string>
        <string>/tmp/.hide-disk-login</string>
    </array>
</dict>
</plist>
PLIST

chown root:wheel "$DAEMON_SCRIPT" "$DAEMON_PLIST"
chmod 755 "$DAEMON_SCRIPT"
chmod 644 "$DAEMON_PLIST"
# 触发文件需先于守护服务存在且可被普通用户 touch（/tmp 开机会被清空）
touch /tmp/.hide-disk-login && chmod 666 /tmp/.hide-disk-login

# 已装旧版时先停掉再装新版（bootstrap 对已加载服务会报错）
launchctl bootout system/com.user.hide-disk 2>/dev/null
# 新版 launchctl 用 bootstrap，旧版回退 load
launchctl bootstrap system "$DAEMON_PLIST" 2>/dev/null || launchctl load -w "$DAEMON_PLIST"

# 登录触发器（LaunchAgent）：任意用户登录成功即 touch 触发文件，
# 唤醒上面的 LaunchDaemon 再隐藏一轮（Agent 无 root，不能直接重挂，走事件触发）
AGENT_PLIST="/Library/LaunchAgents/com.user.hide-disk-login.plist"
cat > "$AGENT_PLIST" <<'AGENT'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.hide-disk-login</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/touch</string>
        <string>/tmp/.hide-disk-login</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
AGENT
chown root:wheel "$AGENT_PLIST"
chmod 644 "$AGENT_PLIST"
# Agent 每次登录自动加载；当前已登录会话立即生效（失败不影响下次登录）
[ -n "$SUDO_UID" ] && launchctl bootout "gui/$SUDO_UID/com.user.hide-disk-login" 2>/dev/null
[ -n "$SUDO_UID" ] && launchctl bootstrap "gui/$SUDO_UID" "$AGENT_PLIST" 2>/dev/null

printf '\n✅ 开机自动隐藏服务已安装（LaunchDaemon + 登录触发）！\n'
printf '   开机监听 /Volumes 事件，用户登录时也会再触发一次隐藏（零轮询，不占性能）\n'
printf '   登记盘请用「🔒 一键隐藏缓存盘」；移除登记用「🔓 一键恢复显示」\n'
exit 0
fi

# 隐藏是唯一需要盘在场的操作：现在选盘（多卷时 GUI 列表选择，单卷自动跳过）
if ! FindVolume; then
    printf '\n❌ 未找到外置磁盘卷，请先插入 USB 硬盘！\n'
    exit 1
fi
printf '\n当前操作卷：%s\n' "$VOL_LABEL"

# 卷名取证：含非可打印 ASCII 字符时现形原始字节（排查 ??），正常时无输出
if printf '%s' "$VOL_LABEL" | LC_ALL=C grep -q '[^ -~]'; then
    printf '\n⚠️ 卷名含非 ASCII 字符，原始字节：\n'
    printf '%s' "$VOL_LABEL" | od -c | head -2
fi

USER_LINK="$USER_HOME/$VOL_LABEL"

# 读取卷 UUID（各分支共用）
# 新版 macOS 的 diskutil 会在值两侧包不可见 Unicode 字符（终端显示为 ??，
# 直接用会写坏配置）；tr 必须加 LC_ALL=C：UTF-8
# locale 下 tr 按排序展开字符集，多字节隐形字符会漏网（即 ?? 的根因）
UUID=$(diskutil info "$MOUNT_POINT" | awk '/Volume UUID/{print $NF}' | LC_ALL=C tr -dc '0-9A-Fa-f-')

# 判断当前挂载是否带 nobrowse：读 mount 输出
# （新版 macOS 的 diskutil info 已无 Browsable 字段，旧检测读到空值会误判）
IsNoBrowse() {
    mount | grep " on $MOUNT_POINT (" | grep -q nobrowse
}

# 防推出看门进程：cwd 落在卷内会让访达「推出」失败（弹“正在使用”）。
# 单卷盘整盘弹出后系统层面无法自动挂回，只能靠这个防误推。
# 看门双层回收：主路径是守护进程监听 /Volumes——盘消失当场 pkill、
# 盘在场时 pkill 旧看门再拉新的（防快速拔插后旧看门占着死文件系统）；
# 兜底是看门每 30 分钟重新 cd 自检一次——进程挂起零 CPU、每天 48 次
# 系统调用可忽略，卷没了自退、拔后速插能重锚 cwd，防守护服务丢失后变孤儿。
# 有意拔盘：走「🔓 恢复显示」或直接拔线
StartKeeper() {
    pkill -f "HideDiskKeep $MOUNT_POINT" 2>/dev/null
    nohup bash -c 'while :; do cd "$1" 2>/dev/null || exit; sleep 1800; done' HideDiskKeep "$MOUNT_POINT" >/dev/null 2>&1 </dev/null &
}

# ======================
# 隐藏缓存盘（nobrowse 重挂 + 用户目录入口）
# ======================
# 菜单匹配用 grep：bash 3.2 解析 [[ == *"中文"* ]] 这类带引号模式会报 EOF 错
if printf '%s' "$CHOICE" | grep -q '隐藏缓存盘'; then

if [ -z "$UUID" ]; then
    printf '\n❌ 未取到卷 UUID！\n'
    exit 1
fi
# UUID 形状校验：应为 36 位十六进制；异常时现形原始字节（排查 ??）
if ! printf '%s' "$UUID" | grep -qE '^[0-9A-F-]{36}$'; then
    printf '\n❌ UUID 异常（%s 字节），原始字节：\n' "$(printf '%s' "$UUID" | wc -c | tr -d ' ')"
    printf '%s' "$UUID" | od -c | head -2
    printf 'diskutil 原始行：\n'
    diskutil info "$MOUNT_POINT" | grep 'Volume UUID' | od -c | head -4
    exit 1
fi

printf '检测到缓存盘：UUID=%s\n' "$UUID"

# 写入开机自动隐藏配置（登记本盘；同 UUID 更新条目，改名一并刷新）
mkdir -p /Library/HideDisk
CONF_FILE="/Library/HideDisk/hide-disk.conf"
touch "$CONF_FILE"
awk -v u="$UUID" -F'|' '$2 != u' "$CONF_FILE" > "$CONF_FILE.tmp" 2>/dev/null
echo "$VOL_LABEL|$UUID" >> "$CONF_FILE.tmp"
mv "$CONF_FILE.tmp" "$CONF_FILE"
chown root:wheel "$CONF_FILE"
chmod 644 "$CONF_FILE"

# 立即以 nobrowse 重新挂载（已是则跳过）；unmount 被占用时不误报成功
if ! IsNoBrowse; then
    DEV=$(diskutil info "$MOUNT_POINT" | awk -F': *' '/Device Node/{print $2}')
    pkill -f "HideDiskKeep $MOUNT_POINT" 2>/dev/null
    if sudo diskutil unmount "$MOUNT_POINT"; then
        sudo diskutil mount -mountOptions nobrowse "$DEV"
        if IsNoBrowse; then
            REMOUNT_MSG="已以 nobrowse 重新挂载"
        else
            REMOUNT_MSG="⚠️ 重挂后验证未通过（仍非 nobrowse），请重跑本工具"
        fi
    else
        REMOUNT_MSG="⚠️ 卸载失败（卷被 Spotlight 等占用），本次未隐藏，请稍后重试"
    fi
else
    REMOUNT_MSG="当前已是 nobrowse，无需重挂"
fi

# 用户目录快捷入口（无推出按钮）
if [ -e "$USER_LINK" ]; then
    LINK_MSG="用户目录入口已存在：$USER_LINK"
else
    ln -s "$MOUNT_POINT" "$USER_LINK"
    LINK_MSG="已创建用户目录入口：$USER_LINK（可拖到 Finder 侧边栏）"
fi

# 验证（mount 行里的 nobrowse 即隐藏生效的直接证据）
echo "—— 验证结果 ——"
diskutil info "$MOUNT_POINT" | grep -E "Mounted|Mount Point"
# mount 行里的 nobrowse 即隐藏生效的直接证据
mount | grep " on $MOUNT_POINT ("

if IsNoBrowse; then
    StartKeeper
    KEEPER_MSG="防推出保护已开启：访达误点「推出」会失败，移除请走「🔓 恢复显示」或直接拔线"
else
    KEEPER_MSG="⚠️ 防推出保护未开启（挂载状态异常，请重跑本工具）"
fi
printf '\n✅ 缓存盘「%s」已隐藏！\n\n%s\n%s\n%s\n%s\n' "$VOL_LABEL" "$REMOUNT_MSG" "$LINK_MSG" "$KEEPER_MSG" "已登记进开机自动隐藏配置（服务安装后开机生效）"

# 未装 LaunchDaemon 时提醒：重启后隐藏不生效
if [ ! -f /Library/LaunchDaemons/com.user.hide-disk.plist ]; then
    printf '\n⚠️ 开机自动隐藏未安装，重启后访达会重新显示本卷\n'
    printf '   请选「🚀 安装开机自动隐藏（LaunchDaemon）」\n'
fi

fi

exit 0
