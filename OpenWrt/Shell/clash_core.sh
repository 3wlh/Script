#!/bin/sh
RED_COLOR='\e[1;31m' #红色
GREEN_COLOR='\e[1;32m' #绿色
RES='\e[0m' #尾

# 读取OpenWrt架构
if [ -f /etc/openwrt_release ]; then
	. /etc/openwrt_release
	version=$(echo ${DISTRIB_RELEASE%%.*})
	platform=$(echo $DISTRIB_ARCH)
	framework=$(echo $DISTRIB_TARGET | awk -F '/' '{print $2}')
	if [ $framework = "armv8" ];then
		cpu="arm64"
	fi
else
	echo -e "\r\n${RED_COLOR}未知的OpenWRT版本!!!${RES}\r\n"
	exit 1
fi
#创建临时目录
dir=$(mktemp -d) && cd $dir || exit 1
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
	ROOT_SPACE=$(df -m /etc | awk 'END{print $4}')
	if [ $ROOT_SPACE -lt 15 ]; then
		echo -e "\r\n${RED_COLOR}错误! 系统存储空间小于15MB.${RES}\r\n"
		exit 1;
	fi
	echo -e "\r\n${GREEN_COLOR}检查OpenWrt架构 ...${RES}"
	prebuilt="aarch64_cortex-a53 aarch64_cortex-a72 aarch64_generic arm_arm1176jzf-s_vfp arm_arm926ej-s arm_cortex-a15_neon-vfpv4 arm_cortex-a5_vfpv4 arm_cortex-a7 arm_cortex-a7_neon-vfpv4 arm_cortex-a8_vfpv3 arm_cortex-a9 arm_cortex-a9_neon arm_cortex-a9_vfpv3-d16 arm_fa526 arm_mpcore arm_xscale i386_pentium-mmx i386_pentium4 mips64_octeonplus mips_24kc mips_4kec mips_mips32 mipsel_24kc mipsel_24kc_24kf mipsel_74kc mipsel_mips32 x86_64"
	verif=$(expr match "$prebuilt" ".*\($platform\)")
	if [[ ! $verif ]]; then
		echo -e "${RED_COLOR}错误! \"$platform\" 平台当前不受支持.${RES}\r\n"
		exit 1;
	fi
}
#下载
function Download() {
	echo -e "\r\n${GREEN_COLOR}下载软件包 ...${RES}\r\n"
	# 获取 dev 信息
	curl -sk --connect-timeout 10 "https://api.github.com/repos/vernesong/OpenClash/contents/dev/dev?ref=core" | grep "download_url" | grep "$cpu" > releases.txt
	if [ $? -ne 0 ]; then
		echo -e "${RED_COLOR}错误! 无法获取dev内核信息，请检查网络状态.${RES}"
		rm -rf $dir
		exit 1
	fi
	dev=$(cat releases.txt | grep "download_url" | head -1 | awk '{print $2}' | sed 's/\"//g' | sed 's/,//g')	

	# 获取 premium 信息
	curl -sk --connect-timeout 10 "https://api.github.com/repos/vernesong/OpenClash/contents/dev/premium?ref=core" | grep "download_url" | grep "$cpu" > releases.txt
	if [ $? -ne 0 ]; then
		echo -e "${RED_COLOR}错误! 无法获取premium内核信息，请检查网络状态.${RES}"
		rm -rf $dir
		exit 1
	fi
	premium=$(cat releases.txt | grep "download_url" | head -1 | awk '{print $2}' | sed 's/\"//g' | sed 's/,//g')
	
	# 获取 meta内核 信息
	curl -sk --connect-timeout 10 "https://api.github.com/repos/vernesong/OpenClash/contents/dev/meta?ref=core" | grep "download_url" | grep "$cpu" > releases.txt
	if [ $? -ne 0 ]; then
		echo -e "${RED_COLOR}错误! 无法获取meta内核信息，请检查网络状态.${RES}"
		rm -rf $dir
		exit 1
	fi
	meta=$(cat releases.txt | grep "download_url" | head -1 | awk '{print $2}' | sed 's/\"//g' | sed 's/,//g')

	# download
	echo -e "${GREEN_COLOR}正在下载 $dev ...${RES}"
	curl --connect-timeout 30 -m 600 -#kLo dev.tar.gz $mirror$dev
	if [ $? -ne 0 ]; then
		echo -e "${RED_COLOR}错误! 下载 $dev 失败.${RES}\r\n"
		rm -rf $dir
		exit 1
	fi
	echo -e "${GREEN_COLOR}正在下载 $premium ...${RES}"
	curl --connect-timeout 30 -m 600 -#kLo premium.gz $mirror$premium
	if [ $? -ne 0 ]; then
		echo -e "${RED_COLOR}错误! 下载 $premium 失败.${RES}\r\n"
		rm -rf $dir
		exit 1
	fi
	echo -e "${GREEN_COLOR}正在下载 $meta ...${RES}"
	curl --connect-timeout 30 -m 600 -#kLo meta.tar.gz $mirror$meta
	if [ $? -ne 0 ]; then
		echo -e "${RED_COLOR}错误! 下载 $meta 失败.${RES}\r\n"
		rm -rf $dir
		exit 1
	fi
}
#安装
function Install() {
	Core="/etc/openclash/core"
	echo -e "\r\n${GREEN_COLOR}安装内核中 ...${RES}\r\n"
	tar -zxf dev*.gz -O > ${Core}/clash && chmod 0755 ${Core}/clash
	gunzip -c premium.gz > ${Core}/clash_tun && chmod 0755 ${Core}/clash_tun
	tar -zxf meta*.gz  -O > ${Core}/clash_meta && chmod 0755 ${Core}/clash_meta
	rm -rf $dir
	echo -e "\r\n${GREEN_COLOR}安装内核完成!${RES}\r\n"
}

Check
if [ $? -eq 0 ]; then
	Download
else
	exit 1
fi
if [ $? -eq 0 ]; then
	Install
fi