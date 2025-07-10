#!/bin/bash
#========函数========
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
Sub_list="EvbGl3PKvNtRUgQ0iZgqg5ryii/STox+qNWfZLpiwuYjk14YgX/LEEOw1x1qQzYEivZyyov5M1ZqIeJ3IJDl4wr+SAvWspo+U2777sABwpifJu92A2tQwsp8JO+J0+9clCcvHSnRn8PPuA2BMUdr2gmTS7YibDx7VSC4ibKNC2Rs9AVfE77u0m0rpE8IazRS"
# 直连域名
URL_list="dash.cloudflare.com | www.spaceship.com | openwrt.ai | dl.openwrt.ai | age.tv"
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
Config="network dhcp firewall fstab ddns ddns-go unishare v2ray_server passwall bypass vssr openclash homeproxy shadowsocksr filebrowser sunpanel alist openlist"
}

function Password(){ #解密函数
key=$(ip -o link show eth0 | awk '{print $NF}' | tr -d '\n' | md5sum | awk '{print $1}' | cut -c9-24)
[[ -n "${key}" ]] || key=$(cat /sys/class/net/eth0/address | tr -d '\n' | md5sum | awk '{print $1}' | cut -c9-24)
echo -e "\e[1;31mKey:\e[0m\e[35m ${key} \e[0m"
}

function AES_D(){ #解密函数
[[ -z "$1" ]] || echo "$1" | openssl enc -e -aes-128-cbc -a -K ${key} -iv ${key} -base64 -d 2>/dev/null
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

function Webpage() {
Webpage_url="http://3wlh.github.io/Script/OpenWrt/webpage"
download_name=(${1})
for name in "${download_name[@]}"; do
	download_url="${Webpage_url}/${name}.html"
	echo "Download ${download_url}"
	wget -qO "/www/$(basename ${download_url})" "${download_url}" --show-progress
done
}

function ddns() {
# 删除myddns_ipv4
uci -q delete ddns.myddns_ipv4
# 删除myddns_ipv6
uci -q delete ddns.myddns_ipv6	
# aliyun
uci set ddns.aliyun=service
uci set ddns.aliyun.service_name="aliyun.com"
uci set ddns.aliyun.use_ipv6="0"
uci set ddns.aliyun.enabled="1"
uci set ddns.aliyun.lookup_host="3wlh.cn"
uci set ddns.aliyun.domain="3wlh.cn"
uci set ddns.aliyun.username="$(AES_D "Uv6Isu3WHAjgLjytxHD3uyR/JKwPRaxfVBN+OeWwZiY=")"
uci set ddns.aliyun.password="$(AES_D "Lp7X9urVlBuQXNEzdUqRCNYlHJ2uWa77PN08NuSJ7vQGh48pSE/BEQXmqX9n77E2")"
uci set ddns.aliyun.ip_source="network"
uci set ddns.aliyun.ip_network="wan"
uci set ddns.aliyun.interface="wan"
uci set ddns.aliyun.use_syslog="2"
uci set ddns.aliyun.check_interval="5"
uci set ddns.aliyun.check_unit="minutes"
uci set ddns.aliyun.force_interval="2"
uci set ddns.aliyun.force_unit="days"
# uci set ddns.aliyun.retry_interval="1"
# uci set ddns.aliyun.retry_unit="minutes"
# cloudflare
uci set ddns.cloudflare=service
uci set ddns.cloudflare.service_name="cloudflare.com-v4"
uci set ddns.cloudflare.use_ipv6="0"
uci set ddns.cloudflare.enabled="1"
uci set ddns.cloudflare.lookup_host="19970101.xyz"
uci set ddns.cloudflare.domain="19970101.xyz"
uci set ddns.cloudflare.username="Bearer"
uci set ddns.cloudflare.password="$(AES_D "ND/hE8YwYu7T+Dza9M/e7LklbCIvKhQw97K8VJU1EydS6GxrBOb1o5fh5YZHIM+6")"
uci set ddns.cloudflare.ip_source="network"
uci set ddns.cloudflare.ip_network="wan"
uci set ddns.cloudflare.interface="wan"
uci set ddns.cloudflare.use_syslog="2"
uci set ddns.cloudflare.check_interval="5"
uci set ddns.cloudflare.check_unit="minutes"
uci set ddns.cloudflare.force_interval="2"
uci set ddns.cloudflare.force_unit="days"
# uci set ddns.cloudflare.retry_interval="1"
# uci set ddns.cloudflare.retry_unit="minutes"
}

function ddns-go() {
uci set ddns-go.config.enabled='1'
ddns_url="http://3wlh.github.io/Script/OpenWrt/ddns-go/config.key"
test -d "/etc/ddns-go" || mkdir -p "/etc/ddns-go"
wget -qO "/etc/ddns-go/$(basename ${ddns_url})" "${ddns_url}" --show-progress
if [ "$(du -b "/etc/ddns-go/$(basename ${ddns_url})" 2>/dev/null | awk '{print $1}')" -ge "2000" ]; then
	openssl aes-128-cbc -d -in "/etc/ddns-go/config.key" -base64 -out "/etc/ddns-go/config.yaml" -k ${key} 2>/dev/null
	chown -R ddns-go:root "/etc/ddns-go"
fi
}

function v2ray_server() {
uuid="64iOHzGUb4ndh9kuxyEdLkIUyxiM1NatBVj9EZOwVdwg6C11d79ywum97Q788pHA"
uci set v2ray_server.@global[0].enable=1
if [ ! -n "$(uci -q get v2ray_server.293af8e569f3446d92ff5cd9ce332ba8)" ]; then
	uci set  v2ray_server.293af8e569f3446d92ff5cd9ce332ba8="user"
	uci set v2ray_server.293af8e569f3446d92ff5cd9ce332ba8.enable="1"
	uci set v2ray_server.293af8e569f3446d92ff5cd9ce332ba8.remarks="Home_VLESS"
	uci set v2ray_server.293af8e569f3446d92ff5cd9ce332ba8.protocol="vless"
	uci set v2ray_server.293af8e569f3446d92ff5cd9ce332ba8.port="4333"
	uci set v2ray_server.293af8e569f3446d92ff5cd9ce332ba8.decryption="none"
	uci add_list v2ray_server.293af8e569f3446d92ff5cd9ce332ba8.uuid="$(AES_D "${uuid}")"
	uci set v2ray_server.293af8e569f3446d92ff5cd9ce332ba8.level="1"
	uci set v2ray_server.293af8e569f3446d92ff5cd9ce332ba8.tls="0"
	uci set v2ray_server.293af8e569f3446d92ff5cd9ce332ba8.transport="tcp"
	uci set v2ray_server.293af8e569f3446d92ff5cd9ce332ba8.tcp_guise="none"
	uci set v2ray_server.293af8e569f3446d92ff5cd9ce332ba8.accept_lan="1"
fi
if [ ! -n "$(uci -q get v2ray_server.ed6e87dd84844c9d9881872a1c660725)" ]; then
	uci set  v2ray_server.ed6e87dd84844c9d9881872a1c660725="user"
	uci set v2ray_server.ed6e87dd84844c9d9881872a1c660725.enable="1"
	uci set v2ray_server.ed6e87dd84844c9d9881872a1c660725.remarks="Home_VMESS"
	uci set v2ray_server.ed6e87dd84844c9d9881872a1c660725.protocol="vmess"
	uci set v2ray_server.ed6e87dd84844c9d9881872a1c660725.port="4334"
	uci add_list v2ray_server.ed6e87dd84844c9d9881872a1c660725.uuid="$(AES_D "${uuid}")"
	uci set v2ray_server.ed6e87dd84844c9d9881872a1c660725.alter_id="16"
	uci set v2ray_server.ed6e87dd84844c9d9881872a1c660725.level="1"
	uci set v2ray_server.ed6e87dd84844c9d9881872a1c660725.tls="0"
	uci set v2ray_server.ed6e87dd84844c9d9881872a1c660725.transport="tcp"
	uci set v2ray_server.ed6e87dd84844c9d9881872a1c660725.tcp_guise="none"
	uci set v2ray_server.ed6e87dd84844c9d9881872a1c660725.accept_lan="1"
fi
if [ ! -n "$(uci -q get v2ray_server.f70129045dee489793b400ddd7af5687)" ]; then
	uci set v2ray_server.f70129045dee489793b400ddd7af5687="user"
	uci set v2ray_server.f70129045dee489793b400ddd7af5687.enable="1"
	uci set v2ray_server.f70129045dee489793b400ddd7af5687.remarks="Home_Socks"
	uci set v2ray_server.f70129045dee489793b400ddd7af5687.protocol="socks"
	uci set v2ray_server.f70129045dee489793b400ddd7af5687.port="4335"
	uci set v2ray_server.f70129045dee489793b400ddd7af5687.auth="1"
	uci set v2ray_server.f70129045dee489793b400ddd7af5687.username="$(AES_D "hJxYB5UfmX5fkt6B0KCwrg==")"
	uci set v2ray_server.f70129045dee489793b400ddd7af5687.password="$(AES_D "v+SXp3gpBanHTGxeahxrRA==")"
	uci set v2ray_server.f70129045dee489793b400ddd7af5687.tls="0"
	uci set v2ray_server.f70129045dee489793b400ddd7af5687.transport="tcp"
	uci set v2ray_server.f70129045dee489793b400ddd7af5687.tcp_guise="none"
	uci set v2ray_server.f70129045dee489793b400ddd7af5687.accept_lan="1"
fi
}

function bypass() {
# 获取配置
url_path="/etc/bypass/white.list"
Data=$(uci -q get bypass.@server_subscribe[0].subscribe_url)
list_IP=$(uci -q get bypass.@access_control[0].lan_ac_ips)
list_URL=$(cat "${url_path}" 2> /dev/null)
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
# 订阅URL地址
for list in ${Sub_list}
do
	list="$(echo ${list} | tr -d " " | tr -d "\n")"
	[[ -n "${list}" ]] || continue
	if [ ! -n "$(echo ${Data} | grep "$(AES_D "${list}")")" ]; then
		uci add_list bypass.@server_subscribe[0].subscribe_url="$(AES_D "${list}")"
	fi
done
# 直连域名
for list in ${URL_list}
do
	list="$(echo ${list} | tr -d " " | tr -d "\n")"
	[[ -n "${list}" ]] || continue
	[[ $(tail -c1 "${url_path}" 2> /dev/null | wc -w) -eq 0 ]] || echo "" >> "${url_path}"
	[[ -n "$(echo ${list_URL} | grep "${list}")" ]] || echo "${list}" >> "${url_path}"
done
# 直连IP
uci set bypass.@access_control[0].lan_ac_mode='b'
for list in ${IP_list}
do
	list="$(echo ${list} | tr -d " " | tr -d "\n")"
	[[ -n "${list}" ]] || continue
	if [ ! -n "$(echo ${list_IP} | grep "${list}")" ]; then
		uci add_list bypass.@access_control[0].lan_ac_ips="${list}"
	fi
done
}

function vssr() {
# 获取配置
url_path="/etc/vssr/white.list"
Data=$(uci -q get vssr.@server_subscribe[0].subscribe_url)
list_IP=$(uci -q get vssr.@access_control[0].lan_ac_ips)
list_URL=$(cat "${url_path}" 2> /dev/null)
# 启用自动切换
uci set vssr.@global[0].enable_switch="1"
# 更新时间
uci set vssr.@server_subscribe[0].auto_update="1"
uci set vssr.@server_subscribe[0].auto_update_time="2"
# 关键字保留
uci set vssr.@server_subscribe[0].save_words="V3/香港/台湾/日本/韩国/HK/YW/JP"
# 订阅URL地址
for list in ${Sub_list}
do
	[[ -n "$(echo ${data} | tr -d " " | tr -d "\n")" ]] || continue
	if [ ! -n "$(echo ${Data} | grep "$(AES_D "${list}")")" ]; then
		uci add_list vssr.@server_subscribe[0].subscribe_url="$(AES_D "${list}")"
	fi
done
# 直连域名
for list in ${URL_list}
do
	list="$(echo ${list} | tr -d " " | tr -d "\n")"
	[[ -n "${list}" ]] || continue
	[[ $(tail -c1 "${url_path}" 2> /dev/null | wc -w) -eq 0 ]] || echo "" >> "${url_path}"
	[[ -n "$(echo ${list_URL} | grep "${list}")" ]] || echo "${list}" >> "${url_path}"
done
# 直连IP
uci set vssr.@access_control[0].lan_ac_mode='b'
for list in ${IP_list}
do
	list="$(echo ${list} | tr -d " " | tr -d "\n")"
	[[ -n "${list}" ]] || continue
	if [ ! -n "$(echo ${list_IP} | grep "${list}")" ]; then
		uci add_list vssr.@access_control[0].lan_ac_ips="${list}"
	fi
done
}

function homeproxy() {
# 获取配置
url_path="/etc/homeproxy/resources/direct_list.txt"
Data=$(uci -q get homeproxy.subscription.subscription_url)
list_IP=$(uci -q get homeproxy.control.lan_direct_ipv4_ips)
list_URL=$(cat "${url_path}" 2> /dev/null)
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
IFS=" " # 分割符变量
uci set homeproxy.subscription.filter_nodes="whitelist"
Keywords=$(uci -q get homeproxy.subscription.filter_keywords | tr  '|' '@' | tr  ' ' '|')
for keywords in $(uci -q get homeproxy.subscription.filter_keywords)
do
	# echo ${keywords}
	uci del_list homeproxy.subscription.filter_keywords="${keywords}"
done
IFS="|" # 分割符变量
uci add_list homeproxy.subscription.filter_keywords="V3|香港|台湾|日本|韩国|HK|YW|JP"
# 订阅URL地址
for list in ${Sub_list}
do
	list="$(echo ${list} | tr -d " " | tr -d "\n")"
	[[ -n "${list}" ]] || continue
	if [ ! -n "$(echo ${Data} | grep "$(AES_D "${list}")")" ]; then
		uci add_list homeproxy.subscription.subscription_url="$(AES_D "${list}")"
	fi
done
# 直连域名
for list in ${URL_list}
do
	list="$(echo ${list} | tr -d " " | tr -d "\n")"
	[[ -n "${list}" ]] || continue
	[[ $(tail -c1 "${url_path}" 2> /dev/null | wc -w) -eq 0 ]] || echo "" >> "${url_path}"
	[[ -n "$(echo ${list_URL} | grep "${list}")" ]] || echo "${list}" >> "${url_path}"
done
# 直连IP
uci set homeproxy.control.lan_proxy_mode='except_listed'
for list in ${IP_list}
do
	list="$(echo ${list} | tr -d " " | tr -d "\n")"
	[[ -n "${list}" ]] || continue
	if [ ! -n "$(echo ${list_IP} | grep "${list}")" ]; then
		uci add_list homeproxy.control.lan_direct_ipv4_ips="${list}"
	fi
done
}

function passwall() {
url_path="/usr/share/passwall/rules/direct_host"
ip_path="/usr/share/passwall/rules/direct_ip"
list_URL=$(cat "${url_path}" 2> /dev/null)
list_IP=$(cat "${ip_path}" 2> /dev/null)
Data=$(uci -q show passwall | grep "passwall.@subscribe_list.*.url=")
Save_words="V3|香港|台湾|日本|韩国|HK|YW|JP"
num1=0
# 更改DNS
uci set passwall.@global[].remote_dns='8.8.8.8'
# 关键字删除
IFS=" " # 分割符变量
uci set passwall.@global_subscribe[].filter_keyword_mode='0'
Keywords=$(uci -q get passwall.@global_subscribe[].filter_discard_list | tr  '|' '@' | tr  ' ' '|')
for keywords in $(uci -q get passwall.@global_subscribe[].filter_discard_list)
do
	# echo ${keywords}
	uci del_list passwall.@global_subscribe[].filter_discard_list="${keywords}"
done
IFS="|" # 分割符变量
# 订阅URL地址
for data in ${Sub_list}
do
	if [ ! -n "$(echo ${Data} | grep "$(AES_D "${data}")")" ]; then
		num1=`expr $num1 + 1`
		uci_id="$(uci add passwall subscribe_list)"
		uci set passwall.${uci_id}.remark="订阅_${num1}"
		uci set passwall.${uci_id}.url="$(AES_D "${data}")"
		uci set passwall.${uci_id}.allowInsecure='0'
		uci set passwall.${uci_id}.filter_keyword_mode='2'
		uci set passwall.${uci_id}.ss_type='global'
		uci set passwall.${uci_id}.trojan_type='global'
		uci set passwall.${uci_id}.vmess_type='global'
		uci set passwall.${uci_id}.vless_type='global'
		uci set passwall.${uci_id}.hysteria2_type='global'
		uci set passwall.${uci_id}.domain_strategy='global'
		uci set passwall.${uci_id}.auto_update='1'
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
for list in ${URL_list}
do
	list="$(echo ${list} | tr -d " " | tr -d "\n")"
	[[ -n "${list}" ]] || continue
	[[ $(tail -c1 "${url_path}" 2> /dev/null | wc -w) -eq 0 ]] || echo "" >> "${url_path}"
	[[ -n "$(echo ${list_URL} | grep "${list}")" ]] || echo "${list}" >> "${url_path}"
done
# 直连IP
for list in ${IP_list}
do
	list="$(echo ${list} | tr -d " " | tr -d "\n")"
	[[ -n "${list}" ]] || continue
	[[ $(tail -c1 "${ip_path}" 2> /dev/null | wc -w) -eq 0 ]] || echo "" >> "${ip_path}"
	[[ -n "$(echo ${list_IP} | grep "${list}")" ]] || echo "${list}" >> "${ip_path}"
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
# 订阅URL地址
for data in ${Sub_list}
do
	[[ -n "$(echo ${data} | tr -d " " | tr -d "\n")" ]] || continue
	if [ ! -n "$(echo ${Data} | grep "$(AES_D "${data}")")" ]; then
		uci add_list shadowsocksr.@server_subscribe[0].subscribe_url="$(AES_D "${data}")"
	fi
done
}

function openclash() {
Data="$(uci -q show openclash)"
count="0"
#更新订阅
uci set openclash.config.auto_update="1"
uci set openclash.config.auto_update="1"
uci set openclash.config.config_update_week_time="*"
uci set openclash.config.config_auto_update_mode="0"
#使用meta内核 1,启用 0,禁用
uci set openclash.config.enable_meta_core="0"
#绕过中国大陆 IP
uci set openclash.config.china_ip_route="1"
# 仅允许内网
uci set openclash.config.intranet_allowed="1"
#本地 DNS 劫持
uci set openclash.config.enable_redirect_dns="0"
# 添加订阅
# $(echo "${data}" | sed "s|htt.*://\(.*\)\..*|\1|g") //取网址
for data in ${Sub_list}
do
	[[ -n "$(echo ${data} | tr -d " " | tr -d "\n")" ]] || continue
	if [ ! -n "$(echo ${Data} | grep "$(AES_D "${data}")")" ]; then
		count=$(( count + 1 ))
		uci_id="$(uci add openclash config_subscribe)"
		uci set openclash.${uci_id}.enabled="1"
		uci set openclash.${uci_id}.name="Clash_${count}"
		uci set openclash.${uci_id}.address="$(AES_D "${data}")"
		uci set openclash.${uci_id}.sub_convert="0"
	fi
done
}

function firewall() {
Data="$(uci -q show firewall)"
if [ -n "$(uci -q get network.MODE)" ]; then
	if [ ! -n "$(echo $(uci -q get firewall.@zone[1].network) | grep "MODE")" ]; then
		uci add_list firewall.@zone[1].network="MODE"
	fi
fi
for data  in ${Firewall}
do
	data=$(echo ${data} | tr -d " " | tr -d "\n")
	[[ -n "${data}" ]] || continue
	name="$(echo ${data} | awk -F: '{print $1}' | tr -d "\n")"
	ip="$(echo ${data} | awk -F: '{print $2}' | tr -d "\n")"
	enabled="$(echo ${data} | awk -F: '{print $3}' | tr -d "\n")"
	lan="$(echo ${data} | awk -F: '{print $4}' | tr -d "\n")"
	if [ $(echo ${data} | grep -o ":" | wc -l) -ge 4 ]; then
		wan="$(echo ${data} | awk -F: '{print $5}' | tr -d "\n")"
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
uci -q delete dhcp.lan.dhcpv6
# 删除 RA 服务删除
uci -q delete dhcp.lan.ra
# 删除 NDP 代理
uci -q delete dhcp.lan.ndp
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
uci set network.wan.ipv6="1"
}

function fstab() {
# 自动挂载未配置的Swap
uci set fstab.@global[0].anon_swap="0"
# 自动挂载未配置的磁盘
uci set fstab.@global[0].anon_mount="0"
# 自动挂载交换分区
uci set fstab.@global[0].auto_swap="0"
# 自动挂载磁盘
uci set fstab.@global[0].auto_mount="1"
# 创建共享目录
if [ ! -d "/mnt/Share" ]; then
    mkdir -p /mnt/Share
fi
# 添加挂载
for data  in ${Fstab}
do
	data=$(echo ${data} | tr -d " " | tr -d "\n")
	[[ -n "${data}" ]] || continue
	dir="$(echo ${data} | awk -F: '{print $1}')"
	uuid="$(echo ${data} | awk -F: '{print $2}')"
	uci_id="$(uci -q show fstab | grep -Eo "^fstab\.@mount.*uuid='${uuid}'" | grep -Eo "^fstab\.@mount.*\]")"
	if [ -z "${uci_id}" ]; then
		# echo "${dir} | ${uuid}"
		uci_id="$(uci add fstab mount)"
		uci set fstab.${uci_id}.target="${dir}"
		uci set fstab.${uci_id}.uuid="${uuid}"
		uci set fstab.${uci_id}.enabled="1"
	else
		uci set ${uci_id}.target="${dir}"
		uci set ${uci_id}.enabled="1"
	fi
	# 创建共享链接
	if [ ! -L "/mnt/Share/${dir##*/}" ]; then
		ln -s ${dir} /mnt/Share/
	fi
done
}

function unishare() {
Data="$(uci -q show unishare)"
uci set unishare.@global[0].enabled="1"
# 匿名用户
uci set unishare.@global[0].anonymous="0"
# webdav端口
uci set unishare.@global[0].webdav_port="8888"
# 添加用户
if [ ! -n "$(echo ${Data} | grep "$(AES_D "EGX0weODHB3uaL5bfaZuWA==")")" ]; then
	uci_id="$(uci add unishare user)"
	uci set unishare.${uci_id}.username="$(AES_D "EGX0weODHB3uaL5bfaZuWA==")"
	uci set unishare.${uci_id}.password="$(AES_D "WyeTXXm2t8gtxOgDfZH2eQ==")"	
fi
# 添加共享
for data  in ${Share}
do
	data=$(echo ${data} | tr -d " " | tr -d "\n")
	[[ -n "${data}" ]] || continue
	dir="$(echo ${data} | awk -F: '{print $1}')"
	name="$(echo ${data} | awk -F: '{print $2}')"
	if [ ! -n "$(echo ${Data} | grep "${dir}")" ]; then
		# echo "${ip} | ${name}"
		uci_id="$(uci add unishare share)"
		uci set unishare.${uci_id}.path="${dir}"
		uci set unishare.${uci_id}.name="${name}"
		uci add_list unishare.${uci_id}.rw="users"
		uci add_list unishare.${uci_id}.proto="samba"
		uci add_list unishare.${uci_id}.proto="webdav"
	fi
done
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

function sunpanel() {
uci set sunpanel.@sunpanel[0].enabled="1"
# 网页端口
uci set sunpanel.@sunpanel[0].port="88"
# 数据目录
uci set sunpanel.@sunpanel[0].config_path="/mnt/SD/Configs/SunPanel"
}

function alist() {
uci set alist.@alist[0].enabled='1'
# 创建连接
if [ -L "/etc/alist" ] || [ -d "/etc/alist" ]; then
	rm -fr "/etc/alist"
fi
ln -s /mnt/SD/Configs/alist /etc
}

function openlist() {
uci set openlist.@openlist[0].enabled='1'
if [ -L "/etc/openlist" ] || [ -d "/etc/openlist" ]; then
	rm -fr "/etc/openlist"
fi
ln -s /mnt/SD/Configs/openlist /etc
}

#========函数入口========
(cd / && {
init # 初始化脚本
Password # 获取key
IFS="|" # 分割符变量
echo -e "\e[1;32m结果:\e[0m"
for func in $(echo ${Config} | tr " " "|")
do
	#echo ${func}
	[ -n "$(uci -q show ${func})" ] && ${func} && uci commit ${func} && echo "${func}配置......OK"
    sleep 1
    Webpage "supermicro modem" && echo "Webpage配置......OK"
done
opkg_unload # 卸载插件
echo  
echo '================================='
echo '=           配置完成            ='
echo '================================='
})