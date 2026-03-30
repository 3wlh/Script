#/bin/bash
# ip=\$(wget -qO - http://members.3322.org/dyndns/getip)
if [ -z "$(echo ${2} | grep ".*wan")" ];then
	exit
fi
log="/tmp/log/netlink.log"
url="http://ip.660101.xyz"
time=$(date +"[%Y_%m_%d %H:%M:%S][${url}]")
pwd=$(ip -o link show eth0 | awk '{print $NF}' | tr -d '\n' | md5sum | awk '{print $1}' | cut -c9-24)
ip=$(ubus call network.interface.wan status | grep \"address\" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')


while :
do
result=$(wget -qO - "${url}/update.php?ip=${ip}&pwd=${pwd}")
if [ -n "$(echo ${result} | grep "数据保存完成")" ]; then
	echo "${time} update:${ip}" >> ${log}
	echo "更新IP完成"
	break
fi
sleep 5m
done