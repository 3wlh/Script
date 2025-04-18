#!/bin/bash

function AES_D(){
key=$(ip -o link show eth0 | awk '{print $NF}' | tr -d '\n' | md5sum | awk '{print $1}' | cut -c9-24)
[[ -n "${key}" ]] || key=$(cat /sys/class/net/eth0/address | tr -d '\n' | md5sum | awk '{print $1}' | cut -c9-24)
[[ -z "$1" ]] || echo "$1" | openssl enc -e -aes-128-cbc -a -K ${key} -iv ${key} -base64 -d 2>/dev/null
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
# 硬盘挂载
Data="$(uci -q show fstab)"
uuid="20b2e6c7-ab79-7e4b-a5f3-d7291d45e554"
if [ ! -n "$(echo ${Data} | grep "${uuid}")" ]; then
	uci_id="$(uci add fstab mount)"
	uci set fstab.${uci_id}.target="/mnt/data"
	uci set fstab.${uci_id}.uuid="${uuid}"
	uci set fstab.${uci_id}.enabled="1"
else
	uci_id="$(echo ${Data} | sed 's/fstab/\nfstab/g' | grep "${uuid}" | sed 's/\(.*\).uuid=.*/\1/g')"
	uci set ${uci_id}.target="/mnt/data"
	uci set ${uci_id}.enabled="1"
fi
if [ ! -L "/data" ]; then
	ln -s /mnt/data /data
fi
}

function cloudflared() {
token="qXeDZU6UzRAxSq29zXkLS2kaTPf8bwaDz2LeV7gDbeLIBJKjZWLnKBVyHMncSFTboxAK6oCPwS3wqdT8VTTCsM4M+JVo5MBGDgeku4nB6xqmH9oKv/Msq0czo2lCDS6sPG+3MTrouDFKlbagxDMt8yd35ywraLxtnNpJ+t2E/kOPZVeqPZj0bo1IjXfvyx/yMOM/kuXQhDPgmjsrXhQi9siCr/Oxn2FlxYNY/K2sn0PtT5IHANr2MJeeA5ZUlrNr"
uci set cloudflared.config.enabled='1'
uci set cloudflared.config.token="$(AES_D "${token}")"
}

function frp() {
uci set frp.common.enabled='1'
uci set frp.common.server_port='7000'
uci set frp.common.server_addr="$(AES_D "BaVVQwu7oj/RIcHQF9tfGg==")"
uci set frp.common.token="$(AES_D "u97dqchCHhR+APqtSlnzIw==")"
# 添加
Data="$(uci -q show frp)"
if [ ! -n "$(echo ${Data} | grep "NapCat_API")" ]; then
	uci_id="$(uci add frp proxy)"
	uci set frp.${uci_id}.enable='1'
	uci set frp.${uci_id}.type='tcp'
	uci set frp.${uci_id}.remote_port='8081'
	uci set frp.${uci_id}.local_ip='localhost'
	uci set frp.${uci_id}.local_port='80'
	uci set frp.${uci_id}.proxy_protocol_version='disable'
	uci set frp.${uci_id}.use_encryption='1'
	uci set frp.${uci_id}.use_compression='1'
	uci set frp.${uci_id}.remark='NapCat_API'
fi
}


Config="fstab cloudflared frp"
(cd / && {
for func  in $(echo ${Config} | sed 's/ / /g')
do
	#echo ${func}
	[ -n "$(uci -q show ${func})" ] && ${func} && uci commit ${func} && echo "${func}配置......OK"
    sleep 1
done
    echo  
	echo '================================='
	echo '=           配置完成            ='
	echo '================================='
})