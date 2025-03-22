#!/bin/sh
RED_COLOR='\e[1;31m' #红色
GREEN_COLOR='\e[1;32m' #绿色
RES='\e[0m' #尾

#设置GitHub加速下载
ip_info=$(curl -sk https://ip.cooluc.com)
country_code=$(echo $ip_info | sed -r 's/.*country_code":"([^"]*).*/\1/')
if [ $country_code = "CN" ]; then
	google_status=$(curl -I -4 -m 3 -o /dev/null -s -w %{http_code} http://www.google.com/generate_204)
	if [ ! $google_status = "204" ];then
		mirror="https://ghproxy.net/"
	fi
fi

# 检查
function Check() {
	echo -e "\r\n${GREEN_COLOR}正在检查可用空间 ...${RES}"
	ROOT_SPACE=$(df -m /www | awk 'END{print $4}')
	if [ $ROOT_SPACE -lt 20 ]; then
		echo -e "\r\n${RED_COLOR}错误! 系统存储空间小于20MB.${RES}\r\n"
		exit 1;
	fi
}
#安装
function Install() {
echo -e "\r\n${GREEN_COLOR}安装<argon_img>图片${RES}\r\n"
mp4="https://raw.githubusercontent.com/3wlh/OpenWrt/main/IMG//background.mp4"
img="https://raw.githubusercontent.com/3wlh/OpenWrt/main/IMG//background.jpg"
rm -f /www/luci-static/argon/background/*
if [ $? -eq 0 ]; then
	echo -e "${GREEN_COLOR}正在下载 $img ...${RES}"
	curl --connect-timeout 30 -m 600 -#kLO $mirror$img
	if [ $? -ne 0 ]; then
		echo -e "${RED_COLOR}下载 $img 失败.${RES}\r\n"
		exit 1
	fi
	sed -i "s|option online_wallpaper .*|	option online_wallpaper 'none'|g" /etc/config/argon
	echo -e "\r\n${GREEN_COLOR}安装<argon_img>完成${RES}\r\n"
else
	echo -e "${RED_COLOR}删除原文件失败.${RES}\r\n"
	exit 1
fi
}

dir="/www/luci-static/argon/background"
(cd $dir &&  (
Check
if [ $? -eq 0 ]; then
	Install
fi
))