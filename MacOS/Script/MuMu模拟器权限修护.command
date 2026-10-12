#!/bin/bash
clear
RED='\033[0;31m'
GRN='\033[0;32m'
BLU='\033[0;34m'
GREY='\033[0;37m'
NC='\033[0m'
APP_PATH="/Applications/MuMuPlayer.app"
echo ""
echo ""
echo -e "MuMu模拟器权限修复工具"
echo ""
echo -e "此程序主要解决此问题：${BLU}APP已损坏,无法打开，您应该将它移到废纸篓等问题！ ${NC}"
echo ""
if [ ! -e "$APP_PATH" ]; then
	echo -e "${RED}错误：应用路径不存在，请安装后再重试！${NC}"
else
	echo -e "${RED}请输入您的管理员密码（开机登录密码），输入后按Enter(回车键)${NC}"
	sudo xattr -rd com.apple.quarantine "$APP_PATH"
	echo -e "${GRN}操作已完成，如果依然提示打不开，请在 系统偏好设置-安全与隐私 里点击 仍要打开${NC}"
fi
echo -e "\n"
read -n 1 -s -p "按任意键退出..."
osascript -e 'tell application "Terminal" to close front window' & exit