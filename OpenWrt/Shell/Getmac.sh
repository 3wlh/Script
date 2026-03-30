#!/bin/bash
if [ -n "$(ip -o link show eth0 | grep 'permaddr')" ];then
	echo "MAC: $(ip -o link show eth0 | awk '{print $NF}')"
	echo $(ip -o link show eth0 | awk '{print $NF}' | tr -d '\n' | md5sum | awk '{print $1}' | cut -c9-24)
else
	echo "MAC: $(cat /sys/class/net/eth0/address)"
	echo $(cat /sys/class/net/eth0/address | tr -d '\n' | md5sum | awk '{print $1}' | cut -c9-24)
fi
