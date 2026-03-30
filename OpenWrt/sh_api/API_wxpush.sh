#/bin/bash
if [ -z "$(echo ${2} | grep ".*wan")" ];then
	exit
fi
function AES_D(){ #解密函数
key=$(ip -o link show eth0 | awk '{print $NF}' | tr -d '\n' | md5sum | awk '{print $1}' | cut -c9-24)
[[ -n "${key}" ]] || key=$(cat /sys/class/net/eth0/address | tr -d '\n' | md5sum | awk '{print $1}' | cut -c9-24)
# $(echo "${text}" | openssl enc -e -aes-128-cbc -a -K ${key} -iv ${key} -base64 2>/dev/null) //加密
# $(echo "${encrypt_str}" | openssl enc -e -aes-128-cbc -a -K ${key} -iv ${key} -base64 -d 2>/dev/null) //解密
[[ -z "$1" ]] || echo "$1" | openssl enc -e -aes-128-cbc -a -K ${key} -iv ${key} -base64 -d 2>/dev/null
}
echo "开始推送消息"
sleep 1m
URL="https://wxpusher.zjiecode.com/api/send/message/";
stp="TF6/gRp4MVkHKpFTXzu8Ixn4MQ40DuKSE6emw76AGEJqzpaFWxiRW+q+o27RbCvG";
appToken="QdXu0GEivja9qclhpAvyt3HCED7AntrCYWxyjJfnBBb83+otFpdfPTh0wuMwgXCK";
uid="r2mrpgaFBOknbV2clDSl+gaGLrcxVZZH1+KGI4NdXpORQkT/XFRWTUqTWV6qOp+/";
ip=$(ubus call network.interface.wan status | grep \"address\" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
data="${URL}?appToken=$(AES_D "${appToken}")&uid=$(AES_D "${uid}")&content=IP:%20${ip}"
echo $(curl -s -X GET $data)