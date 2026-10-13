#!/bin/bash
# ============================================
#  macOS PKG 包卸载工具 v1.1
#  功能：列出 pkg 包 → 选择 → 查目录 → 优先运行
#        官方卸载脚本 → 否则流式删除文件（无临时文件）
#        → 清除安装收据 → 验证
# ============================================

RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[0;33m'
BLU='\033[0;34m'
NC='\033[0m'

# ---------- 自动提权 ----------
if [ $UID -ne 0 ]; then
    printf '\n需要管理员权限，正在自动提权，请在下方输入管理员密码...\n\n'
    exec sudo /bin/bash "$0"
fi

# ---------- 列出可选的第三方包 ----------
list_packages() {
    pkgutil --pkgs | grep -v "^com.apple." | sort | nl -w2 -s'. '
}

# ---------- 主循环 ----------
while true; do
    clear
    echo ""
    echo "========================================"
    echo "        macOS PKG 包卸载工具 v1.1"
    echo "========================================"
    echo ""
    echo -e "${YLW}已安装的第三方 pkg 包（已过滤系统包）：${NC}"
    echo ""
    list_packages
    echo ""
    echo "  a) 显示全部包（包括 com.apple 系统包，仅供参考）"
    echo "  0) 退出"
    echo ""
    read -p "请输入要卸载的包的编号: " idx

    case "$idx" in
        0|q)
            echo "再见！"
            sleep 1
            exit 0
            ;;
        a|A)
            pkgutil --pkgs | sort | nl -w2 -s'. '
            echo ""
            read -n 1 -s -p "按任意键返回..."
            continue
            ;;
        *)
            # 根据编号取出对应的包名
            PKG=$(pkgutil --pkgs | grep -v "^com.apple." | sort | sed -n "${idx}p")

            if [ -z "$PKG" ]; then
                echo -e "\n${RED}无效编号，请重新选择！${NC}"
                sleep 2
                continue
            fi

            # 黑名单检查：系统包绝不允许卸载
            if [[ "$PKG" == com.apple.* ]]; then
                echo -e "\n${RED}⚠ 系统包不允许通过本工具卸载！${NC}"
                sleep 2
                continue
            fi

            echo ""
            echo -e "${YLW}你选择了：${GRN}${PKG}${NC}"
            echo -e "${BLU}----------------------------------------${NC}"
            pkgutil --pkg-info "$PKG"
            echo -e "${BLU}----------------------------------------${NC}"

            # 获取安装位置
            LOC=$(pkgutil --pkg-info "$PKG" | awk '/install-location/ {print $2}')
            LOC=${LOC:-/}
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
            read -p "确认卸载 $PKG 吗？(输入 yes 继续，其他任意键取消): " confirm
            if [ "$confirm" != "yes" ]; then
                echo -e "${YLW}已取消，返回主菜单...${NC}"
                sleep 2
                continue
            fi

            # ---------- 第二步：执行卸载 ----------
            if [ -n "$UNINSTALL_SCRIPT" ]; then
                echo ""
                echo -e "${GRN}▶ 正在运行官方卸载脚本...${NC}"
                chmod +x "$FULL_SCRIPT" 2>/dev/null
                "$FULL_SCRIPT"
                RESULT=$?
                if [ $RESULT -eq 0 ]; then
                    echo -e "${GRN}✔ 官方卸载脚本执行完成${NC}"
                else
                    echo -e "${YLW}脚本退出码 $RESULT，建议稍后手动检查残留${NC}"
                fi
            else
                # ---------- 手动删除模式（流式处理，不生成临时文件） ----------
                echo ""
                echo -e "${YLW}▶ 手动删除模式（流式处理，不生成临时文件）${NC}"

                COUNT=$(pkgutil --files "$PKG" | wc -l | tr -d ' ')
                echo "共 $COUNT 个文件/目录"

                echo ""
                read -p "按 y 逐个确认删除，按 a 全部删除，其他键跳过: " mode
                case "$mode" in
                    a|A)
                        echo ""
                        echo -e "${YLW}▶ 正在全部删除...${NC}"
                        # 用进程替换 < <() 而非管道，使循环在当前 shell 运行，
                        # 这样 DELETED 等变量修改能保留下来
                        DELETED=0
                        while IFS= read -r f; do
                            FULL="${LOC%/}/${f}"
                            if [ -e "$FULL" ]; then
                                if rm -rf "$FULL"; then
                                    DELETED=$((DELETED+1))
                                else
                                    echo -e "${RED}✘ 删除失败：${NC}$FULL"
                                fi
                            fi
                        done < <(pkgutil --files "$PKG")
                        echo -e "${GRN}✔ 完成，共删除 $DELETED 个文件/目录${NC}"
                        ;;
                    y|Y)
                        echo ""
                        DELETED=0
                        while IFS= read -r f; do
                            FULL="${LOC%/}/${f}"
                            if [ -e "$FULL" ]; then
                                read -p "删除 $FULL ? (y/n/q): " yn
                                case "$yn" in
                                    y)
                                        if rm -rf "$FULL"; then
                                            DELETED=$((DELETED+1))
                                            echo -e "${GRN}✔ 已删除${NC}"
                                        else
                                            echo -e "${RED}✘ 删除失败${NC}"
                                        fi
                                        ;;
                                    q)
                                        echo -e "${YLW}已中止，返回主菜单...${NC}"
                                        break
                                        ;;
                                esac
                            fi
                        done < <(pkgutil --files "$PKG")
                        echo -e "${GRN}本次共删除 $DELETED 个文件/目录${NC}"
                        ;;
                    *)
                        echo -e "${YLW}已跳过文件删除${NC}"
                        ;;
                esac
            fi

            # ---------- 第三步：清除安装收据 ----------
            echo ""
            read -p "是否清除安装收据 ($PKG)？(y/n): " forget_yn
            if [ "$forget_yn" = "y" ]; then
                if pkgutil --forget "$PKG"; then
                    echo -e "${GRN}✔ 收据已清除${NC}"
                else
                    echo -e "${RED}✘ 收据清除失败${NC}"
                fi
            else
                echo -e "${YLW}保留收据（系统仍认为该包已安装）${NC}"
            fi

            # ---------- 第四步：验证 ----------
            echo ""
            echo -e "${BLU}---------- 验证结果 ----------${NC}"
            if pkgutil --pkg-info "$PKG" &>/dev/null; then
                echo -e "${YLW}收据仍存在（如已选择清除则属异常）${NC}"
            else
                echo -e "${GRN}✔ 包收据已不存在${NC}"
            fi

            read -n 1 -s -p "按任意键返回主菜单..."
            ;;
    esac
done
