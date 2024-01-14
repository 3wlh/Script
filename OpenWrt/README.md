# OpenWrt
## 在线编译 ：
#### 
* [在线编译教程](/Compile/Online/README.md)
* [友善R6S](/Compile/Online/R6S.md)
* [斐讯N1](/Compile/Online/N1.md)

## 本地编译 ：
#### 环境安装：
```sh
wget -O - https://github.cooluc.com/https://raw.githubusercontent.com/3wking/OpenWrt/main/Compile/Local_Compilation/env.sh | bash
```
* [OpenWrt插件名](/Compile/Local/Pluginqa_Name.txt)
* [OpenWrt插件管理](/Compile/Local/Plug-ina_Manager.txt)
#### 本地编译教程：
* [LEDE](/Compile/Local/LEDE.md)
* [immortalwrt](/Compile/Local/immortalwrt.md)
* [openwrt-redmi](/Compile/Local/openwrt-redmi.md)

## Friendlywrt ：
##### 精简修改friendlywrt
```sh
curl -k https://github.cooluc.com/https://raw.githubusercontent.com/3wking/OpenWrt/main/friendlywrt/remove.sh | bash
```
##### 修改配置
```sh
curl -k https://github.cooluc.com/https://raw.githubusercontent.com/3wking/OpenWrt/main/OpenWrt/config.sh | bash
```

## 插件 ：
##### Openclash_内核安装
```sh
curl -k https://github.cooluc.com/https://raw.githubusercontent.com/3wking/OpenWrt/main/Shell/clash_core.sh | bash
```
##### aliyundrive-webdav_安装
```sh
curl -k https://github.cooluc.com/https://raw.githubusercontent.com/3wking/OpenWrt/main/Shell/aliyundrive-webdav.sh | bash
```
##### alist_安装
```sh
curl -k https://github.cooluc.com/https://raw.githubusercontent.com/3wking/OpenWrt/main/Shell/alist.sh | bash
```
##### argon_img
```sh
curl -k https://github.cooluc.com/https://raw.githubusercontent.com/3wking/OpenWrt/main/Shell/argon_img.sh | bash
```
##### argon_安装
```sh
curl -k https://github.cooluc.com/https://raw.githubusercontent.com/3wking/OpenWrt/main/Shell/argon.sh | bash
```
##### 小Q助手_安装
```sh
curl -k https://github.cooluc.com/https://raw.githubusercontent.com/3wking/OpenWrt/main/Shell/Assistant.sh | bash
```

## 配置
#### 运行命令
```
export pwd=<密码> && wget -qO - https://github.cooluc.com/https://raw.githubusercontent.com/3wking/OpenWrt/main/Config/api.sh | bash
```
```
wget https://github.cooluc.com/https://raw.githubusercontent.com/3wking/OpenWrt/main/Config/api_arm64 -O api_arm64 && chmod +x api_arm64 && ./api_arm64 https://github.cooluc.com/https://raw.githubusercontent.com/3wking/OpenWrt/main/Config/config/api_serial
```

## 在线配置
###### 读取序列号
```
cat /sys/devices/system/cpu/cpu0/regs/identification/midr_el1 | sed 's/00*0//g'
```
```
cat /proc/cpuinfo | grep "Serial" | awk {'print $3'}
```
```
cat /sys/class/net/eth0/address
```

```
cat /proc/cpuinfo | grep "Serial" | awk {'print $3'} | tr 'a-z' 'A-Z'
```
###### 安装命令
```
curl -k https://github.cooluc.com/https://raw.githubusercontent.com/3wking/OpenWrt/main/openwrt/api/auto_config.sh | bash
```
```
curl -k https://github.cooluc.com/https://raw.githubusercontent.com/3wking/OpenWrt/main/openwrt/api/auto_config1.sh | bash
```
```
/etc/init.d/Auto_API disable & rm -rf /etc/init.d/Auto_API & rm -rf /usr/bin/Auto_Config & rm -rf /root/Auto_Config.log
```

###### 系统初始化
```
#!/bin/bash
dir="/etc/init.d/config"
# 写入开机启动
cat > $dir <<'EOF'
#!/bin/sh /etc/rc.common

START=99
STOP=15
dir="/usr/bin/"
name="config"

start() {
  echo start
  while :
	do
	ping -c 1 github.cooluc.com > /dev/null 2>&1
		if [ $? -eq 0 ]
		then
			echo 检测网络正常
			# 判断文件
			if [ -e dir ]
			then
				# 运行文件
				chmod +x $dir$name
				cd $dir && ./$name
				if [ $? -eq 0 ];then
					rm -f $dir$name
					break
				fi	
			else
				# 下载文件
				wget https://github.cooluc.com/https://raw.githubusercontent.com/3wking/OpenWrt/main/openwrt/api/config -O $dir$name
				if [ $? -eq 0 ];then
					# 运行文件
					chmod +x $dir$name
					cd $dir && ./$name
					if [ $? -eq 0 ];then
						rm -f $dir$name
						break
					fi	
				fi	
			fi
		else
			echo 检测网络连接异常
		fi
	sleep 5
	done
	#删除自启动
	/etc/init.d/config disable
	#删除服务文件
	rm -f /etc/init.d/config
}
EOF
#给予运行权限
chmod +x /etc/init.d/config
#创建自启动
/etc/init.d/config enable
```

###### 开机自起配置
```
#!/bin/sh /etc/rc.common
START=99
STOP=15

start() {
  echo start
  dir="/usr/bin/"
  name="config-api"
  while :
	do
	ping -c 1 github.cooluc.com > /dev/null 2>&1
		if [ $? -eq 0 ]
		then
			echo 检测网络正常
			# 启动的命令
			# wget -O - https://github.cooluc.com/https://raw.githubusercontent.com/3wking/OpenWrt/main/Shell/clash_core.sh | bash
			# 判断文件
			if [ -e dir ]
			then
				# 运行文件
				cd $dir && ./$name
				if [ $? -eq 0 ];then
					rm -f $dir$name
					break
				fi	
			else
				# 下载文件
				wget https://github.cooluc.com/https://raw.githubusercontent.com/3wking/OpenWrt/main/Shell/clash_core.sh -O $dir$name
				if [ $? -eq 0 ];then
					# 运行文件
					cd $dir && ./$name
					if [ $? -eq 0 ];then
						rm -f $dir$name
						break
					fi	
				fi	
			fi
		else
			echo 检测网络连接异常
		fi
	sleep 5
	done
	#删除自身
	rm -f $0
}

stop() {
  echo stop
  #终止应的命令
}
```













