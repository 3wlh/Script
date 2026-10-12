#!/bin/bash

# ==============================
# 硬盘隐藏工具（macOS，chflags 方案，终端菜单版）
# 功能：打/删隐藏属性（图标级）、登记回挂硬盘、安装/卸载回挂服务
# 原理：chflags hidden 写卷根 inode 属性（APFS/HFS+），随盘持久——
#       系统挂载那一刻起 Finder 就不显示桌面图标（无闪现窗口）；
#       Finder 只在挂载/自身启动时评估卷图标显隐，对已挂载的卷改
#       标志不自动刷新桌面，打/删属性后须重启 Finder（脚本自动做）；
#       登记的盘被卸载后，守护进程按 UUID 自动挂回（标志自动生效，
#       无需重挂、无需改挂载选项，也就无需登录触发链）
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

# 脚本版本号：每次修改脚本更新此值（格式：日期_时分秒），运行时对版本就知道跑的是哪一版
SCRIPT_VERSION="26-10-12_220012"

# 编号选择：选项经管道传入（一行一个），列出后读编号；
# 选中项存入 PICK_RESULT，取消（0）或列表为空返回 1。
# 交互 read 必须显式读 /dev/tty——stdin 已被选项管道占用
PickItem() {
    PICK_RESULT=""
    PICK_LIST=""
    local i=1 ITEM NUM MAX=0
    while IFS= read -r ITEM; do
        [ -n "$ITEM" ] || continue
        printf '  %d) %s\n' "$i" "$ITEM"
        PICK_LIST="$PICK_LIST$ITEM
"
        i=$((i + 1))
        MAX=$((MAX + 1))
    done
    [ "$MAX" -ge 1 ] || return 1
    while true; do
        read -r -p "请输入编号 (1-$MAX)（0=取消）: " NUM </dev/tty || return 1
        case "$NUM" in
            0) return 1 ;;
            ''|*[!0-9]*) printf '请输入数字编号！\n' ;;
            *)
                if [ "$NUM" -le "$MAX" ]; then
                    PICK_RESULT=$(printf '%s\n' "$PICK_LIST" | sed -n "${NUM}p")
                    return 0
                fi
                printf '编号超出范围！\n' ;;
        esac
    done
}

# 自动识别外置（USB/雷雳等）磁盘的已挂载卷，多个时编号选择
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
        printf '\n找到多个外置磁盘卷：\n'
        if ! PickItem < <(printf '%s\n' "$VOL_CANDIDATES"); then
            return 1
        fi
        VOL_LABEL="$PICK_RESULT"
    else
        VOL_LABEL="$VOL_CANDIDATES"
    fi

    # 防御：卷名为空说明选择流程异常（变量丢失），绝不能对 /Volumes/ 本身操作
    if [ -z "$VOL_LABEL" ]; then
        printf '\n%b\n' "${RED}❌ 卷名为空（选择流程异常），已中止！${NC}"
        return 1
    fi
    MOUNT_POINT="/Volumes/$VOL_LABEL"
    [ -d "$MOUNT_POINT" ]
}

# ======================
# 1) 打上隐藏属性（chflags hidden：图标级隐藏，随盘持久；盘必须在场）
# ======================
DoLockAttr() {
    if ! FindVolume; then
        printf '\n❌ 未找到外置磁盘卷（或已取消），请先插入 USB 硬盘！\n'
        return 1
    fi
    printf '\n当前操作卷：%s\n' "$VOL_LABEL"

    # hidden 标志存文件系统元数据（APFS/HFS+），随盘持久：系统挂载那一刻起
    # Finder 就不显示桌面图标（无「先闪现几秒」问题）；只管桌面图标，
    # Finder 侧边栏仍显示
    if chflags hidden "$MOUNT_POINT"; then
        # Finder 只在「挂载那一刻/自身启动时」评估卷图标显隐；对已挂载的卷
        # 改标志，桌面不会自动刷新——重启 Finder 让它重新评估（闪一下自动恢复）
        killall Finder 2>/dev/null
        printf '\n%b\n' "${GRN}✅ 「${VOL_LABEL}」已打上隐藏属性，桌面图标已消失！${NC}"
    else
        printf '\n%b\n' "${RED}❌ 打标志失败（exFAT/FAT32 卷不支持 BSD 标志）${NC}"
        return 1
    fi

    # 验证：权限列后应出现 hidden 字样（ls -O 显示文件标志）
    echo "—— 验证结果 ——"
    ls -lOd "$MOUNT_POINT"
    return 0
}

# ======================
# 2) 删除隐藏属性（chflags nohidden：恢复桌面图标；盘必须在场）
# ======================
DoUnlockAttr() {
    if ! FindVolume; then
        printf '\n❌ 未找到外置磁盘卷（或已取消），请先插入 USB 硬盘！\n'
        return 1
    fi
    printf '\n当前操作卷：%s\n' "$VOL_LABEL"

    # 清除 hidden 标志恢复桌面图标（标志打在卷根，清除同样须盘在场）
    if chflags nohidden "$MOUNT_POINT"; then
        # 同上：清除标志后重启 Finder，桌面图标才会立即回来
        killall Finder 2>/dev/null
        printf '\n%b\n' "${GRN}✅ 「${VOL_LABEL}」已删除隐藏属性，桌面图标已恢复！${NC}"
    else
        printf '\n%b\n' "${RED}❌ 清除标志失败${NC}"
        return 1
    fi

    echo "—— 验证结果 ——"
    ls -lOd "$MOUNT_POINT"
    return 0
}

# ======================
# 3) 选择回挂硬盘（取 UUID 写入配置，名称|UUID；盘必须在场）
# ======================
DoSelectRemount() {
    if ! FindVolume; then
        printf '\n❌ 未找到外置磁盘卷（或已取消），请先插入 USB 硬盘！\n'
        return 1
    fi
    printf '\n当前操作卷：%s\n' "$VOL_LABEL"

    # 读取卷 UUID：新版 macOS 的 diskutil 会在值两侧包不可见 Unicode 字符
    # （终端显示为 ??，直接用会写坏配置）；tr 必须加 LC_ALL=C：UTF-8
    # locale 下 tr 按排序展开字符集，多字节隐形字符会漏网（即 ?? 的根因）
    UUID=$(diskutil info "$MOUNT_POINT" | awk '/Volume UUID/{print $NF}' | LC_ALL=C tr -dc '0-9A-Fa-f-')

    if [ -z "$UUID" ]; then
        printf '\n%b\n' "${RED}❌ 未取到卷 UUID！${NC}"
        return 1
    fi
    # UUID 形状校验：应为 36 位十六进制；异常时现形原始字节（排查 ??）
    if ! printf '%s' "$UUID" | grep -qE '^[0-9A-F-]{36}$'; then
        printf '\n❌ UUID 异常（%s 字节），原始字节：\n' "$(printf '%s' "$UUID" | wc -c | tr -d ' ')"
        printf '%s' "$UUID" | od -c | head -2
        printf 'diskutil 原始行：\n'
        diskutil info "$MOUNT_POINT" | grep 'Volume UUID' | od -c | head -4
        return 1
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

    printf '\n%b\n' "${GRN}✅ 已登记「${VOL_LABEL}」（UUID=${UUID}）进回挂配置！${NC}"
    printf '   服务安装后：盘被卸载会自动挂回；图标显隐由「1) / 2) 属性」独立管理\n'

    # 未装服务时提醒
    if [ ! -f /Library/LaunchDaemons/com.user.hide-disk.plist ]; then
        printf '\n%b\n' "${YEL}⚠️ 回挂服务未安装，登记暂不生效${NC}"
        printf '   请选「5) 安装服务（事件驱动回挂）」\n'
    fi
    return 0
}

# ======================
# 4) 删除回挂硬盘（从配置移除指定盘的登记，不要求盘在场）
# ======================
DoRemoveRemount() {
    CONF_FILE="/Library/HideDisk/hide-disk.conf"
    if [ ! -s "$CONF_FILE" ]; then
        printf '\n回挂配置中无登记的盘，无需删除\n'
        return 0
    fi

    CONF_COUNT=$(wc -l < "$CONF_FILE" | tr -d ' ')
    if [ "$CONF_COUNT" -gt 1 ]; then
        printf '\n回挂配置中的盘：\n'
        if ! PickItem < <(cut -d'|' -f1 "$CONF_FILE"); then
            return 0
        fi
        VOL_LABEL="$PICK_RESULT"
    else
        VOL_LABEL=$(cut -d'|' -f1 "$CONF_FILE")
    fi

    # 按名称取该盘 UUID，再按 UUID 精确移除该行
    UUID=$(awk -F'|' -v l="$VOL_LABEL" '$1 == l {print $2}' "$CONF_FILE" | LC_ALL=C tr -dc '0-9A-Fa-f-')
    if [ -z "$UUID" ]; then
        printf '\n%b\n' "${RED}❌ 配置中未找到「${VOL_LABEL}」${NC}"
        return 1
    fi
    awk -v u="$UUID" -F'|' '$2 != u' "$CONF_FILE" > "$CONF_FILE.tmp"
    mv "$CONF_FILE.tmp" "$CONF_FILE"

    printf '\n%b\n' "${GRN}✅ 已从回挂配置移除「${VOL_LABEL}」（UUID=${UUID}）！${NC}"
    printf '   服务不再回挂该盘；盘上的隐藏属性不受影响\n'
    return 0
}

# ======================
# 5) 安装服务（LaunchDaemon）：只装服务；登记盘请用「3) 选择回挂硬盘」
# ======================
DoInstallService() {
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

    printf '\n%b\n' "${GRN}✅ 回挂服务已安装（LaunchDaemon）！${NC}"
    printf '   开机跑 + 监听 /Volumes 事件（零轮询，不占性能）：登记的盘被卸载会自动挂回\n'
    printf '   图标显隐由卷上 hidden 标志自管，挂回即生效、无闪现窗口\n'
    printf '   登记盘请用「3) 选择回挂硬盘」；移除登记用「4) 删除回挂硬盘」\n'
    return 0
}

# ======================
# 6) 卸载服务（无需盘在场：删服务 + 所有本脚本生成的文件）
# ======================
DoUninstallService() {
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

    printf '\n%b\n' "${GRN}✅ 已卸载回挂服务，并删除所有生成文件！${NC}"
    printf '   已删：服务（LaunchDaemon）、回挂脚本、配置、旧版登录触发器\n'
    printf '   卷上的隐藏属性不受影响（如需恢复图标请用「2) 删除隐藏属性」）\n'
    return 0
}

# ======================
# 主菜单（终端数字键操作，执行完按任意键返回）
# ======================
while true; do
    clear
    echo ""
    echo "===================================================="
    echo -e "  ${BLU}硬盘隐藏工具V3 @ ${SCRIPT_VERSION}${NC}"
    echo "===================================================="
    echo ""
    echo "  1) 🔒 打上隐藏属性（藏桌面图标）"
    echo "  2) 🔓 删除隐藏属性（恢复图标）"
    echo "  3) ✅ 选择回挂硬盘（登记进配置）"
    echo "  4) ❌ 删除回挂硬盘（从配置移除）"
    echo "  5) 🚀 安装服务（事件驱动回挂）"
    echo "  6) 🗑 卸载服务（删除所有生成文件）"
    echo "  0) 退出"
    echo ""
    read -n 1 -p "请直接按下数字键 (0-6): " choice </dev/tty || break
    echo ""
    case "$choice" in
        1) DoLockAttr ;;
        2) DoUnlockAttr ;;
        3) DoSelectRemount ;;
        4) DoRemoveRemount ;;
        5) DoInstallService ;;
        6) DoUninstallService ;;
        0|q) echo ""; echo "再见！"; break ;;
        "") echo -e "${RED}未输入任何内容，请输入数字 0-6！${NC}" ;;
        *) echo -e "${RED}错误的选项：${choice}，请输入数字 0-6！${NC}" ;;
    esac
    echo ""
    read -n 1 -s -p "按任意键返回主菜单..." _KEY </dev/tty || break
    echo ""
done
