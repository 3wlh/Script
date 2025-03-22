#!/bin/bash
RED_COLOR='\e[1;31m' #红色
GREEN_COLOR='\e[1;32m' #绿色
RES='\e[0m' #尾

#下载路径
Synoapi="https://raw.githubusercontent.com/3wlh/Script/main/Synology/API/Synoapi.cgi"
#设置GitHub加速下载
ip_info=$(curl -sk https://ip.cooluc.com)
country_code=$(echo $ip_info | sed -r 's/.*country_code":"([^"]*).*/\1/')
if [ $country_code = "CN" ]; then
	google_status=$(curl -I -4 -m 3 -o /dev/null -s -w %{http_code} http://www.google.com/generate_204)
	if [ ! $google_status = "204" ];then
		mirror="https://github.cooluc.com/"
	fi
fi

#下载
function Download() (
	echo -e "\r\n${GREEN_COLOR}下载软件包 ...${RES}\r\n"
	echo -e "${GREEN_COLOR}正在下载 $Synoapi ...${RES}"
	sudo curl --connect-timeout 30 -m 600 -#kLO $mirror$Synoapi
	if [ $? -ne 0 ]; then
		echo -e "${RED_COLOR}下载 $Synoapi 失败.${RES}\r\n"
		sudo rm -f $dir/Synoapi.cgi
		exit 1
	fi
)

# 安装
function Install() (
	echo -e "\r\n${GREEN_COLOR}安装软件包 ...${RES}\r\n"
	echo -e "${GREEN_COLOR}更改api权限...${RES}\r\n"
	sudo chmod -R 0755 $dir/Synoapi.cgi
	if [ $? -ne 0 ]; then
		echo -e "${RED_COLOR}更改权限失败.${RES}\r\n"
		sudo rm -f $dir/Synoapi.cgi
		exit 1
	fi
	/usr/syno/bin/synodsmnotify -t dsm @administrators helptoc:logcenter_notification pkgmgr:install_packages
	echo -e "\r\n${GREEN_COLOR}安装完成!${RES}\r\n"
)

#进入目录
dir="/usr/syno/synoman" && cd $dir || exit 1
# /usr/syno/bin/synodsmnotify -t dsm @administrators helptoc:logcenter_notification pkg_detail_status:installing
Download
if [ $? -eq 0 ]; then
	 Install
fi