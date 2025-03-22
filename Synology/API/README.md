# API
## 
## DSM7.0 root权限的api
##### install_Synoapi.spk
```sh
sudo curl -k https://ghproxy.net/https://raw.githubusercontent.com/3wking/Script/Synology/main/Shell/install_Synoapi.spk.sh | bash
```
##### install_Synoapi.cgi
```sh
sudo curl -k https://ghproxy.net/https://raw.githubusercontent.com/3wking/Script/Synology/main/Shell/install_Synoapi.cgi.sh | bash
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

##### 删除api
```sh
sudo rm -f /usr/syno/synoman/Synoapi.cgi
```
##### 查看api进程
```sh
ps aux | grep -w Synoapi | grep -v grep
```
##### 开机自启
```sh
#任务计划
sudo curl -k https://ghproxy.net/https://raw.githubusercontent.com/3wking/Script/Script/Synology/main/Shell/api.sh | bash
```