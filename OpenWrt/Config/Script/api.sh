#!/bin/bash

#========变量========
RED_COLOR='\e[1;31m' #红色
GREEN_COLOR='\e[1;32m' #绿色
RES='\e[0m' #尾
dir="/usr/share/api/"
# api="https://raw.githubusercontent.com/3wlh/Script/main/OpenWrt/Config/API/"
api="https://gitee.com/git_3wlh/File/raw/main/OpenWrt/"
config="`echo ${url%/*/*}`/Config/"

#========函数========
#设置GitHub加速下载
ip_info=$(curl -sk https://ip.cooluc.com)
country_code=$(echo $ip_info | sed -r 's/.*country_code":"([^"]*).*/\1/')
if [ $country_code = "CN" ]; then
	google_status=$(curl -I -4 -m 3 -o /dev/null -s -w %{http_code} http://www.google.com/generate_204)
	if [ ! $google_status = "204" ];then
		mirror="https://mirror.ghproxy.com/"
	fi
fi

# 读取OpenWrt架构
function Read_schema() {
if [ -f /etc/openwrt_release ]; then
	. /etc/openwrt_release
	version=$(echo ${DISTRIB_RELEASE%%.*})
	platform=$(echo $DISTRIB_ARCH)
else
	echo -e "\r\n${RED_COLOR}未知的OpenWRT版本!!!${RES}\r\n"
	exit 1
fi
}

# 检查架构
function Check_schema() {
	echo -e "\r\n${GREEN_COLOR}正在检查可用空间 ...${RES}"
	ROOT_SPACE=$(df -m /usr | awk 'END{print $4}')
	if [ $ROOT_SPACE -lt 2 ]; then
		echo -e "\r\n${RED_COLOR}错误! 系统存储空间小于2MB.${RES}\r\n"
		exit 1;
	fi
	echo -e "\r\n${GREEN_COLOR}检查OpenWrt架构 ...${RES}"
	ARM64_prebuilt="aarch64_cortex-a53 aarch64_cortex-a72 aarch64_generic"
	ARM_prebuilt="arm_cortex-a7 "
	AMD_prebuilt="x86_64"
	verif=$(expr match "$ARM64_prebuilt" ".*\($platform\)")
	if [[ $verif ]]; then
		file="api_arm64"
		return
	fi
	verif=$(expr match "$ARM_prebuilt" ".*\($platform\)")
	if [[ $verif ]]; then
		file="api_arm"
		return
	fi
	verif=$(expr match "$AMD_prebuilt" ".*\($platform\)")
	if [[ $verif ]]; then
		file="api_amd64"
		return	
	fi
	echo -e "\r\n${RED_COLOR}错误! \"$platform\" 平台当前不受支持.${RES}\r\n"
	exit 1;
}

function Config() {
if [ ! -e $dir$file ]; then
	mkdir -p $dir
	wget $api$file -O $dir$file
	chmod +x $dir$file
fi
#API_SPACE=$(du -s $dir | awk 'END{print $1}')
if [ `du -s $dir | awk 'END{print $1}'` -lt 50 ]; then
	rm -rf /usr/share/api
	sleep 5s
	Config
fi
	cd $dir && ./$file $pwd $config
}

#========函数入口========
(cd / && {
	Read_schema
	if [ $? -eq 0 ]; then
		Check_schema
		echo -e "\r\n${GREEN_COLOR}OpenWRT架构：$file${RES}\r\n"
	else
		exit 1
	fi
	if [ $? -eq 0 ]; then
		Config
	fi
})