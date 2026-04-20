#!/bin/bash

#========函数========
key="${1}"
function init {
echo -e "\e[1;36m初始化配置变量\e[0m"
#======= 初始化配置变量 =======
# 挂载 挂载目录 : uuid
Fstab="/mnt/SD : 3519c925-6c5e-7242-baa9-027d8a399db6 |
/mnt/HDD : 32ccc041-95e8-524e-aebb-b0501f7156a4"
# 共享 共享目录 : 名称
Share="/mnt/SD : SD|
/mnt/HDD : HDD|
/mnt/SD/存储 : 文件存储|"
# 节点
Sub_list="Dow4mIXKWbWKvxsD4++LQ3eofoBRLP0lJyXIQpJT6XA="
# 直连域名
URL_list="cloudflare.com | spaceship.com | openwrt.ai | age.tv"
IP_list="10.10.10.5 | 10.10.10.100 | 10.10.10.101 | 10.10.10.102"
# 防火墙：名称 : IP : [空或true:启用;false:禁用] : LAN端口 : WAN端口
Firewall="V2ray : 10.10.10.254 :: 4333-4335 |
OpenWrt_WEB : 10.10.10.254 :: 80 : 8 |
ASUS_WEB : 10.10.10.253 :: 80 : 6 |
DS918+_WEB : 10.10.10.252 :: 80 : 2 |
5Plus_WEB : 10.10.10.5 : false : 80 : 5 |
Page : 10.10.10.254 :: 88 |
Power_WEB : 10.10.10.8 : false : 80 : 4 |
DS918+_SMB : 10.10.10.252 :: 445 : 4455 |
DS918+_WebDAV : 10.10.10.252 :: 5005 |
DS918+_DSM : 10.10.10.252 :: 5000 |
DS918+_File : 10.10.10.252 ::7000-7001 |
PVE : 10.10.10.200 :: 8006 |
VS_Code : 10.10.10.252 :: 8001 |
Alist : 10.10.10.254 :: 5244 |
ADB: 10.10.10.100 :false: 5555 |"
# 卸载插件
Package="luci-app-partexp luci-app-diskman luci-app-webadmin luci-app-syscontrol"
# 配置名称
Config="network dhcp firewall v2ray_server passwall bypass vssr openclash homeproxy shadowsocksr"
}

function Password(){ #解密函数
mac="$(ip -o link show eth0 2>/dev/null | grep -Eo 'permaddr ([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}' | awk '{print $NF}')"
[ -z "${mac}" ] && mac="$(cat /sys/class/net/eth0/address 2>/dev/null)"
[ -n "${mac}" ] && key="$(echo -n "${mac}" | md5sum | awk '{print $1}' | cut -c9-24)"
echo -e "\e[1;31mKey:\e[0m\e[35m ${key} \e[0m"
}

function AES_D(){ #解密函数
[ -z "$1" ] || echo "$1" | openssl enc -e -aes-128-cbc -a -K ${key} -iv ${key} -base64 -d 2>/dev/null
}

function opkg_unload() {
for package in $(echo ${Package} | tr " " "|")
do
	# echo ${package}
	if [ -n "$(opkg list-installed ${package})" ]; then
		opkg remove ${package} --autoremove > /dev/null 2>&1 && echo "${package} 卸载......OK"
    fi
done
}

function direct_domain() {
echo "${URL_list}" | tr '|' '\n' | while read -r domain; do
	list=$(echo "${domain}" | tr -d ' \n')
	[ -z "${domain}" ] && continue
	[ $(tail -c1 "${1}" 2> /dev/null | wc -w) -eq 0 ] || echo "" >> "${1}"
	[ -n "$(cat "${1}" 2> /dev/null | grep "${domain}")" ] || echo "${domain}" >> "${1}"
done
}

function mddns() {
uci set mddns.config.enabled="1"
uci set mddns.config.online_config="https://cnb.cool/3wlh/Script/-/git/raw/main/OpenWrt/mddns/config.json"
}

function v2ray_server() {
function v2ray_config() { #v2ray_server配置函数
uuid="64iOHzGUb4ndh9kuxyEdLunzaiFkzNd8nOOROnv7MWqMTSw/YvzqvS78SDodQ7Db"
if [ ! -n "$(uci -q get v2ray_server.${1})" ]; then
	uci set  v2ray_server.${1}="user"
	uci set v2ray_server.${1}.enable="1"
	uci set v2ray_server.${1}.remarks="${2}"
	uci set v2ray_server.${1}.protocol="${3}"
	uci set v2ray_server.${1}.port="${4}"
	if [ "${3}" == "vless" ] || [ "${3}" == "vmess" ]; then
		[ "${3}" == "vless" ] && uci set v2ray_server.${1}.decryption="none"
		uci add_list v2ray_server.${1}.uuid="$(AES_D "${uuid}")"
		[ "${3}" == "vmess" ] &&  uci set v2ray_server.${1}.alter_id="16"
		uci set v2ray_server.${1}.level="1"
	fi
	if [ "${3}" == "socks" ]; then
		uci set v2ray_server.${1}.auth="1"
		uci set v2ray_server.${1}.username="$(AES_D "hJxYB5UfmX5fkt6B0KCwrg==")"
		uci set v2ray_server.${1}.password="$(AES_D "v+SXp3gpBanHTGxeahxrRA==")"
	fi
	uci set v2ray_server.${1}.tls="0"
	uci set v2ray_server.${1}.transport="tcp"
	uci set v2ray_server.${1}.tcp_guise="none"
	uci set v2ray_server.${1}.accept_lan="1"
fi	
}
uci set v2ray_server.@global[0].enable="1"
v2ray_config "293af8e569f3446d92ff5cd9ce332ba8" "Home_VLESS" "vless" "4333"
v2ray_config "ed6e87dd84844c9d9881872a1c660725" "Home_VMESS" "vmess" "4334"
v2ray_config "f70129045dee489793b400ddd7af5687" "Home_Socks" "socks" "4335"
}

function bypass() {
# 启用自动切换
uci set bypass.@global[0].enable_switch="1"
# 国外DNS
if [ -n "$(uci -q get bypass.@global[0].tcp_dns_o)" ]; then
	uci set bypass.@global[0].tcp_dns_o="1.1.1.1,1.0.0.1,8.8.8.8,8.8.4.4,9.9.9.9,149.112.112.112"
fi	
# 更新时间
uci set bypass.@server_subscribe[0].auto_update_time="2"
# 关键字保留
uci set bypass.@server_subscribe[0].save_words="V3/香港/台湾/日本/韩国/HK/YW/JP"
# 订阅新节点故障转移 （1转移 ：0不转移）
uci set bypass.@server_subscribe[0].switch="0"
# 添加订阅
Data=$(uci -q get bypass.@server_subscribe[0].subscribe_url)
echo "${Sub_lis}" | tr '|' '\n' | while read -r list; do
	list=$(echo "${list}" | tr -d ' \n')
	[ -z "${list}" ] && continue
	if [ ! -n "$(echo ${Data} | grep "$(AES_D "${list}")")" ]; then
		uci add_list bypass.@server_subscribe[0].subscribe_url="$(AES_D "${list}")"
	fi
done
# 直连域名
url_path="/etc/bypass/white.list"

# 直连IP
uci set bypass.@access_control[0].lan_ac_mode='b'
list_IP=$(uci -q get bypass.@access_control[0].lan_ac_ips)
echo "${IP_list}" | tr '|' '\n' | while read -r list; do
	list=$(echo "${list}" | tr -d ' \n')
	[ -z "${list}" ] && continue
	if [ -z "$(echo ${list_IP} | grep "${list}")" ]; then
		uci add_list bypass.@access_control[0].lan_ac_ips="${list}"
	fi
done
}

function vssr() {
# 启用自动切换
uci set vssr.@global[0].enable_switch="1"
# 更新时间
uci set vssr.@server_subscribe[0].auto_update="1"
uci set vssr.@server_subscribe[0].auto_update_time="2"
# 关键字保留
uci set vssr.@server_subscribe[0].save_words="V3/香港/台湾/日本/韩国/HK/YW/JP"
# 添加订阅
Data=$(uci -q get vssr.@server_subscribe[0].subscribe_url)
echo "${Sub_list}" | tr '|' '\n' | while read -r list; do
	list=$(echo "${list}" | tr -d ' \n')
	[ -z "${list}" ] && continue
	if [ ! -n "$(echo ${Data} | grep "$(AES_D "${list}")")" ]; then
		uci add_list vssr.@server_subscribe[0].subscribe_url="$(AES_D "${list}")"
	fi
done
# 直连域名
direct_domain "/etc/vssr/white.list"
# 直连IP
uci set vssr.@access_control[0].lan_ac_mode='b'
list_IP=$(uci -q get vssr.@access_control[0].lan_ac_ips)
echo "${IP_list}" | tr '|' '\n' | while read -r list; do
	list=$(echo "${list}" | tr -d ' \n')
	[ -z "${list}" ] && continue
	if [ -z "$(echo ${list_IP} | grep "${list}")" ]; then
		uci add_list vssr.@access_control[0].lan_ac_ips="${list}"
	fi
done
}

function homeproxy() {
# 是否支持ipv6 0.关闭
uci set homeproxy.config.ipv6_support='0'
# 更新时间
uci set homeproxy.subscription.auto_update="1"
uci set homeproxy.subscription.auto_update_time="2"
# 订阅新节点自动切换设置
uci set homeproxy.subscription.switch="0"
# 国内 DNS 服务器
uci set homeproxy.config.china_dns_server="wan"
# 包封装格式 {xudp}(Xray-core) {packetaddr}(v2ray-core)
# uci set homeproxy.subscription.packet_encoding='xudp'
# 关键字保留删除
uci set homeproxy.subscription.filter_nodes="whitelist"
Keywords=$(uci -q get homeproxy.subscription.filter_keywords | tr  '|' '@' | tr  ' ' '|')
for keywords in $(uci -q get homeproxy.subscription.filter_keywords)
do
	# echo ${keywords}
	uci del_list homeproxy.subscription.filter_keywords="${keywords}"
done
uci add_list homeproxy.subscription.filter_keywords="V3|香港|台湾|日本|韩国|HK|YW|JP"
# 添加订阅
Data=$(uci -q get homeproxy.subscription.subscription_url)
echo "${Sub_lis}" | tr '|' '\n' | while read -r list; do
	data=$(echo "${list}" | tr -d ' \n')
	[ -z "${list}" ] && continue
	if [ ! -n "$(echo ${Data} | grep "$(AES_D "${list}")")" ]; then
		uci add_list homeproxy.subscription.subscription_url="$(AES_D "${list}")"
	fi
done
# 直连域名
direct_domain "/etc/homeproxy/resources/direct_list.txt"
# 直连IP
uci set homeproxy.control.lan_proxy_mode='except_listed'
list_IP=$(uci -q get homeproxy.control.lan_direct_ipv4_ips)
echo "${IP_list}" | tr '|' '\n' | while read -r list; do
	list=$(echo "${list}" | tr -d ' \n')
	[ -z "${list}" ] && continue
	if [ -z "$(echo ${list_IP} | grep "${list}")" ]; then
		uci add_list homeproxy.control.lan_direct_ipv4_ips="${list}"
	fi
done
}

function passwall() {
Save_words="V3|香港|台湾|日本|韩国|HK|YW|JP"
# 更改DNS
uci set passwall.@global[].remote_dns='8.8.8.8'
# 关键字删除
uci set passwall.@global_subscribe[].filter_keyword_mode='0'
Keywords=$(uci -q get passwall.@global_subscribe[].filter_discard_list | tr  '|' '@' | tr  ' ' '|')
for keywords in $(uci -q get passwall.@global_subscribe[].filter_discard_list)
do
	# echo ${keywords}
	uci del_list passwall.@global_subscribe[].filter_discard_list="${keywords}"
done
# 添加订阅
Data=$(uci -q show passwall | grep "passwall.@subscribe_list.*.url=")
num1=0
echo "${Sub_lis}" | tr '|' '\n' | while read -r list; do
	list=$(echo "${list}" | tr -d ' \n')
	[ -z "${list}" ] && continue
	if [ -z "$(echo ${Data} | grep "$(AES_D "${list}")")" ]; then
		num1=`expr $num1 + 1`
		uci_id="$(uci add passwall subscribe_list)"
		uci set passwall.${uci_id}.remark="订阅_${num1}"
		uci set passwall.${uci_id}.url="$(AES_D "${list}")"
		uci set passwall.${uci_id}.allowInsecure='0'
		uci set passwall.${uci_id}.filter_keyword_mode='2'
		uci set passwall.${uci_id}.ss_type='global'
		uci set passwall.${uci_id}.trojan_type='global'
		uci set passwall.${uci_id}.vmess_type='global'
		uci set passwall.${uci_id}.vless_type='global'
		uci set passwall.${uci_id}.hysteria2_type='global'
		uci set passwall.${uci_id}.domain_strategy='global'
		uci set passwall.${uci_id}.auto_update='0'
		uci set passwall.${uci_id}.week_update='7'
		uci set passwall.${uci_id}.time_update='2'
		uci set passwall.${uci_id}.access_mode='direct'
		uci set passwall.${uci_id}.user_agent='v2rayN/9.99'
		for save_words in ${Save_words}
		do
			uci add_list passwall.${uci_id}.filter_keep_list="${save_words}"
		done	
	fi	
done
# 直连域名
direct_domain "/usr/share/passwall/rules/direct_host"
# 直连IP
ip_path="/usr/share/passwall/rules/direct_ip"
echo "${IP_list}" | tr '|' '\n' | while read -r list; do
	list=$(echo "${list}" | tr -d ' \n')
	[ -z "${list}" ] && continue
	[ $(tail -c1 "${ip_path}" 2> /dev/null | wc -w) -eq 0 ] || echo "" >> "${ip_path}"
	[ -n "$(cat "${ip_path}" 2> /dev/null | grep "${list}")" ] || echo "${list}" >> "${ip_path}"
done
}

function shadowsocksr() {
# 获取配置
Data=$(shadowsocksr.@server_subscribe[0].subscribe_url)
# 更新时间
uci set shadowsocksr.@server_subscribe[0].auto_update="1"
uci set shadowsocksr.@server_subscribe[0].auto_update_time="2"
# 关键字保留
uci set shadowsocksr.@server_subscribe[0].save_words="V3/香港/台湾/日本/韩国/HK/YW/JP"
# 添加订阅
echo "${Sub_list}" | tr '|' '\n' | while read -r list; do
	data=$(echo "${list}" | tr -d ' \n')
	[ -z "${list}" ] && continue
	if [ ! -n "$(echo ${Data} | grep "$(AES_D "${list}")")" ]; then
		uci add_list shadowsocksr.@server_subscribe[0].subscribe_url="$(AES_D "${list}")"
	fi
done
}

function openclash() {
#更新订阅
#uci set openclash.config.auto_update="1"
#uci set openclash.config.config_update_week_time="*"
#uci set openclash.config.config_auto_update_mode="0"
#使用meta内核 1,启用 0,禁用
#uci set openclash.config.enable_meta_core="0"
#绕过中国大陆 IP
uci set openclash.config.china_ip_route="1"
# 仅允许内网
uci set openclash.config.intranet_allowed="1"
#本地 DNS 劫持
uci set openclash.config.enable_redirect_dns="1"
uci set openclash.config.enable_custom_domain_dns_server="1"
# 添加订阅
Data="$(uci -q show openclash)"
count="0"
echo "${Sub_lis}" | tr '|' '\n' | while read -r list; do
	list=$(echo "${list}" | tr -d ' \n')
	[ -z "${list}" ] && continue
	count=$(( count + 1 ))
	if [ -z "$(echo "${Data}" | grep "$(AES_D "${list}")")" ]; then
		uci_id="$(uci add openclash config_subscribe)"
		uci set openclash.${uci_id}.enabled="0"
		uci set openclash.${uci_id}.name="Clash_${count}"
		uci set openclash.${uci_id}.address="$(AES_D "${list}")"
		uci set openclash.${uci_id}.sub_ua="clash-ninja/openwrt"
		uci set openclash.${uci_id}.sub_convert="0"
		uci add_list openclash.${uci_id}.keyword="V3"
		uci add_list openclash.${uci_id}.keyword="香港|台湾|日本|韩国|HK|TW|JP|KR"
	fi
done
# 直连域名
direct_domain "/etc/openclash/custom/openclash_custom_domain_dns.list"
}

function firewall() {
Data="$(uci -q show firewall)"
if [ -n "$(uci -q get network.MODE)" ]; then
	if [ ! -n "$(echo $(uci -q get firewall.@zone[1].network) | grep "MODE")" ]; then
		uci add_list firewall.@zone[1].network="MODE"
	fi
fi
echo "$Firewall" | while IFS='|' read -r data; do
    data=$(echo "${data}" | tr -d ' \n')
	[ -z "${data}" ] && continue
	name="$(echo ${data} | awk -F: '{printf "%s",$1}')"
	ip="$(echo ${data} | awk -F: '{printf "%s",$2}')"
	enabled="$(echo ${data} | awk -F: '{printf "%s",$3}')"
	lan="$(echo ${data} | awk -F: '{printf "%s",$4}')"
	if [ $(echo ${data} | grep -o ":" | wc -l) -ge 4 ]; then
		wan="$(echo ${data} | awk -F: '{printf "%s",$5}')"
	else
		wan="${lan}"
	fi
	if [ ! -n "$(echo ${Data} | grep "src_dport='${wan}'")" ]; then
		# echo "${name} | ${ip} | ${enabled} | ${lan} | ${wan}"
		uci_id="$(uci add firewall redirect)"
		uci set firewall.${uci_id}.target="DNAT"
		uci set firewall.${uci_id}.name="${name}"
		uci set firewall.${uci_id}.src="wan"
		uci set firewall.${uci_id}.src_dport="${wan}"
		uci set firewall.${uci_id}.dest_ip="${ip}"
		uci set firewall.${uci_id}.dest_port="${lan}"
		if [ "${enabled}" == "false" ]; then
			uci set firewall.${uci_id}.enabled="0"
		fi
	fi
done
}

function dhcp() {
Data="$(uci -q show dhcp)"
# 删除 DHCPv6 服务
#uci -q delete dhcp.lan.dhcpv6
# 删除 RA 服务删除
#uci -q delete dhcp.lan.ra
# 删除 NDP 代理
uci -q delete dhcp.lan.ndp
# WAN DHCPv6 接口
uci set dhcp.wan.ipv6='auto'
# 添加静态DHCP
if [ ! -n "$(echo ${Data} | grep "DBBOX5C")" ]; then
	uci_id="$(uci add dhcp host)"
	uci set dhcp.${uci_id}.name="DBBOX5C"
	uci set dhcp.${uci_id}.dns="1"
	uci set dhcp.${uci_id}.mac="70:4A:0E:D6:E1:A0"
	uci set dhcp.${uci_id}.ip="10.10.10.150"
	uci set dhcp.${uci_id}.leasetime="infinite"
fi
}

function network() {
if [ ! -n "$(uci -q get network.MODE)" ]; then
	uci set network.MODE="interface"
	uci set network.MODE.proto="static"
	uci set network.MODE.device="$(uci -q get network.wan.device)"
	uci set network.MODE.ipaddr="192.168.1.2"
	uci set network.MODE.gateway="192.168.1.1"
	uci set network.MODE.netmask="255.255.255.0"
	uci set network.MODE.defaultroute="0"
fi
uci set network.wan.ipv6="auto"
}

function filebrowser() {
# uci set filebrowser.config.enabled="1"
uci set filebrowser.@global[0].enable="1"
# 网页端口
# uci set filebrowser.config.listen_port="8989"
uci set filebrowser.@global[0].port="8088"
# 数据目录
# uci set filebrowser.config.root_path="/mnt/Share"
uci set filebrowser.@global[0].root_path="/mnt/Share"
# 软件目录
uci set filebrowser.@global[0].project_directory="/usr/bin"
# 禁用命令执行功能
# uci set filebrowser.config.disable_exec="1"
}

#========函数入口========
(cd / && {
init # 初始化脚本
[ -z "${key}" ] && Password # 获取key
echo -e "\e[1;32m结果:\e[0m"
for func in $(echo ${Config})
do
	#echo ${func}
	[ -n "$(uci -q show ${func})" ] && ${func} && uci commit ${func} && echo "${func}配置......OK"
    sleep 1
done
opkg_unload # 卸载插件
echo  
echo '================================='
echo '=           配置完成            ='
echo '================================='
})