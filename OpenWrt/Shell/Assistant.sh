#!/bin/bash
RED_COLOR='\e[1;31m' #红色
GREEN_COLOR='\e[1;32m' #绿色
RES='\e[0m' #尾

# 读取OpenWrt架构
if [ -f /etc/openwrt_release ]; then
	. /etc/openwrt_release
	version=$(echo ${DISTRIB_RELEASE%%.*})
	platform=$(echo $DISTRIB_ARCH)
	framework=$(echo $DISTRIB_TARGET | awk -F '/' '{print $2}')
	if [ $framework = "64" ];then
		cpu="amd64"
	else
		cpu="arm64"
	fi
else
	echo -e "\r\n${RED_COLOR}未知的OpenWRT版本!!!${RES}\r\n"
	exit 1
fi
#创建临时目录
tmp=$(mktemp -d) && cd $tmp || exit 1
#设置GitHub加速下载
ip_info=$(curl -sk https://ip.cooluc.com)
country_code=$(echo $ip_info | sed -r 's/.*country_code":"([^"]*).*/\1/')
if [ $country_code = "CN" ]; then
	google_status=$(curl -I -4 -m 3 -o /dev/null -s -w %{http_code} http://www.google.com/generate_204)
	if [ ! $google_status = "204" ];then
		mirror="https://github.cooluc.com/"
	fi
fi
# 检查
function Check() {
	echo -e "\r\n${GREEN_COLOR}正在检查可用空间 ...${RES}"
	ROOT_SPACE=$(df -m /usr | awk 'END{print $4}')
	if [ $ROOT_SPACE -lt 50 ]; then
		echo -e "\r\n${RED_COLOR}错误! 系统存储空间小于50MB.${RES}\r\n"
		exit 1;
	fi
}
#下载
function Download() {
	echo -e "\r\n${GREEN_COLOR}下载软件包 ...${RES}\r\n"
	# 获取软件包信息
	if [ $cpu = "amd64" ];then
		Assistant="https://raw.githubusercontent.com/3wking/OpenWrt/main/bin/Assistant_amd64.tar.gz"
	else
		Assistant="https://raw.githubusercontent.com/3wking/OpenWrt/main/bin/Assistant_arm64.tar.gz"
	fi	
	# download
	echo -e "${GREEN_COLOR}正在下载 $Assistant ...${RES}"
	curl --connect-timeout 30 -m 600 -#kLO $mirror$Assistant
	if [ $? -ne 0 ]; then
		echo -e "${RED_COLOR}下载 $Assistant 失败.${RES}\r\n"
		rm -rf $tmp
		exit 1
	fi
}
# 安装
function Install() {
	dir="/usr/share/Assistant"
	echo -e "\r\n${GREEN_COLOR}安装小Q助手 ...${RES}\r\n"
	if [ ! -d "$dir" ];then
	mkdir $dir
	else
	rm -rf $dir
	fi
	tar -zxf $tmp/Assistant*.gz -C $dir
	rm -rf $tmp/"Assistant*.tar.gz"
	if [ $? -ne 0 ]; then
	echo -e "${RED_COLOR}解压Assistant失败.${RES}\r\n"
	exit 1
	fi
	if [ ! -f "$dir/cq_config.yml" ]; then
	read -p "请输入你的AccessKeyID >>>: " AccessKeyID
	read -p "请输入你的AccessKey >>>: " AccessKey
	read -p "请输入你的域名 >>>: " DomainName
	read -p "请输入你的子域名 >>>: " RR
	echo "AccessKeyID=${AccessKeyID}" > $dir/cq_config.yml
	echo "AccessKey=${AccessKey}" >> $dir/cq_config.yml
	echo "DomainName=${DomainName}" >> $dir/cq_config.yml
	echo "RR=${RR}" >> $dir/cq_config.yml
	fi
	if [ -f "/etc/init.d/Assistant" ]; then
	rm -rf "/etc/init.d/Assistant"
	fi
	ln -s $dir/Assistant /etc/init.d/Assistant
	echo -e "\r\n${GREEN_COLOR}小Q助安装完成!${RES}\r\n"
	echo -e "${GREEN_COLOR}启动服务：${RES}"
	echo "/etc/init.d/Assistant start"
	echo -e "${GREEN_COLOR}停止服务：${RES}"
	echo "/etc/init.d/Assistant stop"
	echo -e "${GREEN_COLOR}开机自启：${RES}"
	echo "/etc/init.d/Assistant enable"
	echo -e "${GREEN_COLOR}取消自启：${RES}"
	echo "/etc/init.d/Assistant disable"
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
