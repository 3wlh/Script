#!/bin/bash

RED='\033[0;31m'
GRN='\033[0;32m'
BLU='\033[0;34m'
NC='\033[0m'

while true; do
	reset
	echo ""
	echo "================================"
	echo "  macOS 文件夹锁定工具 v1.0 @"
	echo "================================"
	echo ""
	echo -e "此程序主要解决此问题：${BLU}APP文件更新,自动删除的问题！${NC}"
	echo ""
	echo "  1) 开启锁定文件夹,添加锁定属性"
	echo "  2) 关闭锁定文件夹,删除锁定属性"
	echo "  0) 退出"
	echo ""
	read -n 1 -p "请直接按下数字键 (0-2): " choice

	case "$choice" in
		1)
			echo ""
			read -e -p "请将要锁定的目录图标拖至此处，并按Enter(回车键)执行： " FILEPATH
			FILEPATH="${FILEPATH%% }"
			echo ""
			if [ ! -e "$FILEPATH" ]; then
				echo -e "${RED}错误：路径不存在或无法访问！${NC}"
			elif chflags uchg "$FILEPATH"; then
				echo -e "${GRN}✔ 文件夹锁定成功.${NC}"
				ls -lOd "$FILEPATH"
			else
				echo -e "${RED}✘ 锁定失败！可能是权限不足，请尝试用 sudo 运行本脚本.${NC}"
			fi
			;;
		2)
			echo ""
			read -e -p "请将要解除锁定的目录图标拖至此处，并按Enter(回车键)执行： " FILEPATH
			FILEPATH="${FILEPATH%% }"
			echo ""
			if [ ! -e "$FILEPATH" ]; then
				echo -e "${RED}错误：路径不存在或无法访问！${NC}"
			elif chflags nouchg "$FILEPATH"; then
				echo -e "${GRN}✔ 文件夹解除锁定成功.${NC}"
				ls -lOd "$FILEPATH"
			else
				echo -e "${RED}✘ 解锁失败！可能是权限不足，请尝试用 sudo 运行本脚本.${NC}"
			fi
			;;
		0|q) echo -e "\n" ; echo "再见！" ; sleep 1 ; break ;;
		"") echo -e "\n${RED}未输入任何内容，请输入数字 1-3！${NC}" ;;
		*) echo -e "\n${RED}错误的选项：$choice，请输入数字 1-3！${NC}" ;;
	esac
	echo ""
	echo "3秒后自动返回主菜单..."
	sleep 3
done
osascript -e 'tell application "Terminal" to close front window' & exit
