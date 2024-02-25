# API
## 在线配置
###### 读取序列号
```
cat /sys/devices/system/cpu/cpu0/regs/identification/midr_el1 | sed 's/00*0//g'
```
###### 读取CPU序列号
```
cat /proc/cpuinfo | grep "Serial" | awk {'print $3'}
```
###### 读取MAC序列号
```
cat /sys/class/net/eth0/address
```
###### 读取软路由型号
```
cat /tmp/sysinfo/model | sed 's/ /_/g'
```
## 运行
###### 删除api
```
rm -f /usr/share/api/*
```
###### 一键运行
```
export pwd=<密码> && wget -qO - https://ghproxy.net/https://raw.githubusercontent.com/3wlh/OpenWrt/main/OpenWrt/Config/Script/api.sh | bash
```

###### 运行命令
```
wget https://ghproxy.net/https://raw.githubusercontent.com/3wlh/Script/main/OpenWrt/Config/api_arm64 -O api_arm64 && chmod +x api_arm64 && ./api_arm64 https://ghproxy.net/https://raw.githubusercontent.com/3wlh/Script/main/OpenWrt/Config/config/api_serial
```