#!/bin/bash
clear

src="/Volumes/DataDisk/MacOS"
dst="$HOME/DataDisk"

# 检查源目录是否存在
if [ ! -d "$src" ]; then
	echo "错误：源目录 $src 不存在"
	echo -e "\n"
	read -n 1 -s -r -p "按任意键关闭窗口..."
	osascript -e 'tell application "Terminal" to close front window' & exit
fi

# 如果已存在同名链接/文件，先处理
if [ -e "$dst" ] || [ -L "$dst" ]; then
	echo "错误：$dst 已存在，请先删除或重命名"
	echo -e "\n"
	read -n 1 -s -r -p "按任意键关闭窗口..."
	osascript -e 'tell application "Terminal" to close front window' & exit
fi

ln -s "$src" "$dst" && echo "创建成功：$dst ->$src"
echo -e "\n"
read -n 1 -s -r -p "按任意键关闭窗口..."
osascript -e 'tell application "Terminal" to close front window' & exit