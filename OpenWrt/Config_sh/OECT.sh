#!/bin/bash
function init {
echo -e "\e[1;36m初始化配置变量\e[0m"
#======= 初始化配置变量 =======
# 挂载 挂载目录 : uuid
Fstab="/mnt/SD : 3519c925-6c5e-7242-baa9-027d8a399db6 |
/mnt/HDD : 20e90bf5-d880-684d-a087-3786846280ea"
# 共享 共享目录 : 名称
Share="/mnt/SD : SD|
/mnt/HDD : HDD|
/mnt/SD/存储 : 文件存储"
# 配置名称
Config="fstab unishare sunpanel cloudflared openlist openlist2 frp dockerd"
}

function Password(){
key=$(ip -o link show eth0 | grep -Eo "permaddr ([0-9A-Fa-f]{2}[:]){5}([0-9A-Fa-f]{2})" |awk '{print $NF}' | tr -d '\n' | md5sum | awk '{print $1}' | cut -c9-24 | grep -v "8f00b204e9800998")
[[ -n "${key}" ]] || key=$(cat /sys/class/net/eth0/address | tr -d '\n' | md5sum | awk '{print $1}' | cut -c9-24)
echo -e "\e[1;31mKey:\e[0m\e[35m ${key} \e[0m"
}

function AES_D(){ #解密函数
[[ -z "$1" ]] || echo "$1" | openssl enc -e -aes-128-cbc -a -K ${key} -iv ${key} -base64 -d 2>/dev/null
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
if [ ! -n "$(echo ${Data} | grep "$(AES_D "m3XpP/wTU5A6CztJKgOkiw==")")" ]; then
	uci_id="$(uci add unishare user)"
	uci set unishare.${uci_id}.username="$(AES_D "m3XpP/wTU5A6CztJKgOkiw==")"
	uci set unishare.${uci_id}.password="$(AES_D "QuEQ+o09m+be88boCYodQA==")"	
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

function openlist() {
uci set openlist.@openlist[0].enabled='1'
if [ -L "/etc/openlist" ] || [ -d "/etc/openlist" ]; then
	rm -fr "/etc/openlist"
fi
ln -s /mnt/SD/Configs/openlist /etc
}

function openlist2() {
uci set openlist2.@openlist2[0].enabled='1'
uci set openlist2.@openlist2[0].data_dir='/mnt/SD/Configs/openlist'	
}

function sunpanel() {
uci set sunpanel.@sunpanel[0].enabled="1"
# 网页端口
uci set sunpanel.@sunpanel[0].port="88"
# 数据目录
uci set sunpanel.@sunpanel[0].config_path="/mnt/SD/Configs/SunPanel"
}

function cloudflared() {
token="7/ds/bf/niBXDWDA5uhBFEvSD4c/WaD7OLbtOxucVM8+6gke+CsTnCbOMLyGZ0yjaTQaJq8wpbj3ShOiS4Ga1ppTGPTHR3ut3GIIcVInqjwPK/i/FQgOaczxVVwbUcMwj8rRUl1LLrPt/GOv7Sb5ITTQu8cDXb98sxjUAbl73/EeGisDQ12zEks+NkFaqljmoDBFPtF8bCBV4cHN+/lwRLpbPS8hd8h/vYXP2Hg1qI0CIJDYxIU7QI4i5fn41g4E"
uci set cloudflared.config.enabled='1'
uci set cloudflared.config.token="$(AES_D "${token}")"
}

function dockerd() {
uci set dockerd.globals.data_root="/mnt/HDD/docker/"
# 网易云镜像站
uci add_list dockerd.globals.registry_mirrors="https://hub-mirror.c.163.com"
# 百度云镜像站
uci add_list dockerd.globals.registry_mirrors="https://mirror.baidubce.com"
# 1panel镜像站
uci add_list dockerd.globals.registry_mirrors="https://docker.1panel.live"
# DockerProxy代理加速
uci add_list dockerd.globals.registry_mirrors="https://dockerproxy.net"
# 上海交大镜像站
uci add_list dockerd.globals.registry_mirrors="https://docker.mirrors.sjtug.sjtu.edu.cn"
# 南京大学镜像站
uci add_list dockerd.globals.registry_mirrors="https://docker.nju.edu.cn"
# Daocloud镜像站
uci add_list dockerd.globals.registry_mirrors="https://docker.m.daocloud.io"
uci commit dockerd
}

function frp() {
uci set frp.common.enabled='1'
uci set frp.common.server_port='7000'
uci set frp.common.server_addr="$(AES_D "nzRMMNIm8K9XKX8i9AftXA==")"
uci set frp.common.token="$(AES_D "T35GBVxiNmd119TodyLdHDB6rGmj54dqV2XwFA/T71Q=")"
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
done
	IFS=" "
	Webpage "supermicro modem" && echo "Webpage配置......OK"
    echo  
	echo '================================='
	echo '=           配置完成            ='
	echo '================================='
})