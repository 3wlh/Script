#!/bin/bash

function AES_D(){
key=$(ip -o link show eth0 | awk '{print $NF}' | tr -d '\n' | md5sum | awk '{print $1}' | cut -c9-24)
[[ -n "${key}" ]] || key=$(cat /sys/class/net/eth0/address | tr -d '\n' | md5sum | awk '{print $1}' | cut -c9-24)
# $(echo "${text}" | openssl enc -e -aes-128-cbc -a -K ${key} -iv ${key} -nosalt 2>/dev/null) //加密
# $(echo "${encrypt_str}" | openssl enc -e -aes-128-cbc -a -K ${key} -iv ${key} -nosalt -d 2>/dev/null) //解密
[[ -z "$1" ]] || echo "$1" | openssl enc -e -aes-128-cbc -a -K ${key} -iv ${key} -nosalt -d 2>/dev/null
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
token="aNuV2nQ24o8IftLNtKxPkaWW1WQvwIeFRFkQ9f6g0JbtQ7XWGJEfDmCGRY5IAfls
3VND+w6L/1xUzLejs7EjEDCdC8RWapNK4T4zKOgivNpWY7JUCZYydAq1mQV3l5T8
Klntxzk0W3V7O8loDWJx6AekQeO+uLOYl0V3lstI0dJqxerhnGrKd7lTjV4glVdJ
ilb/8+DnAdH5tr50WbT4rjdrjXyIxjkgL6C/rGq/WoSj0C/hnIXuDtxDjKGwudHL"
uci set cloudflared.config.enabled='1'
uci set cloudflared.config.token="$(AES_D "${token}")"
}

Config="fstab cloudflared"
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