# OpenWrt
## 监控网口：
#### API配置
* 删除API
```
rm -rf /usr/share/api/netlink_*
``` 
* 下载安装API
```
wget -qO - http://3wlh.github.io/Script/OpenWrt/sh/config.sh | bash
```
```
wget -qO - https://gitee.com/git_3wlh/Script/raw/main/OpenWrt/sh/config.sh | bash
```
* 脚本下载
####
```
mkdir -p /usr/share/ip/
```
#### 
```
wget -qO /usr/share/ip/ https://gitee.com/git_3wlh/Script/raw/main/OpenWrt/sh/API_qqpush.sh
```
#### 
```
wget -qO /usr/share/ip/ https://gitee.com/git_3wlh/Script/raw/main/OpenWrt/sh/API_wxpush.sh
```
####
```
wget -qO /usr/share/ip/ https://gitee.com/git_3wlh/Script/raw/main/OpenWrt/sh/API_updateip1.sh
```
#### 
```
wget -qO /usr/share/ip/ https://gitee.com/git_3wlh/Script/raw/main/OpenWrt/sh/API_updateip2.sh
```