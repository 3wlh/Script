#!/bin/bash
Key="${1}"
function init {
echo "初始化配置变量"
#======= 初始化配置变量 =======
# 挂载 挂载目录 : uuid
Fstab="/mnt/SD : 3519c925-6c5e-7242-baa9-027d8a399db6 |
/mnt/HDD : 20e90bf5-d880-684d-a087-3786846280ea"
# 共享 共享目录 : 名称
Share="/mnt/SD : SD|
/mnt/HDD : HDD|
/mnt/SD/存储 : 文件存储"
# 配置名称
Config="cloudflared openlist openlist2"
}

function AES_D(){ #解密函数
[[ -z "$1" ]] || echo "$1" | openssl enc -e -aes-128-cbc -a -K ${Key} -iv ${Key} -base64 -d 2>/dev/nul
}

function cloudflared() {
token="7/ds/bf/niBXDWDA5uhBFEvSD4c/WaD7OLbtOxucVM8+6gke+CsTnCbOMLyGZ0yjaTQaJq8wpbj3ShOiS4Ga1ppTGPTHR3ut3GIIcVInqjwPK/i/FQgOaczxVVwbUcMwj8rRUl1LLrPt/GOv7Sb5ITTQu8cDXb98sxjUAbl73/EeGisDQ12zEks+NkFaqljmoDBFPtF8bCBV4cHN+/lwRLpbPS8hd8h/vYXP2Hg1qI0CIJDYxIU7QI4i5fn41g4E"
echo $(AES_D "${token}")
}

function frp() {
echo $(AES_D "${token}")$(AES_D "nzRMMNIm8K9XKX8i9AftXA==")
echo $(AES_D "${token}")$(AES_D "T35GBVxiNmd119TodyLdHDB6rGmj54dqV2XwFA/T71Q=")
}
(cd / && {
init # 初始化脚本
Password # 获取key
IFS="|" # 分割符变量
echo -e "结果:"
for func in $(echo ${Config} | tr " " "|")
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