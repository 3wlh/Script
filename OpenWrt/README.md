# OpenWrt
## 在线配置OpenWrt：
#### API配置
* 删除API
```
rm -rf /usr/share/api
``` 
* 运行在线配置命令
```
wget -qO - https://gitee.com/git_3wlh/Script/raw/master/OpenWrt/Config/Script/api.sh | bash -s <密码> <地址>
```
* 本地配置
```
wget -qO - http://10.10.10.8/confing | bash
```
```
wget -qO - http://10.10.10.8/confing_pwd | bash
```
#### 更新IP
* 一键命令
```
bash -c "$(wget -qO - https://ghproxy.net/https://raw.githubusercontent.com/3wlh/Script/main/OpenWrt/Shell/updateip.sh)"
```
```
bash -c "$(wget -qO - https://ghproxy.net/https://raw.githubusercontent.com/3wlh/Script/main/OpenWrt/Shell/updateip2.sh)"
```
#### 微信推送
* 一键命令
```
bash -c "$(wget -qO - https://ghproxy.net/https://raw.githubusercontent.com/3wlh/Script/main/OpenWrt/Shell/wxpusher.sh)"
```
#### 读取数据
* 读取序列号
```
cat /sys/devices/system/cpu/cpu0/regs/identification/midr_el1 | sed 's/00*0//g'
```
* 读取CPU序列号
```
cat /proc/cpuinfo | grep "Serial" | awk {'print $3'}
```
* 读取MAC序列号
```
cat /sys/class/net/eth0/address
```
```
ethtool -P eth0 | awk '{print $NF}' | tr -d '\n' | md5sum | awk '{print $1}' | cut -c9-24
```
* 读取软路由型号
```
cat /tmp/sysinfo/model | sed 's/ /_/g'
```

## 配置插件：
#### 插件
* Openclash_内核安装
```sh
wget -qO - https://ghproxy.net/https://raw.githubusercontent.com/3wlh/Script/main/OpenWrt/Shell/clash_core.sh | bash
```
* aliyundrive-webdav_安装
```sh
wget -qO - https://ghproxy.net/https://raw.githubusercontent.com/3wlh/Script/main/OpenWrt/Shell/aliyundrive-webdav.sh | bash
```
* alist_安装
```sh
wget -qO - https://ghproxy.net/https://raw.githubusercontent.com/3wlh/Script/main/OpenWrt/Shell/alist.sh | bash
```
* argon_img
```sh
wget -qO - https://ghproxy.net/https://raw.githubusercontent.com/3wlh/Script/main/OpenWrt/Shell/argon_img.sh | bash
```
* argon_安装
```sh
wget -qO - https://ghproxy.net/https://raw.githubusercontent.com/3wking/Script/main/OpenWrt/Shell/argon.sh | bash
```
* 小Q助手_安装
```sh
wget -qO - https://ghproxy.net/https://raw.githubusercontent.com/3wking/Script/main/OpenWrt/Shell/Assistant.sh | bash
```

## Friendlywrt：
#### 精简修改
* friendlywrt
```sh
wget -qO - https://ghproxy.net/https://raw.githubusercontent.com/3wking/Script/main/OpenWrt/friendlywrt/remove.sh | bash
```

## Orangepi：
#### 系统设置
* 修改设置
```sh
wget -qO - https://mirror.ghproxy.com/https://raw.githubusercontent.com/3wlh/Script/main/OpenWrt/Shell/Orangepi.sh | bash
```
```sh
wget -qO - https://mirror.ghproxy.com/https://raw.githubusercontent.com/3wlh/Script/main/OpenWrt/Shell/Orangepi2.sh | bash
```

