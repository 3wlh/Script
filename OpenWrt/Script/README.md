# API
## 在线配置
#### 读取序列号
```
cat /sys/devices/system/cpu/cpu0/regs/identification/midr_el1 | sed 's/00*0//g'
```
#### 读取CPU序列号
```
cat /proc/cpuinfo | grep "Serial" | awk {'print $3'}
```
#### 读取MAC序列号
```
cat /sys/class/net/eth0/address
```
#### 读取软路由型号
```
cat /tmp/sysinfo/model | sed 's/ /_/g'
```
#### 读取软路由型号配置
```
cat /tmp/sysinfo/model | sed 's/ /_/g' | cut -d "_" -f 2- | sed  's/.*/API_&.key/'
```

## 运行
#### 删除api
```
rm -f /usr/share/api/*
```
- 一键运行
```
wget -qO - https://gitee.com/git_3wlh/Script/raw/master/OpenWrt/Config/Script/api.sh | bash -s <密码> <地址>
```

- 运行命令Arm64
```
wget https://gitee.com/git_3wlh/File/raw/main/OpenWrt/api_arm64 -O /usr/share/api/api_arm64 && chmod +x /usr/share/api/api_arm64 && bash /usr/share/api/api_arm64 <密码> <地址>
```
- 运行命令Amd64
```
wget https://gitee.com/git_3wlh/File/raw/main/OpenWrt/api_amd64 -O /usr/share/api/api_amd64 && chmod +x /usr/share/api/api_amd64 && bash /usr/share/api/api_amd64 <密码> <地址>
```