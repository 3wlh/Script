#!/bin/bash
key=$(ip -o link show eth0 | awk '{print $NF}' | tr -d '\n' | md5sum | awk '{print $1}' | cut -c9-24)
[[ -n "${key}" ]] || key=$(cat /sys/class/net/eth0/address | tr -d '\n' | md5sum | awk '{print $1}' | cut -c9-24)
# $(echo "${text}" | openssl enc -e -aes-128-cbc -a -K ${key} -iv ${key} -base64 2>/dev/null) //加密
# $(echo "${encrypt_str}" | openssl enc -e -aes-128-cbc -a -K ${key} -iv ${key} -base64 -d 2>/dev/null) //解密
[[ -z "$1" ]] || echo $(echo "$1" | openssl enc -e -aes-128-cbc -a -K ${key} -iv ${key} -base64 2>/dev/null)
