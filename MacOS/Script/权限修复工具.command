#!/bin/bash

RED='\033[0;31m'
GRN='\033[0;32m'
BLU='\033[0;34m'
NC='\033[0m'

if [ $UID -ne 0 ]; then
    printf '\n需要管理员权限，正在自动提权，请在下方输入管理员密码...\n\n'
    exec sudo /bin/bash "$0"
fi

while true; do
	clear
	echo ""
	echo "========================================"
	echo "  macOS 系统及应用权限修复工具 v1.1 @"
	echo "========================================"
	echo ""
	echo -e "此程序主要解决此问题：${BLU}APP已损坏,无法打开，您应该将它移到废纸篓等问题！${NC}"
	echo ""
	echo "  1) 打开系统权限，允许所有破解的软件、游戏或其他工具在macOS系统下运行"
	echo "  2) 关闭系统权限，不再允许破解的软件、游戏或其他工具在macOS系统下运行"
	echo "  3) 仅允许某个指定的破解应用在macOS系统下运行"
	echo "  0) 退出"
	echo ""
	read -n 1 -p "请直接按下数字键 (0-3): " choice
	case "$choice" in
		1)
			echo ""
			echo -e "${GRN}该选项将允许所有破解应用在macOS系统下运行，此选项需在安装应用前执行${NC}"
			echo -e "${GRN}此选项不会对系统造成其他任何影响，可放心使用${NC}"
			echo ""
			OUT=$(spctl --global-disable 2>&1 || spctl --master-disable 2>&1)
			if echo "$OUT" | grep -q "needs to be confirmed"; then
    				echo -e "${GRN}✔ 命令已执行，请到 系统设置-隐私与安全性-安全性-允许以下来源应用程序,里面选择<任何来源>${NC}"
			elif [ -z "$OUT" ]; then
    				echo -e "${GRN}✔ 操作成功！${NC}"
			else
    				echo -e "${RED}✘ 操作失败：${OUT}${NC}"
			fi
			read -n 1 -s -p "按任意键退出..."
			break
			;;
		2)
			echo ""
			echo -e "${GRN}该选项将不再允许任何破解应用在您的macOS系统下运行${NC}"
			echo ""
			if spctl --global-enable 2>/dev/null || spctl --master-enable 2>/dev/null; then
				echo -e "${GRN}✔ 操作成功！${NC}"
			else
				echo -e "${RED}✘ 操作失败！${NC}"
			fi
			echo -e "当前 Gatekeeper 状态：${GRN}$(spctl --status 2>&1)${NC}"
			read -n 1 -s -p "按任意键退出..."
			break
			;;
		3)
			echo ""
			echo -e "${GRN}该选项将允许您运行某个指定的被破解的应用，运行前请确保应用已被正确安装${NC}"
			echo ""
			read -e -p "请将应用程序文件夹内的应用图标拖至此处，并按Enter(回车键)执行： " FILEPATH
			FILEPATH="${FILEPATH%% }"
			echo ""
			if [ ! -e "$FILEPATH" ]; then
				echo -e "${RED}错误：路径不存在或无法访问！${NC}"
			else
				ERRMSG=$(xattr -rd com.apple.quarantine "$FILEPATH" 2>&1)
				if [ $? -eq 0 ]; then
					echo -e "${GRN}✔ 操作成功，隔离属性已清除！${NC}"
				elif echo "$ERRMSG" | grep -q "No such xattr"; then
					echo -e "${GRN}✔ 该应用本来就没有隔离属性，无需处理，可直接尝试打开。${NC}"
				else
					echo -e "${RED}✘ 操作失败！${ERRMSG}${NC}"
				fi
			fi
			echo ""
			echo -e "${GRN}如果依然提示打不开，请在 系统设置-隐私与安全性 里点击 仍要打开${NC}"
			;;
		0|q)
			echo -e "\n"
			echo "再见！"
			sleep 1
			break
			;;
		"")
			echo -e "\n${RED}未输入任何内容，请输入数字 1-4！${NC}"
			;;
		*)
			echo -e "\n${RED}错误的选项：${choice}，请输入数字 1-4！${NC}"
			;;
	esac
	echo ""
	echo "3秒后自动返回主菜单..."
	sleep 3
done
osascript -e 'tell application "Terminal" to close front window' & exit
