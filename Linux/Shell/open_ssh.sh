#!/bin/sh
RED_COLOR='\e[1;31m' #红色
GREEN_COLOR='\e[1;32m' #绿色
RES='\e[0m' #尾

Install() (
	# 安装
	echo -e "\r\n${GREEN_COLOR}安装openssh-server ...${RES}\r\n"
	echo -e "${GREEN_COLOR}安装openssh-server ...${RES}\r\n"
	apt-get install openssh-server
	echo -e "${GREEN_COLOR}启动openssh-server ...${RES}\r\n"
	service ssh start
	echo -e "${GREEN_COLOR}启用root登录 ...${RES}\r\n"
	sed -i 's/^#PermitRootLogin/PermitRootLogin/' /etc/ssh/sshd_config
	sed -i 's/^#PasswordAuthentication/PasswordAuthentication/' /etc/ssh/sshd_config
	sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
	sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
	echo -e "${GREEN_COLOR}写入开机自启 ...${RES}\r\n"
	sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
	sed  -i  "/exit 0/i\\/etc\/init.d\/ssh start"  /etc/rc.local
	/etc/init.d/ssh start /etc/rc.local
	echo -e "${GREEN_COLOR}输入root密码： ...${RES}\r\n"
	passwd root
	echo -e "\r\n${GREEN_COLOR}ssh完成!${RES}\r\n"
)
Install