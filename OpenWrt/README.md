# OpenWrt
## 在线配置OpenWrt：
#### API配置
* 删除API
```
rm -rf /usr/share/api
``` 
* 运行在线配置命令
```
wget -qO - http://3wlh.github.io/Script/OpenWrt/Script/api.sh | bash -s <密码> <地址>
```
```
wget -qO - https://gitee.com/git_3wlh/Script/raw/main/OpenWrt/Script/api.sh | bash -s <密码> <地址>
```
* 本地配置
```
bash -c "$(wget -qO - http://10.10.10.8/confing)"
```
```
bash -c "$(wget -qO - http://10.10.10.8/confing_pwd)"
```
#### 更新IP
* 一键命令
```
bash -c "$(wget -qO - http://3wlh.github.io/Script/OpenWrt/Shell/updateip.sh)"
```
```
bash -c "$(wget -qO - https://gitee.com/git_3wlh/Script/raw/main/OpenWrt/Shell/updateip.sh)"
```

```
bash -c "$(wget -qO - http://3wlh.github.io/Script/OpenWrt/Shell/updateip2.sh)"
```
```
bash -c "$(wget -qO - https://gitee.com/git_3wlh/Script/raw/main/OpenWrt/Shell/updateip2.sh)"
```
#### 微信推送
* 一键命令
```
bash -c "$(wget -qO - http://3wlh.github.io/Script/OpenWrt/Shell/wxpusher.sh)"
```
```
bash -c "$(wget -qO - https://gitee.com/git_3wlh/Script/raw/main/OpenWrt/Shell/wxpusher.sh)"
```

#### RustDesk
* key
```
bash -c "$(wget -qO - http://3wlh.github.io/Script/OpenWrt/Shell/RustDesk.sh)"
```
```
bash -c "$(wget -qO - https://gitee.com/git_3wlh/Script/raw/main/OpenWrt/Shell/RustDesk.sh)"
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
cat /sys/class/net/eth0/address | tr -d '\n' | md5sum | awk '{print $1}' | cut -c9-24
```
```
ip -o link show eth0 | awk '{print $NF}' | tr -d '\n' | md5sum | awk '{print $1}' | cut -c9-24
```
* 自动读取MAC序列号
```
bash -c "$(wget -qO - http://3wlh.github.io/Script/OpenWrt/Shell/Getmac.sh)"
```
```
bash -c "$(wget -qO - https://gitee.com/git_3wlh/Script/raw/main/OpenWrt/Shell/Getmac.sh)"
```
* 读取软路由型号
```
cat /tmp/sysinfo/model | sed 's/ /_/g'
```

## 配置插件：
#### 插件
* Openclash_内核安装
```
bash -c "$(wget -qO - http://3wlh.github.io/Script/OpenWrt/Shell/clash_core.sh)"
```
```
bash -c "$(wget -qO - https://gitee.com/git_3wlh/Script/raw/main/OpenWrt/Shell/clash_core.sh)"
```
* aliyundrive-webdav_安装
```
bash -c "$(wget -qO - http://3wlh.github.io/Script/OpenWrt/Shell/aliyundrive-webdav.sh)"
```
```
bash -c "$(wget -qO - https://gitee.com/git_3wlh/Script/raw/main/OpenWrt/Shell/aliyundrive-webdav.sh)"
```
* alist_安装
```
bash -c "$(wget -qO - http://3wlh.github.io/Script/OpenWrt/Shell/alist.sh)"
```
```
bash -c "$(wget -qO - https://gitee.com/git_3wlh/Script/raw/main/OpenWrt/Shell/alist.sh)"
```
* argon_img
```sh
bash -c "$(wget -qO - http://3wlh.github.io/Script/OpenWrt/Shell/argon_img.sh)"
```
```
bash -c "$(wget -qO - https://gitee.com/git_3wlh/Script/raw/main/OpenWrt/Shell/argon_img.sh)"
```
* argon_安装
```
bash -c "$(wget -qO - http://3wlh.github.io/Script/OpenWrt/Shell/argon.sh)"
```
```
bash -c "$(wget -qO - https://gitee.com/git_3wlh/Script/raw/main/OpenWrt/Shell/argon.sh)"
```

## Friendlywrt：
#### 精简修改
* friendlywrt
```
bash -c "$(wget -qO - http://3wlh.github.io/Script/OpenWrt/friendlywrt/remove.sh)"
```
```
bash -c "$(wget -qO - https://gitee.com/git_3wlh/Script/raw/main/OpenWrt/Shell/remove.sh)"
```
## Orangepi：
#### 系统设置
* 修改设置
```
bash -c "$(wget -qO - http://3wlh.github.io/Script/OpenWrt/Shell/Orangepi.sh)"
```
```
bash -c "$(wget -qO - https://gitee.com/git_3wlh/Script/raw/main/OpenWrt/Shell/Orangepi.sh)"
```
```
bash -c "$(wget -qO - http://3wlh.github.io/Script/OpenWrt/Shell/Orangepi2.sh)"
```
```
bash -c "$(wget -qO - https://gitee.com/git_3wlh/Script/raw/main/OpenWrt/Shell/Orangepi2.sh)"
```

