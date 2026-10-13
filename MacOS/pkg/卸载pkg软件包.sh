#!/bin/bash
# ============================================
#  macOS PKG 包卸载工具 v1.4
#  功能：列出 pkg 包 → 选择 → 查目录 → 优先运行
#        官方卸载脚本 → 否则流式删除文件（无临时文件）
#        → 清除安装收据 → 验证
#  运行：sudo bash xx.sh / 双击 xx.command / curl -fsSL URL | sudo bash
# ============================================

RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[0;33m'
BLU='\033[0;34m'
NC='\033[0m'

# ---------- 权限检查（不自动提权，非 root 直接报错退出） ----------
# 支持两种运行方式（交互 read 一律读 /dev/tty：管道执行时
# stdin 是脚本数据流，不指定 /dev/tty 的 read 会吞掉脚本后续内容）：
#   文件方式： sudo bash xx.sh / 双击 xx.command
#   管道方式： curl -fsSL 'URL' | sudo bash
if [ $UID -ne 0 ]; then
    printf '\033[0;31m✘ 需要管理员权限！\033[0m\n' >&2
    if [ -n "${BASH_SOURCE[0]}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
        printf '请重新运行： sudo bash %s\n\n' "${BASH_SOURCE[0]}" >&2
    else
        printf "请使用： curl -fsSL '脚本URL' | sudo bash\n\n" >&2
    fi
    exit 1
fi

# ---------- 安全删除 ----------
# 文件/符号链接直接删；目录只用 rmdir 删空目录，
# 非空共享目录（如 /usr/local/bin）自动保留，绝不 rm -rf
safe_remove() {
    local p="$1"
    if [ -L "$p" ]; then
        rm -f "$p"
    elif [ -d "$p" ]; then
        rmdir "$p" 2>/dev/null
    else
        rm -f "$p"
    fi
}

# ---------- 手动删除模式（流式处理，不生成临时文件） ----------
# 前面已输 y 确认卸载，这里不再二次询问，直接全部删除；
# 共享目录（如 /usr/local/bin）由 safe_remove 兜底保护
# 入参：$1=包ID  $2=安装根目录
manual_remove() {
    local PKG="$1" LOC="$2"
    local f FULL DELETED=0 KEPT=0

    echo ""
    echo -e "${YLW}▶ 手动删除模式（流式处理，不生成临时文件）${NC}"

    local COUNT
    COUNT=$(pkgutil --files "$PKG" | wc -l | tr -d ' ')
    echo "共 $COUNT 个文件/目录，正在全部删除（倒序处理，空目录才删除）..."

    # tail -r 倒序：先删文件再删目录，保证空目录能被 rmdir 清掉
    while IFS= read -r f; do
        FULL="${LOC%/}/${f}"
        if [ -e "$FULL" ] || [ -L "$FULL" ]; then
            if safe_remove "$FULL"; then
                DELETED=$((DELETED+1))
            elif [ -d "$FULL" ] && [ ! -L "$FULL" ]; then
                KEPT=$((KEPT+1))
                echo -e "${YLW}○ 目录非空，已保留：${NC}$FULL"
            else
                echo -e "${RED}✘ 删除失败：${NC}$FULL"
            fi
        fi
    done < <(pkgutil --files "$PKG" | tail -r)
    echo -e "${GRN}✔ 完成，共删除 $DELETED 个文件/目录，保留非空目录 $KEPT 个${NC}"
}

# ---------- 卸载单个包（完整流程） ----------
# 入参：$1=包ID
uninstall_package() {
    local PKG="$1"
    local LOC UNINSTALL_SCRIPT FULL_SCRIPT confirm RESULT sysconfirm

    # 系统包不拦截，但必须高危警告并二次确认（需输入完整包ID）
    if [[ "$PKG" == com.apple.* ]]; then
        echo ""
        echo -e "${RED}##################################################################${NC}"
        echo -e "${RED}##${NC}  ${RED}⚠⚠⚠  高危：你选择的是 macOS 系统包  ⚠⚠⚠${NC}                    "
        echo -e "${RED}##${NC}                                                              "
        echo -e "${RED}##${NC}  ${YLW}包ID：${NC}${PKG}"
        echo -e "${RED}##${NC}                                                              "
        echo -e "${RED}##${NC}  系统包属于 macOS / Xcode 组件，删除其文件或清除收据可能   "
        echo -e "${RED}##${NC}  导致系统更新异常、开发工具损坏，且通常无法直接恢复。      "
        echo -e "${RED}##${NC}  （密封系统卷 SSV 下多数系统文件实际只读，但仍请勿尝试）  "
        echo -e "${RED}##${NC}  如确有需要，建议先退出本工具，用 Time Machine 做好备份。 "
        echo -e "${RED}##################################################################${NC}"
        read -p "清楚以上风险？请输入完整包ID继续卸载，其他任意输入取消: " sysconfirm </dev/tty || sysconfirm=""
        if [ "$sysconfirm" != "$PKG" ]; then
            echo -e "${YLW}已取消${NC}"
            sleep 1
            return 2
        fi
        echo -e "${RED}已确认风险，继续...${NC}"
    fi

    echo ""
    echo -e "${YLW}你选择了：${GRN}${PKG}${NC}"
    echo -e "${BLU}----------------------------------------${NC}"
    pkgutil --pkg-info "$PKG"
    echo -e "${BLU}----------------------------------------${NC}"

    # 获取安装位置（新版 pkgutil 字段名为 location:，旧版为 install-location:）
    LOC=$(pkgutil --pkg-info "$PKG" | awk '$1=="location:" || $1=="install-location:" {print $2}')
    # location 是相对卷的路径（如 usr/local），统一规范成绝对路径
    case "$LOC" in
        ""|"/") LOC="/" ;;
        /*) ;;
        *) LOC="/$LOC" ;;
    esac
    echo -e "${BLU}安装位置（根目录）：${NC} $LOC"

    # ---------- 第一步：查找官方卸载脚本 ----------
    echo ""
    echo -e "${YLW}正在查找官方卸载脚本...${NC}"
    UNINSTALL_SCRIPT=$(pkgutil --files "$PKG" | grep -E "uninstall(\.sh)?$" | head -1)

    if [ -n "$UNINSTALL_SCRIPT" ]; then
        FULL_SCRIPT="${LOC%/}/${UNINSTALL_SCRIPT}"
        echo -e "${GRN}✔ 找到官方卸载脚本：${NC} $FULL_SCRIPT"

        if [ ! -f "$FULL_SCRIPT" ]; then
            echo -e "${RED}✘ 脚本实际不存在（可能已被删除），将转为手动删除模式${NC}"
            UNINSTALL_SCRIPT=""
        fi
    else
        echo -e "${YLW}未找到官方卸载脚本，将转为手动删除模式${NC}"
    fi

    # ---------- 最终确认 ----------
    echo ""
    echo -e "${RED}============================================${NC}"
    echo -e "${RED}⚠  警告：此操作将卸载上面的软件包，不可恢复！${NC}"
    echo -e "${RED}============================================${NC}"
    read -p "确认卸载 $PKG 吗？(输入 y 继续，其他任意键取消): " confirm </dev/tty || confirm=""
    # 大小写不敏感地接受 y / yes
    case "$confirm" in
        [yY] | [yY][eE][sS]) ;;
        *)
            echo -e "${YLW}已取消${NC}"
            sleep 2
            return 2
            ;;
    esac

    # ---------- 第二步：执行卸载 ----------
    if [ -n "$UNINSTALL_SCRIPT" ]; then
        echo ""
        echo -e "${GRN}▶ 正在运行官方卸载脚本...${NC}"
        chmod +x "$FULL_SCRIPT" 2>/dev/null
        # 官方卸载脚本可能自身有交互确认（如 git 的二次确认），管道模式下
        # 必须显式接 /dev/tty：否则它会从管道里吞掉本脚本的后续内容
        "$FULL_SCRIPT" </dev/tty
        RESULT=$?
        if [ $RESULT -eq 0 ]; then
            echo -e "${GRN}✔ 官方卸载脚本执行完成${NC}"
        else
            echo -e "${YLW}脚本退出码 $RESULT，建议稍后手动检查残留${NC}"
        fi
    else
        manual_remove "$PKG" "$LOC"
    fi

    # ---------- 第三步：清除安装收据（已确认卸载，默认清除，不再询问） ----------
    echo ""
    if pkgutil --pkg-info "$PKG" &>/dev/null; then
        if pkgutil --forget "$PKG"; then
            echo -e "${GRN}✔ 安装收据已清除${NC}"
        else
            echo -e "${RED}✘ 收据清除失败${NC}"
        fi
    else
        echo -e "${GRN}✔ 安装收据已不存在（官方卸载脚本已清除）${NC}"
    fi

    # ---------- 第四步：验证 ----------
    echo ""
    echo -e "${BLU}---------- 验证结果 ----------${NC}"
    if pkgutil --pkg-info "$PKG" &>/dev/null; then
        echo -e "${YLW}收据仍存在（如已选择清除则属异常）${NC}"
    else
        echo -e "${GRN}✔ 包收据已不存在${NC}"
    fi
}

# ---------- 列出可选的第三方包 ----------
list_packages() {
    pkgutil --pkgs | grep -v "^com.apple." | sort | nl -w2 -s'. '
}

# ---------- 主循环：只负责菜单与编号解析 ----------
while true; do
    clear
    echo ""
    echo "========================================"
    echo "        macOS PKG 包卸载工具 v1.4"
    echo "========================================"
    echo ""
    echo -e "${YLW}已安装的第三方 pkg 包（已过滤系统包）：${NC}"
    echo ""
    list_packages
    echo ""
    echo "  a) 显示全部包（包括 com.apple 系统包，可在列表中直接选编号）"
    echo "  0) 退出"
    echo ""
    read -p "请输入要卸载的包的编号: " idx </dev/tty || break
    SRC=third

    case "$idx" in
        0|q)
            echo -e "\n"
            echo "再见！"
            sleep 1
            break
            ;;
        a|A)
            echo ""
            pkgutil --pkgs | sort | nl -w2 -s'. '
            echo ""
            read -p "输入编号可直接卸载该包（com.apple 系统包会有高危警告+二次确认），直接回车返回: " sub </dev/tty || continue
            [ -z "$sub" ] && continue
            idx="$sub"
            SRC=all
            ;;
    esac

    # 根据编号取出对应的包名（全部列表 / 第三方列表）
    if [ "$SRC" = "all" ]; then
        PKG=$(pkgutil --pkgs | sort | sed -n "${idx}p")
    else
        PKG=$(pkgutil --pkgs | grep -v "^com.apple." | sort | sed -n "${idx}p")
    fi

    if [ -z "$PKG" ]; then
        echo -e "\n${RED}无效编号，请重新选择！${NC}"
        sleep 2
        continue
    fi

    uninstall_package "$PKG"
    RC=$?
    # 返回码 2 = 用户主动取消：不再等“按任意键”，直接回主菜单
    if [ "$RC" -ne 2 ]; then
        echo ""
        read -n 1 -s -p "按任意键返回主菜单..." </dev/tty || break
    fi
done
osascript -e 'tell application "Terminal" to close front window' & exit
