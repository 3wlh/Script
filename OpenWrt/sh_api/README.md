# OpenWrt
## 监控网口：
#### API配置
* 删除API
```
rm -rf /usr/share/ip/netlink_*
``` 
* 下载安装API
```
wget -qO - http://3wlh.github.io/Script/OpenWrt/sh_api/config.sh | bash
```
```
wget -qO - https://gitee.com/git_3wlh/Script/raw/main/OpenWrt/sh_api/config.sh | bash
```
* 

* 脚本下载
####
```
mkdir -p /usr/share/ip/
```
#### SH
```
wget -qP /usr/share/ip/ http://3wlh.github.io/Script/OpenWrt/sh_api/API_qqpush.sh --show-progress \
wget -qP /usr/share/ip/ http://3wlh.github.io/Script/OpenWrt/sh_api/API_wxpush.sh --show-progress \
wget -qP /usr/share/ip/ http://3wlh.github.io/Script/OpenWrt/sh_api/API_updateip1.sh --show-progress \
wget -qP /usr/share/ip/ http://3wlh.github.io/Script/OpenWrt/sh_api/API_updateip2.sh --show-progress
```
