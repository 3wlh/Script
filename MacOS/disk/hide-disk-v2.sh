#!/bin/bash

# ==============================
# 硬盘隐藏工具（macOS，nobrowse + 属性开关，终端菜单版）
# 功能：隐藏/恢复挂载硬盘显示、查看挂载状态、开机自动隐藏、属性开关
# 原理：以 nobrowse 选项重新挂载，卷不再出现在桌面/Finder，
#       用户目录放符号链接作为入口（链接无「推出」按钮）；
#       卸载的卷由守护进程按 UUID 自动挂回（整盘推出后设备已分离，
#       需重新插拔，插回自动挂回并隐藏）；
#       开机持久化用 LaunchDaemon 开机重挂 + 监听 /Volumes 事件，
#       登录页出现时（LoginWindow 会话）与用户登录时由 LaunchAgent 再触发；
#       属性开关用 chflags hidden（图标级隐藏，随盘持久，只藏桌面图标、
#       Finder 侧边栏仍显示；Finder 不自动刷新已挂载卷的桌面图标，
#       打/删属性后脚本自动重启 Finder 使其立即生效）
# 流程：数字键选操作 → 隐藏=当场隐藏+登记进配置；恢复=从配置移除+恢复显示；
#       状态=遍历配置所有盘；打属性=图标级隐藏（需盘在场）；
#       删属性=恢复桌面图标（需盘在场）；安装=只装服务；卸载=删服务及所有生成文件
# 菜单：终端数字键操作（无 GUI 弹窗），执行完按任意键返回主菜单
# ==============================
RED='\033[0;31m'
GRN='\033[0;32m'
BLU='\033[0;34m'
YEL='\033[0;33m'
NC='\033[0m'

# 入口链接指向的卷内子目录名：MacOS=用户目录的盘符链接指向卷内 MacOS 文件夹；
# 留空、或卷内不存在该目录时，默认链接到卷根目录
LINK_SUBDIR="MacOS"

if [ $UID -ne 0 ]; then
    echo "需要管理员权限，请重新运行：sudo $0"
    exit 1
fi

# 脚本版本号：每次修改脚本更新此值（格式：日期_时分秒），运行时对版本就知道跑的是哪一版
SCRIPT_VERSION="26-10-12_231639"

# sudo 运行时 $HOME 是 /var/root，入口快捷方式需建到实际用户目录下
# dscl 输出的路径同样被隐形 Unicode 字符包裹（终端显示为 ??，导致链接建到
# 无效路径），tr 只保留可打印 ASCII（\40-\176）；必须 LC_ALL=C，否则
# UTF-8 locale 下 tr 按排序展开字符集，隐形字符会漏网
if [ -n "$SUDO_USER" ]; then
    USER_HOME=$(dscl . -read "/Users/$SUDO_USER" NFSHomeDirectory 2>/dev/null | awk '{print $2}' | LC_ALL=C tr -cd '\40-\176')
    [ -d "$USER_HOME" ] || USER_HOME="/Users/$SUDO_USER"
fi
USER_HOME=${USER_HOME:-$HOME}

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

# 判断当前挂载是否带 nobrowse：读 mount 输出
# （新版 macOS 的 diskutil info 已无 Browsable 字段，旧检测读到空值会误判）
IsNoBrowse() {
    mount | grep " on $MOUNT_POINT (" | grep -q nobrowse
}

# ======================
# 1) 隐藏挂载硬盘显示（nobrowse 重挂 + 用户目录入口；盘必须在场）
# ======================
DoHide() {
    # 隐藏是唯一需要盘在场的操作：先选盘（多卷时编号选择，单卷自动跳过）
    if ! FindVolume; then
        printf '\n❌ 未找到外置磁盘卷（或已取消），请先插入 USB 硬盘！\n'
        return 1
    fi
    printf '\n当前操作卷：%s\n' "$VOL_LABEL"

    # 卷名取证：含非可打印 ASCII 字符时现形原始字节（排查 ??），正常时无输出
    if printf '%s' "$VOL_LABEL" | LC_ALL=C grep -q '[^ -~]'; then
        printf '\n⚠️ 卷名含非 ASCII 字符，原始字节：\n'
        printf '%s' "$VOL_LABEL" | od -c | head -2
    fi

    USER_LINK="$USER_HOME/$VOL_LABEL"

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

    printf '检测到挂载硬盘：UUID=%s\n' "$UUID"

    # 写入开机自动隐藏配置（登记本盘；同 UUID 更新条目，改名一并刷新）
    mkdir -p /Library/HideDisk
    CONF_FILE="/Library/HideDisk/hide-disk.conf"
    touch "$CONF_FILE"
    awk -v u="$UUID" -F'|' '$2 != u' "$CONF_FILE" > "$CONF_FILE.tmp" 2>/dev/null
    echo "$VOL_LABEL|$UUID" >> "$CONF_FILE.tmp"
    mv "$CONF_FILE.tmp" "$CONF_FILE"
    chown root:wheel "$CONF_FILE"
    chmod 644 "$CONF_FILE"

    # 立即以 nobrowse 重新挂载（已是则跳过）；unmount 被占用时不误报成功；
    # 重挂后验证真实挂载态（mount 行须带 nobrowse），未隐藏则等 2 秒自动再
    # 执行一轮（卸载被占用/挂载竞态常在数秒内自行缓解），两轮均失败才提示重跑
    if ! IsNoBrowse; then
        DEV=$(diskutil info "$MOUNT_POINT" | awk -F': *' '/Device Node/{print $2}')
        ATTEMPT=0
        while [ $ATTEMPT -lt 2 ]; do
            OK=0
            # 卷不在原路径（上轮 mount 失败）时跳过卸载直接再挂
            if [ ! -d "$MOUNT_POINT" ] || sudo diskutil unmount "$MOUNT_POINT"; then
                sudo diskutil mount -mountOptions nobrowse "$DEV"
                if IsNoBrowse; then
                    if [ $ATTEMPT -eq 0 ]; then
                        REMOUNT_MSG="已以 nobrowse 重新挂载"
                    else
                        REMOUNT_MSG="已以 nobrowse 重新挂载（重试后成功）"
                    fi
                    OK=1
                else
                    REMOUNT_MSG="⚠️ 重挂后验证未通过（仍非 nobrowse），请重跑本工具"
                fi
            else
                REMOUNT_MSG="⚠️ 卸载失败（卷被 Spotlight 等占用），本次未隐藏，请稍后重试"
            fi
            [ "$OK" = "1" ] && break
            ATTEMPT=$((ATTEMPT + 1))
            [ $ATTEMPT -lt 2 ] && sleep 2
        done
    else
        REMOUNT_MSG="当前已是 nobrowse，无需重挂"
    fi

    # 用户目录快捷入口（无推出按钮）：LINK_SUBDIR 变量控制链接目标——
    # 不为空则链接到卷内该子目录，留空则默认链接卷根目录；
    # 恢复/卸载分支按链接名删除、不删卷内目录（里面是数据）
    # mkdir 前必须确认卷真实挂载在原路径：重挂失败/被挂到「卷名 1」时卷已不在，
    # 此时 mkdir 会在 /Volumes 下建出真实空目录，占住卷名，之后卷永远挂到「卷名 1」
    LINK_NOTE=""
    if [ -n "$LINK_SUBDIR" ]; then
        DATA_DIR="$MOUNT_POINT/$LINK_SUBDIR"
        LINK_TARGET_MSG="卷内 $LINK_SUBDIR 文件夹"
        if mount | grep -q " on $MOUNT_POINT ("; then
            mkdir -p "$DATA_DIR"
        else
            LINK_NOTE=$(printf '\n⚠️ 卷未挂载在原路径（重挂失败或挂到「卷名 1」），链接暂悬空，卷挂回原路径后自动生效')
        fi
    else
        DATA_DIR="$MOUNT_POINT"
        LINK_TARGET_MSG="卷根目录"
    fi
    # 是链接且目标相同 → 不动；是链接但目标不同 → 删了重建；
    # 同名真实目录 → 直接删除后重建（该路径归本工具管辖）
    if [ -L "$USER_LINK" ] && [ "$(readlink "$USER_LINK" 2>/dev/null)" = "$DATA_DIR" ]; then
        LINK_MSG=$(printf '用户目录入口已存在：%s → %s' "$USER_LINK" "$LINK_TARGET_MSG")
    else
        if [ -d "$USER_LINK" ] && [ ! -L "$USER_LINK" ]; then
            rm -rf "$USER_LINK"
        else
            rm -f "$USER_LINK"
        fi
        if ln -s "$DATA_DIR" "$USER_LINK"; then
            LINK_MSG=$(printf '已创建用户目录入口：%s → %s（可拖到 Finder 侧边栏）%s' "$USER_LINK" "$LINK_TARGET_MSG" "$LINK_NOTE")
        else
            LINK_MSG=$(printf '❌ 建链接失败，当前状态：%s' "$(ls -ld "$USER_LINK" 2>/dev/null)")
        fi
    fi

    # 验证（mount 行里的 nobrowse 即隐藏生效的直接证据）
    echo "—— 验证结果 ——"
    diskutil info "$MOUNT_POINT" | grep -E "Mounted|Mount Point"
    # mount 行里的 nobrowse 即隐藏生效的直接证据
    mount | grep " on $MOUNT_POINT ("

    printf '\n%b\n' "${GRN}✅ 挂载硬盘「${VOL_LABEL}」已隐藏！${NC}"
    printf '\n%s\n%s\n%s\n' "$REMOUNT_MSG" "$LINK_MSG" "已登记进开机自动隐藏配置（服务安装后开机生效，卸载会自动挂回）"

    # 未装 LaunchDaemon 时提醒：重启后隐藏不生效
    if [ ! -f /Library/LaunchDaemons/com.user.hide-disk.plist ]; then
        printf '\n%b\n' "${YEL}⚠️ 开机自动隐藏未安装，重启后访达会重新显示本卷${NC}"
        printf '   请选「6) 安装开机自动隐藏（LaunchDaemon）」\n'
    fi
    return 0
}

# ======================
# 2) 恢复挂载硬盘显示（读配置选卷，不要求盘在场：拔掉的盘也能从隐藏机制移除）
# ======================
DoRestore() {
    CONF_FILE="/Library/HideDisk/hide-disk.conf"
    if [ ! -s "$CONF_FILE" ]; then
        printf '\n配置中无登记的盘，无需恢复\n'
        return 0
    fi

    # 从配置选卷（多条时编号选择，一条自动选中）
    CONF_COUNT=$(wc -l < "$CONF_FILE" | tr -d ' ')
    if [ "$CONF_COUNT" -gt 1 ]; then
        printf '\n配置中登记的盘：\n'
        if ! PickItem < <(cut -d'|' -f1 "$CONF_FILE"); then
            return 0
        fi
        VOL_LABEL="$PICK_RESULT"
    else
        VOL_LABEL=$(cut -d'|' -f1 "$CONF_FILE")
    fi

    # 从配置行取该卷 UUID（格式 LABEL|UUID）
    UUID=$(awk -F'|' -v l="$VOL_LABEL" '$1 == l {print $2}' "$CONF_FILE" | LC_ALL=C tr -dc '0-9A-Fa-f-')
    if [ -z "$UUID" ]; then
        printf '\n%b\n' "${RED}❌ 配置中未找到「${VOL_LABEL}」${NC}"
        return 1
    fi

    # 从配置移除该卷
    awk -v u="$UUID" -F'|' '$2 != u' "$CONF_FILE" > "$CONF_FILE.tmp"
    mv "$CONF_FILE.tmp" "$CONF_FILE"

    MOUNT_POINT="/Volumes/$VOL_LABEL"

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
        printf '\n%b\n' "${GRN}✅ 已从开机自动隐藏移除「${VOL_LABEL}」，盘已恢复显示！${NC}"
        printf '\n%s\n%s\n' "$REMOUNT_MSG" "$LINK_MSG"
    else
        printf '\n%b\n' "${GRN}✅ 已从开机自动隐藏移除「${VOL_LABEL}」（盘当前不在场，插入后即正常显示）${NC}"
    fi
    return 0
}

# ======================
# 3) 查看挂载状态（遍历配置文件：盘在则报状态，不在则提示）
# ======================
DoStatus() {
    CONF_FILE="/Library/HideDisk/hide-disk.conf"
    if [ ! -f /Library/LaunchDaemons/com.user.hide-disk.plist ]; then
        printf '\n开机自动隐藏未安装，无监控的盘\n'
        return 0
    fi
    if [ ! -s "$CONF_FILE" ]; then
        printf '\n开机自动隐藏已安装，但配置中无登记的盘\n'
        return 0
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
    return 0
}

# ======================
# 4) 打上隐藏属性（chflags hidden：图标级隐藏，随盘持久；盘必须在场）
# ======================
DoLockAttr() {
    if ! FindVolume; then
        printf '\n❌ 未找到外置磁盘卷（或已取消），请先插入 USB 硬盘！\n'
        return 1
    fi
    printf '\n当前操作卷：%s\n' "$VOL_LABEL"

    # hidden 标志存文件系统元数据（APFS/HFS+），随盘持久：系统挂载那一刻起
    # Finder 就不显示桌面图标（无「先闪现几秒」问题）；只管桌面图标，
    # Finder 侧边栏仍显示（连侧边栏一起藏请用「1) 隐藏挂载硬盘显示」）
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
# 5) 删除隐藏属性（chflags nohidden：恢复桌面图标；盘必须在场）
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
# 6) 安装开机自动隐藏（LaunchDaemon）：只装服务；登记盘请用「1) 隐藏挂载硬盘显示」
# ======================
DoInstallService() {
    DAEMON_SCRIPT="/Library/HideDisk/hide-disk-remount.sh"
    DAEMON_PLIST="/Library/LaunchDaemons/com.user.hide-disk.plist"

    # 生成重挂脚本：静态（引号 heredoc 按字节原样写入、遍历配置文件，无写死值），幂等 + 事件驱动
    # （配合 plist 的 WatchPaths 监听 /Volumes：只在挂载/卸载事件时被拉起，零轮询；
    #   开机/挂载竞态与 unmount 被占用时按真实挂载态判定，退避重试最长约 10 秒）
    # 注释用中文不影响执行：bash 不解析注释内容，字节损坏也只坏注释不坏逻辑
    mkdir -p /Library/HideDisk
    cat > "$DAEMON_SCRIPT" <<'DAEMON'
#!/bin/bash
# 以 nobrowse 重挂各注册卷（幂等、事件驱动）。由 hide-disk-v2.sh 生成
CONF="/Library/HideDisk/hide-disk.conf"
[ -f "$CONF" ] || exit 0

# 维护登录触发文件：确保存在且所有用户可写（/tmp 每次开机会被清空）；
# LaunchAgent 每次登录 touch 它，经 WatchPaths 唤醒本守护进程
touch /tmp/.hide-disk-login 2>/dev/null && chmod 666 /tmp/.hide-disk-login 2>/dev/null

# 开机/登录竞态：WatchPaths 可能早于挂载完成就触发；Spotlight/Finder 扫
# 新挂卷时 unmount 会被占用。退避重试 3 轮（间隔 4/6 秒，最长约 10 秒）；
# 所有在场且 UUID 相符的卷都确认 nobrowse 后才提前退出
n=0
while [ $n -lt 3 ]; do
    PENDING=0
    while IFS='|' read -r LABEL VUUID; do
        [ -n "$LABEL" ] || continue
        MP="/Volumes/$LABEL"
        if [ ! -d "$MP" ]; then
            # 卷不在但设备仍在线（是卸载、不是整盘推出）：
            # 按 UUID 查设备并以 nobrowse 挂回
            DEV=$(diskutil info "$VUUID" 2>/dev/null | awk -F': *' '/Device Node/{print $2}')
            if [ -n "$DEV" ]; then
                diskutil mount -mountOptions nobrowse "$DEV" >/dev/null 2>&1
                # 设备在但挂回失败（登录竞态）：标记待重试，不能静默放过
                [ -d "$MP" ] || PENDING=1
            fi
            # 设备查不到（整盘推出/拔出）：谁也无法自动挂回，
            # 跳过等重插（重插时 /Volumes 变动会再次唤醒本进程）
            [ -d "$MP" ] || continue
        fi
        # UUID 核对：挂载点同名不代表是本盘（防同名顶替），不符跳过
        U=$(diskutil info "$MP" 2>/dev/null | awk '/Volume UUID/{print $NF}' | LC_ALL=C tr -dc '0-9A-Fa-f-')
        [ "$U" = "$VUUID" ] || continue
        # 已是 nobrowse（幂等）：直接跳过
        if mount | grep " on $MP (" | grep -q nobrowse; then
            continue
        fi
        DEV=$(diskutil info "$MP" | awk -F': *' '/Device Node/{print $2}')
        diskutil unmount "$MP" >/dev/null 2>&1
        diskutil mount -mountOptions nobrowse "$DEV" >/dev/null 2>&1
        # 重挂后以 mount 表验证真实状态：卸载被占用不得误记为成功
        mount | grep " on $MP (" | grep -q nobrowse || PENDING=1
    done < "$CONF"
    [ "$PENDING" = "0" ] && exit 0
    n=$((n + 1))
    # 退避间隔 4/6 秒；最后一轮失败不再空等直接退出
    [ $n -lt 3 ] && sleep $((n * 2 + 2))
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

    # 登录窗口触发器（LoginWindow 会话 Agent）：登录页一出现（开机首次出现、
    # 注销返回均算）就以 root 身份 touch 触发文件，赶在用户会话/Finder 启动前的
    # 安静窗口唤醒守护进程补跑一轮隐藏——此时 unmount 最少被占用。
    # 该会话由系统在登录页出现时自动加载，无法手动 bootstrap，装好即生效于
    # 下一次出现登录页（注销或重启后）；就算个别系统版本不加载它也只是少一道
    # 保险，其余三个触发点不受影响
    LW_AGENT_PLIST="/Library/LaunchAgents/com.user.hide-disk-loginwindow.plist"
    cat > "$LW_AGENT_PLIST" <<'LWAGENT'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.hide-disk-loginwindow</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/touch</string>
        <string>/tmp/.hide-disk-login</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>LimitLoadToSessionType</key>
    <string>LoginWindow</string>
</dict>
</plist>
LWAGENT
    chown root:wheel "$LW_AGENT_PLIST"
    chmod 644 "$LW_AGENT_PLIST"

    printf '\n%b\n' "${GRN}✅ 开机自动隐藏服务已安装（LaunchDaemon + 登录触发）！${NC}"
    printf '   开机监听 /Volumes 事件；登录页出现时（LoginWindow 会话）、用户登录时均会再触发一轮隐藏（零轮询，不占性能）\n'
    printf '   登记盘请用「1) 隐藏挂载硬盘显示」；移除登记用「2) 恢复挂载硬盘显示」\n'
    return 0
}

# ======================
# 7) 卸载开机自动隐藏（无需盘在场：删服务 + 所有本脚本生成的文件）
# ======================
DoUninstallService() {
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
    launchctl bootout system/com.user.hide-disk 2>/dev/null
    launchctl unload -w "$DAEMON_PLIST" 2>/dev/null
    [ -n "$SUDO_UID" ] && launchctl bootout "gui/$SUDO_UID/com.user.hide-disk-login" 2>/dev/null
    rm -f "$DAEMON_PLIST" "/Library/LaunchAgents/com.user.hide-disk-login.plist" "/Library/LaunchAgents/com.user.hide-disk-loginwindow.plist" /tmp/.hide-disk-login
    rm -f "$DAEMON_SCRIPT" "$CONF_FILE"
    # /Library/HideDisk 若为本脚本创建且已空则删除（rmdir 只删空目录，安全）
    rmdir /Library/HideDisk 2>/dev/null

    printf '\n%b\n' "${GRN}✅ 已卸载开机自动隐藏，并删除所有生成文件！${NC}"
    printf '   已删：服务（LaunchDaemon）、登录触发器（LaunchAgent）、重挂脚本、配置、用户目录入口链接\n'
    printf '   当前会话的挂载状态不受影响（如需恢复显示请重挂）\n'
    return 0
}

# ======================
# 主菜单（终端数字键操作，执行完按任意键返回）
# ======================
while true; do
    clear
    echo ""
    echo "===================================================="
    echo -e "  ${BLU}硬盘隐藏工具V2 @ ${SCRIPT_VERSION}${NC}"
    echo "===================================================="
    echo ""
    echo "  1) 🔒 隐藏挂载硬盘显示（nobrowse 挂载）"
    echo "  2) 🔓 恢复挂载硬盘显示（默认挂载）"
    echo "  3) 👀 查看挂载状态"
    echo "  4) ✅ 打上隐藏属性（仅藏桌面图标）"
    echo "  5) ❌ 删除隐藏属性（恢复桌面图标）"
    echo "  6) 🚀 安装开机自动隐藏服务（LaunchDaemon）"
    echo "  7) 🚮 卸载开机自动隐藏服务"
    echo "  0) 退出"
    echo ""
    read -n 1 -p "请直接按下数字键 (0-7): " choice </dev/tty || break
    echo ""
    case "$choice" in
        1) DoHide ;;
        2) DoRestore ;;
        3) DoStatus ;;
        4) DoLockAttr ;;
        5) DoUnlockAttr ;;
        6) DoInstallService ;;
        7) DoUninstallService ;;
        0|q) echo ""; echo "再见！"; break ;;
        "") echo -e "${RED}未输入任何内容，请输入数字 0-7！${NC}" ;;
        *) echo -e "${RED}错误的选项：${choice}，请输入数字 0-7！${NC}" ;;
    esac
    echo ""
    read -n 1 -s -p "按任意键返回主菜单..." _KEY </dev/tty || break
    echo ""
done
