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
###### 一键运行
```
export pwd=<密码> && wget -qO - https://github.cooluc.com/https://raw.githubusercontent.com/3wking/OpenWrt/main/Config/Script/api.sh | bash
```

###### 运行命令
```
wget https://github.cooluc.com/https://raw.githubusercontent.com/3wking/OpenWrt/main/Config/api_arm64 -O api_arm64 && chmod +x api_arm64 && ./api_arm64 https://github.cooluc.com/https://raw.githubusercontent.com/3wking/OpenWrt/main/Config/config/api_serial
```