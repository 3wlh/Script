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