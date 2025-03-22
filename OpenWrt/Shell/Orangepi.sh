#!/bin/sh

RED_COLOR='\e[1;31m' #红色
GREEN_COLOR='\e[1;32m' #绿色
RES='\e[0m' #尾

# 卸载插件
function Uninstall () {
	# 上网时间控制
	echo -e "\r\n${RED_COLOR}remove luci-app-accesscontrol（1/23）${RES}\r\n"	
	opkg remove luci-app-accesscontrol --force-removal-of-dependent-packages --autoremove
	# 广告过滤
	echo -e "\r\n${RED_COLOR}remove luci-app-adbyby-plus（2/23）${RES}\r\n"	
	opkg remove luci-app-adbyby-plus --force-removal-of-dependent-packages --autoremove
	# AirPlay播放音频
	echo -e "\r\n${RED_COLOR}remove luci-app-airconnect（3/23）${RES}\r\n"	
	opkg remove	luci-app-airconnect --force-removal-of-dependent-packages --autoremove
	# mac绑定
	echo -e "\r\n${RED_COLOR}remove luci-app-arpbind（4/23）${RES}\r\n"	
	opkg remove luci-app-arpbind --force-removal-of-dependent-packages --autoremove
	# ddns解析
	echo -e "\r\n${RED_COLOR}remove luci-app-ddns（5/23）${RES}\r\n"	
	opkg remove luci-app-ddns --force-removal-of-dependent-packages --autoremove
	# 文件传输
	echo -e "\r\n${RED_COLOR}remove luci-app-filetransfer（6/23）${RES}\r\n"	
	opkg remove luci-app-filetransfer --force-removal-of-dependent-packages --autoremove
	# IPSec VPN 服务器
	echo -e "\r\n${RED_COLOR}remove luci-app-ipsec-server（7/23）${RES}\r\n"	
	opkg remove luci-app-ipsec-server --force-removal-of-dependent-packages --autoremove
	# Multi Stream Daemon Lite
	echo -e "\r\n${RED_COLOR}remove luci-app-msd_lite（8/23）${RES}\r\n"	
	opkg remove luci-app-msd_lite --force-removal-of-dependent-packages --autoremove
	# OpenClash
	echo -e "\r\n${RED_COLOR}remove luci-app-openclash（9/23）${RES}\r\n"	
	opkg remove luci-app-openclash --force-removal-of-dependent-packages --autoremove
	luci-app-openvpn-server
	# OpenVPN 服务器
	echo -e "\r\n${RED_COLOR}remove luci-app-openvpn-server（10/23）${RES}\r\n"	
	opkg remove luci-app-openvpn-server --force-removal-of-dependent-packages --autoremove
	# PPTP VPN 服务器
	echo -e "\r\n${RED_COLOR}remove luci-app-pptp-server（11/23）${RES}\r\n"	
	opkg remove luci-app-pptp-server --force-removal-of-dependent-packages --autoremove
	# 网络共享
	echo -e "\r\n${RED_COLOR}remove luci-app-samba（12/23）${RES}\r\n"	
	opkg remove luci-app-samba --force-removal-of-dependent-packages --autoremove
	# 智能队列管理
	echo -e "\r\n${RED_COLOR}remove luci-app-sqm（13/23）${RES}\r\n"	
	opkg remove luci-app-sqm --force-removal-of-dependent-packages --autoremove
	# ShadowSocksR Plus+
	echo -e "\r\n${RED_COLOR}remove luci-app-ssr-plus（14/23）${RES}\r\n"	
	opkg remove luci-app-ssr-plus --force-removal-of-dependent-packages --autoremove
	# Turbo ACC 网络加速
	echo -e "\r\n${RED_COLOR}remove luci-app-turboacc（15/23）${RES}\r\n"	
	opkg remove luci-app-turboacc --force-removal-of-dependent-packages --autoremove
	# UPnP服务
	echo -e "\r\n${RED_COLOR}remove luci-app-upnp（16/23）${RES}\r\n"	
	opkg remove luci-app-upnp --force-removal-of-dependent-packages --autoremove
	# USB 打印服务器
	echo -e "\r\n${RED_COLOR}remove luci-app-usb-printer（17/23）${RES}\r\n"	
	opkg remove luci-app-usb-printer --force-removal-of-dependent-packages --autoremove
	# KMS 服务器
	echo -e "\r\n${RED_COLOR}remove luci-app-vlmcsd（18/23）${RES}\r\n"	
	opkg remove luci-app-vlmcsd --force-removal-of-dependent-packages --autoremove
	# FTP 服务器
	echo -e "\r\n${RED_COLOR}remove luci-app-vsftpd（19/23）${RES}\r\n"	
	opkg remove luci-app-vsftpd --force-removal-of-dependent-packages --autoremove
	# WireGuard Status
	echo -e "\r\n${RED_COLOR}remove luci-app-wireguard（20/23）${RES}\r\n"	
	opkg remove luci-app-wireguard --force-removal-of-dependent-packages --autoremove
	# 路由器设置向导
	echo -e "\r\n${RED_COLOR}remove luci-app-wizard（21/23）${RES}\r\n"	
	opkg remove luci-app-wizard --force-removal-of-dependent-packages --autoremove
	# 网络唤醒
	echo -e "\r\n${RED_COLOR}remove luci-app-wol（22/23）${RES}\r\n"	
	opkg remove *wol* --force-removal-of-dependent-packages --autoremove
	# ZeroTier
	echo -e "\r\n${RED_COLOR}remove luci-app-zerotier（23/23）${RES}\r\n"	
	opkg remove luci-app-zerotier --force-removal-of-dependent-packages --autoremove
}

# 添加插件源
function Add_Source () {
opkg="/etc/opkg/customfeeds.conf"	
if ! grep -q "openwrt_kiddin9" $opkg; then
  sed -i '$a\src/gz openwrt_kiddin9 https://dl.openwrt.ai/latest/packages/aarch64_generic/kiddin9' $opkg
fi
conf="/etc/opkg.conf"
conf="/etc/opkg.conf"
if ! grep -q "arch all" $conf; then
  sed -i '$a\arch aarch64_generic 100' $conf
fi
if ! grep -q "arch all" $conf; then
  sed -i '$a\arch all 200' $conf
fi	
}

# 设置旁路由
function Set () {
Fstab="/etc/config/fstab"
DHCP="/etc/config/dhcp"
Network="/etc/config/network"
System="/etc/config/system"

#========Fstab========
# 更改挂挂载选项
sed -i "s|option anon_swap .*|option anon_swap '0'|g" $Fstab
sed -i "s|option anon_mount .*|option anon_mount '0'|g" $Fstab
sed -i "s|option auto_swap .*|option auto_swap '0'|g" $Fstab
sed -i "s|option auto_mount .*|option auto_mount '1'|g" $Fstab
#========Network========
# 禁用 DHCP 分配
sed -i "/option dhcpv4 'server'/a\	option ignore '1'" $Network
sed -i "/option ignore '1'/a\	option dynamicdhcp '0'" $Network
# 添加 网关 和 DNS
sed -i "s/192.168.1.1/10.10.10.5/" $Network
if ! grep -q "option gateway '10.10.10.254'" $Network; then
	sed -i "/option ip6assign '60'/a\	option gateway '10.10.10.254'" $Network
fi
if ! grep -q "list dns '10.10.10.254'" $Network; then
	sed -i "/option gateway '10.10.10.254'/a\	list dns '10.10.10.254'" $Network
fi
# 以下是旁路由模式
# 删除 WAN 口
WAN=$((`awk "/con.*'wan'/{print NR}" $Network`))  && sed -i "${WAN},$(($WAN+3))d" $Network
# 删除 WAN6 口
WAN6=$((`awk "/con.*'wan6'/{print NR}" $Network`))  && sed -i "${WAN6},$(($WAN6+3))d" $Network
# 删除 dev 口
dev=$((`awk "/con.*'wan_eth1_dev'/{print NR}" $Network`))  && sed -i "${dev},$(($dev+3))d" $Network
# 删除 vpn 口
vpn=$((`awk "/con.*'vpn0'/{print NR}" $Network`))  && sed -i "${vpn},$(($vpn+3))d" $Network
# 删除 ipsec 口
ipsec=$((`awk "/con.*'ipsec_server'/{print NR}" $Network`))  && sed -i "${ipsec},$(($ipsec+6))d" $Network
# 添加 eth1 到LAN 口
sed -i "s/option ifname 'eth.*'/option ifname 'eth0 eth1'/g" $Network

#========DHCP========
# 禁用 ipv6_DHCP
sed -i "/config dhcp 'lan'/a\	option dynamicdhcp '0'" $DHCP
sed -i "/option dhcpv6 'hybrid'/d" $DHCP
sed -i "/option ra 'hybrid'/d" $DHCP
sed -i "/option ra_slaac '1'/d" $DHCP
sed -i "/list ra_flags 'managed-config'/d" $DHCP
sed -i "/list ra_flags 'other-config'/d" $DHCP
sed -i "/option ndp 'hybrid'/d" $DHCP
sed -i "/option force '1'/d" $DHCP
# 不提供DHCP服务
sed -i "/option dhcpv4 'server'/a\	option ignore '1'" $DHCP

#========System========
if ! grep -q "option name 'Blue'" $System; then
cat >>$System<<EOF

config led
	option name 'Blue'
	option sysfs 'blue:indicator-1'
	option trigger 'none'
	option default '0'
	
EOF
fi
if ! grep -q "ooption name 'Green'" $System; then
cat >>$System<<EOF

config led
	option name 'Green'
	option sysfs 'green:indicator-2'
	option trigger 'none'
	option default '0'

EOF
fi
}

#========函数入口========
(cd / && {
	Uninstall && echo -e "\r\n${GREEN_COLOR}卸载自带插件......OK${RES}\r\n" &
    sleep 1
    Add_Source && echo -e "\r\n${GREEN_COLOR}添加插件源......OK${RES}\r\n" &
    sleep 1
    Set && echo -e "\r\n${GREEN_COLOR}设置旁路游模式......OK${RES}\r\n" &
    sleep 1
    sleep 4
    echo  
	echo '================================='
	echo '=           配置完成            ='
	echo '================================='
	echo '=        重启软路由生效         ='
	echo '================================='
})
