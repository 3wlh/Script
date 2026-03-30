# Synology
## DSM7.0 root权限的api
##### install_Synoapi.spk
```sh
sudo bash -c "$(wget -qO - http://3wlh.github.io/Script/Synology/Shell/install_Synoapi.spk.sh)"
```
```
sudo bash -c "$(wget -qO - https://gitee.com/git_3wlh/Script/raw/main/Synology/Shell/install_Synoapi.spk.sh)"
```
##### install_Synoapi.cgi
```sh
sudo bash -c "$(wget -qO - http://3wlh.github.io/Script/Synology/Shell/install_Synoapi.cgi.sh)"
```
```
sudo bash -c "$(wget -qO - https://gitee.com/git_3wlh/Script/raw/main/Synology/Shell/install_Synoapi.cgi.sh)"
```


##### 套件调用api
```sh
#preinst  //自带服务端
api_url="http://127.0.0.1:5"
status_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST $api_url)
if [[ $status_code == 200 ]]; then
	dir=$(cd `dirname $0`;pwd)
	privilege="`echo $dir | awk -F '/scripts' '{print $1}'`/conf/privilege"
	ret=$(curl -d "dir=$privilege" -X POST $api_url)
	if [[ $ret != "OK" ]]; then
		echo "<br><p style=\"color:red;\">调用api失败.</p>"
		echo "<p style=\"color:red;\">退出安装.</p>"
		exit 1
	fi
else
	echo "<br><p style=\"color:red;\">未启用api.</p>"
	echo "<p style=\"color:red;\">退出安装.</p>"
	exit 1
	fi
```

##### 调用api
```sh
#preinst  //系统服务端
api_url="http://127.0.0.1:5000/Synoapi.cgi"
status_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST $api_url)
if [[ $status_code == 200 ]]; then
	dir=$(cd `dirname $0`;pwd)
	privilege="`echo $dir | awk -F '/scripts' '{print $1}'`/conf/privilege"
	ret=$(curl -d "dir=$privilege" -X POST $api_url)
	if ! echo $ret | grep "OK" >/dev/null 2>&1; then
		echo "<br><p style=\"color:red;\">调用api失败.</p>"
		echo "<p style=\"color:red;\">退出安装.</p>"
		exit 1
	fi
else
	echo "<br><p style=\"color:red;\">未启用api.</p>"
	echo "<p style=\"color:red;\">退出安装.</p>"
	exit 1
	fi
```
## 硬盘无法休眠
###### 建立开机脚本，开机时将日志恢复到内存
```
if [ ! -d "/var/logbak" ]; then
     mkdir /var/logbak
     cp -a -f /var/log/.  /var/logbak/
fi
cp -a -f /var/logbak/.  /tmp/log/
mount -B /tmp/log  /var/log
```
###### 建立关机脚本，关机时将日志从内存写到备份目录
```
cp -a -f /tmp/log/.     /var/logbak
```
## 其他命令
##### 卸载无用套件
```sh
sudo synopkg uninstall QuickConnect
sudo synopkg uninstall HybridShare
sudo synopkg uninstall OAuthService
sudo synopkg uninstall SecureSignIn
```
##### 添加网口
```sh
bash -c "$(wget -qO - http://3wlh.github.io/Script/Synology/Shell/Network.sh)"
```
```
bash -c "$(wget -qO - https://gitee.com/git_3wlh/Script/raw/main/Synology/Shell/Network.sh)"
```
##### 查找进程
```sh
if ! ps aux | grep -w Synoapi | grep -v grep >/dev/null 2>&1
then
//进程不存在
fi
```

#### 群晖7.2登录_透明
```
<style type="text/css"> .tab-panel {background: rgba(255,255,255,0.8) !important;} .login-textfield .input-container input { background-color: transparent !important; } body {-webkit-filter:brightness(1); -o-filter:brightness(1); -moz-filter:brightness(1); filter:brightness(1);} </style>
```