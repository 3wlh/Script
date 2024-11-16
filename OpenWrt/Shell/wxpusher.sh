#!/bin/bash

#========变量========
dir="/usr/share/api/"
api="https://gitee.com/git_3wlh/File/raw/main/OpenWrt/"
Cron="/etc/crontabs/root"
Cron_text=$(cat $Cron 2>/dev/null)
#========函数========

# 读取OpenWrt架构
function Read_schema() {
if [ -f /etc/openwrt_release ]; then
	. /etc/openwrt_release
	version=$(echo ${DISTRIB_RELEASE%%.*})
	platform=$(echo $DISTRIB_ARCH)
else
	echo -e "\r\n未知的OpenWRT版本!!!\r\n"
	exit 1
fi
}

# 检查架构
function Check_schema() {
	echo -e "\r\n${GREEN_COLOR}正在检查可用空间 ...${RES}"
	ROOT_SPACE=$(df -m /usr | awk 'END{print $4}')
	if [ $ROOT_SPACE -lt 2 ]; then
		echo -e "\r\n错误! 系统存储空间小于2MB.\r\n"
		exit 1;
	fi
	echo -e "\r\n检查OpenWrt架构 ..."
	ARM64_prebuilt="aarch64_cortex-a53 aarch64_cortex-a72 aarch64_generic"
	AMD_prebuilt="x86_64"
	verif=$(expr match "$ARM64_prebuilt" ".*\($platform\)")
	if [[ $verif ]]; then
		file="wxpusher_arm64"
		return
	fi
	verif=$(expr match "$AMD_prebuilt" ".*\($platform\)")
	if [[ $verif ]]; then
		file="wxpusher_amd64"
		return	
	fi
	echo -e "\r\n错误! \"$platform\" 平台当前不受支持.\r\n"
	exit 1;
}

function Set_Configuration() {
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
	cd $dir && ./$file $Password $URL
}

function Install() {
	if [ ! -n "$(echo ${Cron_text} | grep "${dir}${file}")" ]; then
		echo "*/10 * * * * ${dir}${file}" >> ${Cron}
	fi
}

#========函数入口========
(cd / && {
	Read_schema
	if [ $? -eq 0 ]; then
		Check_schema
		echo -e "\r\nOpenWRT架构：$file\r\n"
	else
		exit 1
	fi
	if [ $? -eq 0 ]; then
		Set_Configuration
		Install
	fi
})