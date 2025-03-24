# OpenWrt
## 监控网口：
#### API配置
* 删除API
```
rm -rf /usr/share/ip/netlink_*
``` 
* 下载安装API
```
wget -qO - http://3wlh.github.io/Script/OpenWrt/sh/config.sh | bash

wget -qP /usr/share/ip/ http://file.11121314.xyz/OpenWrt/netlink_arm64 --show-progress && \
chmod +x /usr/share/ip/netlink_arm64 && /usr/share/ip/netlink_arm64 -install &

```
```
wget -qO - https://gitee.com/git_3wlh/Script/raw/main/OpenWrt/sh/config.sh | bash
```
* 

* 脚本下载
####
```
mkdir -p /usr/share/ip/
```
#### SH
```
wget -qP /usr/share/ip/ http://3wlh.github.io/Script/OpenWrt/sh/API_qqpush.sh --show-progress \
wget -qP /usr/share/ip/ http://3wlh.github.io/Script/OpenWrt/sh/API_wxpush.sh --show-progress \
wget -qP /usr/share/ip/ http://3wlh.github.io/Script/OpenWrt/sh/API_updateip1.sh --show-progress \
wget -qP /usr/share/ip/ http://3wlh.github.io/Script/OpenWrt/sh/API_updateip2.sh --show-progress
```
