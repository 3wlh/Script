#!/bin/bash
if [ -n "$(ip -o link show eth0 | grep -n 'permaddr')"];then
	echo "ip -o link show eth0"
	echo $(ip -o link show eth0 | awk '{print $NF}' | tr -d '\n' | md5sum | awk '{print $1}' | cut -c9-24)
else
	echo "/sys/class/net/eth0/address"
	echo $(cat /sys/class/net/eth0/address | awk '{print $NF}' | tr -d '\n' | md5sum | awk '{print $1}' | cut -c9-24)
fi
