#!/bin/bash

# ==============================
# 硬盘隐藏工具（macOS，chflags 方案）
# 功能：打/删隐藏属性（图标级）、登记回挂硬盘、安装/卸载回挂服务
# 原理：chflags hidden 写卷根 inode 属性（APFS/HFS+），随盘持久——
#       系统挂载那一刻起 Finder 就不显示桌面图标（无闪现窗口）；
#       登记的盘被卸载后，守护进程按 UUID 自动挂回（标志自动生效，
#       无需重挂、无需改挂载选项，也就无需登录触发链）
# 流程：先弹菜单 → 🔒打属性=chflags hidden；🔓删属性=chflags nohidden；
#       ✅选盘=取 UUID 写配置（名称|UUID）；❌删登记=从配置移除；
#       🚀安装=装回挂服务；🗑卸载=删服务及所有生成文件
# 说明：图形界面（菜单/选卷）用静态中文 heredoc 走 stdin（从未乱码）；
#       卷名列表经环境变量传入（卷名为英文时安全）；
#       含中文变量的结果/错误输出一律走终端 printf（终端显示一直正常）。
#       勿用 osascript -e / do shell script / 文件参数传中文，实测均乱码
# ==============================

export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8

CHOICE_FILE="/tmp/.hide-disk-choice"

# 自动提权：非 root 运行时自动以 sudo 重新执行本脚本（密码在终端窗口输入，无需手动 sudo）
if [ $UID -ne 0 ]; then
    printf '\n需要管理员权限，正在自动提权，请在下方输入管理员密码...\n\n'
    exec sudo /bin/bash "$0"
fi

clear

# 自报版本指纹：字节数对不上说明传的是旧文件
printf '脚本字节数：%s\n' "$(wc -c < "$0" | tr -d ' ')"

# 自动识别外置（USB/雷雳等）磁盘的已挂载卷，多个时 GUI 选择
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
set options to {"🔒 打上隐藏属性（藏桌面图标）", "🔓 删除隐藏属性（恢复图标）", "✅ 选择回挂硬盘（登记进配置）", "❌ 删除回挂硬盘（从配置移除）", "🚀 安装服务（事件驱动回挂）", "🗑 卸载服务（删除所有生成文件）"}
choose from list options with title "硬盘隐藏工具" with prompt "请选择操作：" default items {item 1 of options}
EOF
CHOICE=$(cat "$CHOICE_FILE")
rm -f "$CHOICE_FILE"

if [ -z "$CHOICE" ] || [ "$CHOICE" = "false" ]; then
    exit 0
fi

# ======================
# 卸载服务（无需盘在场：删服务 + 所有本脚本生成的文件）
# ======================
if printf '%s' "$CHOICE" | grep -q '卸载服务'; then

DAEMON_SCRIPT="/Library/HideDisk/hide-disk-remount.sh"
DAEMON_PLIST="/Library/LaunchDaemons/com.user.hide-disk.plist"
CONF_FILE="/Library/HideDisk/hide-disk.conf"

# 停服务并删除所有生成文件（守护服务、回挂脚本、配置）
launchctl bootout system/com.user.hide-disk 2>/dev/null
launchctl unload -w "$DAEMON_PLIST" 2>/dev/null
# 旧版（nobrowse 方案）的登录触发器残留：一并停掉删除
[ -n "$SUDO_UID" ] && launchctl bootout "gui/$SUDO_UID/com.user.hide-disk-login" 2>/dev/null
rm -f "$DAEMON_PLIST" "$DAEMON_SCRIPT" "$CONF_FILE"
rm -f "/Library/LaunchAgents/com.user.hide-disk-login.plist" "/Library/LaunchAgents/com.user.hide-disk-loginwindow.plist" /tmp/.hide-disk-login
# /Library/HideDisk 若已空则删除（rmdir 只删空目录）
rmdir /Library/HideDisk 2>/dev/null

printf '\n✅ 已卸载回挂服务，并删除所有生成文件！\n'
printf '   已删：服务（LaunchDaemon）、回挂脚本、配置、旧版登录触发器\n'
printf '   卷上的隐藏属性不受影响（如需恢复图标请用「🔓 删除隐藏属性」）\n'
exit 0
fi

# ======================
# 安装服务（LaunchDaemon）：只装服务；登记盘请用「✅ 选择回挂硬盘」
# ======================
if printf '%s' "$CHOICE" | grep -q '安装服务'; then

DAEMON_SCRIPT="/Library/HideDisk/hide-disk-remount.sh"
DAEMON_PLIST="/Library/LaunchDaemons/com.user.hide-disk.plist"

# 生成回挂脚本：静态（引号 heredoc 按字节原样写入、遍历配置文件，无写死值），
# 幂等 + 事件驱动（配合 plist 的 WatchPaths 监听 /Volumes：只在挂载/卸载
# 事件时被拉起，零轮询；开机竞态按真实挂载态判定，退避重试最长约 10 秒）
# 注释用中文不影响执行：bash 不解析注释内容，字节损坏也只坏注释不坏逻辑
mkdir -p /Library/HideDisk
cat > "$DAEMON_SCRIPT" <<'DAEMON'
#!/bin/bash
# 按 UUID 回挂登记卷（幂等、事件驱动）。由 hide-disk-v3.sh 生成
# 图标隐藏靠卷上持久的 hidden 标志（chflags）：挂回来的卷标志自动
# 生效，本脚本只负责回挂，无需重挂、无需改挂载选项
# 配置格式：名称|UUID（一行一卷，本脚本只用 UUID 字段）
CONF="/Library/HideDisk/hide-disk.conf"
[ -f "$CONF" ] || exit 0

# 开机/挂载竞态：WatchPaths 可能早于系统挂载完成就触发。退避重试
# 3 轮（间隔 4/6 秒，最长约 10 秒）；所有登记卷都挂上后才提前退出
n=0
while [ $n -lt 3 ]; do
    PENDING=0
    while IFS='|' read -r LABEL VUUID; do
        # 清洗隐形字符与脏字节（UUID 只含十六进制与连字符）
        VUUID=$(printf '%s' "$VUUID" | LC_ALL=C tr -dc '0-9A-Fa-f-')
        [ -n "$VUUID" ] || continue
        INFO=$(diskutil info "$VUUID" 2>/dev/null)
        # 设备查不到（整盘推出/拔出）：谁也无法自动挂回，
        # 跳过等重插（重插时 /Volumes 变动会再次唤醒本进程）
        [ -n "$INFO" ] || continue
        MOUNTED=$(echo "$INFO" | awk -F': *' '/Mounted:/{print $2}' | LC_ALL=C tr -dc 'A-Za-z')
        # 已挂载（幂等）：不动——图标显隐由卷上 hidden 标志自管
        [ "$MOUNTED" = "Yes" ] && continue
        # 未挂载但设备在线（被卸载）：按 UUID 查设备挂回
        DEV=$(echo "$INFO" | awk -F': *' '/Device Node/{print $2}')
        [ -n "$DEV" ] && diskutil mount "$DEV" >/dev/null 2>&1
        # 回挂后以真实挂载态验证：失败（登录竞态等）标记待重试，不静默放过
        MOUNTED=$(diskutil info "$VUUID" 2>/dev/null | awk -F': *' '/Mounted:/{print $2}' | LC_ALL=C tr -dc 'A-Za-z')
        [ "$MOUNTED" = "Yes" ] || PENDING=1
    done < "$CONF"
    [ "$PENDING" = "0" ] && exit 0
    n=$((n + 1))
    # 退避间隔 4/6 秒；最后一轮失败不再空等直接退出
    [ $n -lt 3 ] && sleep $((n * 2 + 2))
done
exit 0
DAEMON

# LaunchDaemon 配置（静态 XML，纯 ASCII）：开机跑 + 监听 /Volumes（零轮询）
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
    </array>
</dict>
</plist>
PLIST

chown root:wheel "$DAEMON_SCRIPT" "$DAEMON_PLIST"
chmod 755 "$DAEMON_SCRIPT"
chmod 644 "$DAEMON_PLIST"

# 清理旧版（nobrowse 方案）的登录触发器：chflags 方案无需登录触发，
# 从旧版换装时顺带移除，避免残留 Agent 无谓地唤醒本服务
[ -n "$SUDO_UID" ] && launchctl bootout "gui/$SUDO_UID/com.user.hide-disk-login" 2>/dev/null
rm -f "/Library/LaunchAgents/com.user.hide-disk-login.plist" "/Library/LaunchAgents/com.user.hide-disk-loginwindow.plist" /tmp/.hide-disk-login

# 已装旧版时先停掉再装新版（bootstrap 对已加载服务会报错）
launchctl bootout system/com.user.hide-disk 2>/dev/null
# 新版 launchctl 用 bootstrap，旧版回退 load
launchctl bootstrap system "$DAEMON_PLIST" 2>/dev/null || launchctl load -w "$DAEMON_PLIST"

printf '\n✅ 回挂服务已安装（LaunchDaemon）！\n'
printf '   开机跑 + 监听 /Volumes 事件（零轮询，不占性能）：登记的盘被卸载会自动挂回\n'
printf '   图标显隐由卷上 hidden 标志自管（🔒/🔓），挂回即生效、无闪现窗口\n'
printf '   登记盘请用「✅ 选择回挂硬盘」；移除登记用「❌ 删除回挂硬盘」\n'
exit 0
fi

# ======================
# 删除回挂硬盘（从配置移除指定盘的登记，不要求盘在场）
# ======================
if printf '%s' "$CHOICE" | grep -q '删除回挂硬盘'; then

CONF_FILE="/Library/HideDisk/hide-disk.conf"
if [ ! -s "$CONF_FILE" ]; then
    printf '\n回挂配置中无登记的盘，无需删除\n'
    exit 0
fi

# 从配置选盘：GUI 列表显示硬盘名称（多条时选择，一条自动选中）
CONF_COUNT=$(wc -l < "$CONF_FILE" | tr -d ' ')
if [ "$CONF_COUNT" -gt 1 ]; then
    export VOL_ITEMS="$(cut -d'|' -f1 "$CONF_FILE")"
    osascript > "$CHOICE_FILE" 2>/dev/null <<'EOF'
set volList to paragraphs of (system attribute "VOL_ITEMS")
choose from list volList with title "选择盘" with prompt "选择要从回挂配置中移除的盘："
EOF
    VOL_LABEL=$(cat "$CHOICE_FILE")
    rm -f "$CHOICE_FILE"
    if [ -z "$VOL_LABEL" ] || [ "$VOL_LABEL" = "false" ]; then
        exit 0
    fi
else
    VOL_LABEL=$(cut -d'|' -f1 "$CONF_FILE")
fi

# 按名称取该盘 UUID，再按 UUID 精确移除该行
UUID=$(awk -F'|' -v l="$VOL_LABEL" '$1 == l {print $2}' "$CONF_FILE" | LC_ALL=C tr -dc '0-9A-Fa-f-')
if [ -z "$UUID" ]; then
    printf '\n❌ 配置中未找到「%s」\n' "$VOL_LABEL"
    exit 1
fi
awk -v u="$UUID" -F'|' '$2 != u' "$CONF_FILE" > "$CONF_FILE.tmp"
mv "$CONF_FILE.tmp" "$CONF_FILE"

printf '\n✅ 已从回挂配置移除「%s」（UUID=%s）！\n' "$VOL_LABEL" "$UUID"
printf '   服务不再回挂该盘；盘上的隐藏属性不受影响\n'
exit 0
fi

# ======================
# 打上隐藏属性（chflags hidden：图标级隐藏，随盘持久；盘必须在场）
# ======================
if printf '%s' "$CHOICE" | grep -q '打上隐藏属性'; then

# 标志只能打在挂载着的卷根上：先选盘（多卷时 GUI 列表选择，单卷自动）
if ! FindVolume; then
    printf '\n❌ 未找到外置磁盘卷，请先插入 USB 硬盘！\n'
    exit 1
fi
printf '\n当前操作卷：%s\n' "$VOL_LABEL"

# hidden 标志存文件系统元数据（APFS/HFS+），随盘持久：系统挂载那一刻起
# Finder 就不显示桌面图标（无「先闪现几秒」问题）；只管桌面图标，
# Finder 侧边栏仍显示
if chflags hidden "$MOUNT_POINT"; then
    # Finder 只在「挂载那一刻/自身启动时」评估卷图标显隐；对已挂载的卷
    # 改标志，桌面不会自动刷新——重启 Finder 让它重新评估（闪一下自动恢复）
    killall Finder 2>/dev/null
    printf '\n✅ 「%s」已打上隐藏属性，桌面图标已消失！\n' "$VOL_LABEL"
else
    printf '\n❌ 打标志失败（exFAT/FAT32 卷不支持 BSD 标志）\n'
fi

# 验证：权限列后应出现 hidden 字样（ls -O 显示文件标志）
echo "—— 验证结果 ——"
ls -lOd "$MOUNT_POINT"
exit 0
fi

# ======================
# 删除隐藏属性（chflags nohidden：恢复桌面图标；盘必须在场）
# ======================
if printf '%s' "$CHOICE" | grep -q '删除隐藏属性'; then

if ! FindVolume; then
    printf '\n❌ 未找到外置磁盘卷，请先插入 USB 硬盘！\n'
    exit 1
fi
printf '\n当前操作卷：%s\n' "$VOL_LABEL"

# 清除 hidden 标志恢复桌面图标（标志打在卷根，清除同样须盘在场）
if chflags nohidden "$MOUNT_POINT"; then
    # 同上：清除标志后重启 Finder，桌面图标才会立即回来
    killall Finder 2>/dev/null
    printf '\n✅ 「%s」已删除隐藏属性，桌面图标已恢复！\n' "$VOL_LABEL"
else
    printf '\n❌ 清除标志失败\n'
fi

echo "—— 验证结果 ——"
ls -lOd "$MOUNT_POINT"
exit 0
fi

# ======================
# 选择回挂硬盘（取 UUID 写入配置，名称|UUID；盘必须在场）
# ======================
if printf '%s' "$CHOICE" | grep -q '选择回挂硬盘'; then

if ! FindVolume; then
    printf '\n❌ 未找到外置磁盘卷，请先插入 USB 硬盘！\n'
    exit 1
fi
printf '\n当前操作卷：%s\n' "$VOL_LABEL"

# 读取卷 UUID：新版 macOS 的 diskutil 会在值两侧包不可见 Unicode 字符
# （终端显示为 ??，直接用会写坏配置）；tr 必须加 LC_ALL=C：UTF-8
# locale 下 tr 按排序展开字符集，多字节隐形字符会漏网（即 ?? 的根因）
UUID=$(diskutil info "$MOUNT_POINT" | awk '/Volume UUID/{print $NF}' | LC_ALL=C tr -dc '0-9A-Fa-f-')

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

printf '检测到硬盘：UUID=%s\n' "$UUID"

# 写入回挂配置（名称|UUID 一行一条；同 UUID 去重，改名一并刷新）
mkdir -p /Library/HideDisk
CONF_FILE="/Library/HideDisk/hide-disk.conf"
touch "$CONF_FILE"
awk -v u="$UUID" -F'|' '$2 != u' "$CONF_FILE" > "$CONF_FILE.tmp" 2>/dev/null
echo "$VOL_LABEL|$UUID" >> "$CONF_FILE.tmp"
mv "$CONF_FILE.tmp" "$CONF_FILE"
chown root:wheel "$CONF_FILE"
chmod 644 "$CONF_FILE"

printf '\n✅ 已登记「%s」（UUID=%s）进回挂配置！\n' "$VOL_LABEL" "$UUID"
printf '   服务安装后：盘被卸载会自动挂回；图标显隐由「🔒/🔓 属性」独立管理\n'

# 未装服务时提醒
if [ ! -f /Library/LaunchDaemons/com.user.hide-disk.plist ]; then
    printf '\n⚠️ 回挂服务未安装，登记暂不生效\n'
    printf '   请选「🚀 安装服务（事件驱动回挂）」\n'
fi
exit 0
fi

exit 0
