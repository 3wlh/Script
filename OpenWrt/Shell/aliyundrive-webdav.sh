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
	ROOT_SPACE=$(df -m /usr | awk 'END{print $4}')
	if [ $ROOT_SPACE -lt 5 ]; then
		echo -e "\r\n${RED_COLOR}错误! 系统存储空间小于5MB.${RES}\r\n"
		exit 1;
	fi
	echo -e "\r\n${GREEN_COLOR}检查OpenWrt架构 ...${RES}"
	prebuilt="aarch64_cortex-a53 aarch64_cortex-a72 aarch64_generic arm_arm1176jzf-s_vfp arm_arm926ej-s arm_cortex-a15_neon-vfpv4 arm_cortex-a5_vfpv4 arm_cortex-a7 arm_cortex-a7_neon-vfpv4 arm_cortex-a8_vfpv3 arm_cortex-a9 arm_cortex-a9_neon arm_cortex-a9_vfpv3-d16 arm_fa526 arm_mpcore arm_xscale i386_pentium-mmx i386_pentium4 mips64_octeonplus mips_24kc mips_4kec mips_mips32 mipsel_24kc mipsel_24kc_24kf mipsel_74kc mipsel_mips32 x86_64"
	verif=$(expr match "$prebuilt" ".*\($platform\)")
	if [[ ! $verif ]]; then
		echo -e "\r\n${RED_COLOR}错误! \"$platform\" 平台当前不受支持.${RES}\r\n"
		exit 1;
	else
		echo -e "\r\n${GREEN_COLOR}更新opkg来源 ...${RES}"
		#opkg update
		#安装依赖
	fi
}
#下载
function Download() {
	echo -e "\r\n${GREEN_COLOR}下载软件包 ...${RES}\r\n"
	# 获取软件包信息
	curl -sk --connect-timeout 10 "https://api.github.com/repos/messense/aliyundrive-webdav/releases" | grep "browser_download_url" | grep "ipk"> releases.txt
	if [ $? -ne 0 ]; then
		echo -e "${RED_COLOR}无法获取版本信息，请检查网络状态.${RES}\r\n"
		rm -rf $dir
		exit 1
	fi

	webdav=$(cat releases.txt | grep "browser_download_url" | grep $platform.ipk | head -1 | awk '{print $2}' | sed 's/\"//g')
	luci_app=$(cat releases.txt | grep "browser_download_url" | grep luci-app | head -1 | awk '{print $2}' | sed 's/\"//g')
	luci_i18n=$(cat releases.txt | grep "browser_download_url" | grep luci-i18n | head -1 | awk '{print $2}' | sed 's/\"//g')

	# download
	echo -e "${GREEN_COLOR}正在下载 $webdav ...${RES}"
	curl --connect-timeout 30 -m 600 -#kLO $mirror$webdav
	if [ $? -ne 0 ]; then
		echo -e "${RED_COLOR}错误! 下载 $alist 失败.${RES}\r\n"
		rm -rf $dir
		exit 1
	fi
	echo -e "${GREEN_COLOR}正在下载 $luci_app ...${RES}"
	curl --connect-timeout 30 -m 600 -#kLO $mirror$luci_app
	if [ $? -ne 0 ]; then
		echo -e "${RED_COLOR}错误! 下载 $luci_app 失败.${RES}\r\n"
		rm -rf $dir
		exit 1
	fi
	echo -e "${GREEN_COLOR}正在下载 $luci_i18n ...${RES}"
	curl --connect-timeout 30 -m 600 -#kLO $mirror$luci_i18n
	if [ $? -ne 0 ]; then
		echo -e "${RED_COLOR}错误! 下载 $luci_i18n 失败.${RES}\r\n"
		rm -rf $dir
		exit 1
	fi
}
# 安装
function Install() {
	echo -e "\r\n${GREEN_COLOR}安装软件包 ...${RES}\r\n"
	opkg install aliyundrive-webdav*.ipk
	opkg install luci-app*.ipk
	opkg install luci-i18n*.ipk
	rm -rf $dir /tmp/luci-*
	echo -e "\r\n${GREEN_COLOR}完成!${RES}\r\n"
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
