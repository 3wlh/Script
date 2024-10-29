#/bin/bash
File_dir="/usr/share/IP"
File_name="${File_dir}/update.sh"
Cron_file="/etc/crontabs/root"
Cron_text=$(cat "/etc/crontabs/root" 2>/dev/null)
test  -d ${File_dir} || mkdir -p ${File_dir}
cat>$File_name<<EOF
#/bin/bash
# IP=\$(wget -qO - http://members.3322.org/dyndns/getip)
# Webpage=\$(wget -qO - http://ip.3wlh.cn)
TMP_dir="/tmp/IP"
IP_name="\${TMP_dir}/IP.txt"
Wan_ip=\$(ubus call network.interface.wan status | grep \"address\" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
test  -d \${TMP_dir} || mkdir -p \${TMP_dir}
if [ ! -n "\$(cat \${IP_name} 2>/dev/null | grep "\${Wan_ip}")" ]; then
	result=\$(wget -qO - "http://ip.3wlh.cn/update.php?IP=\${Wan_ip}")
	if [ -n "\$(echo \${result} | grep "数据保存完成")" ]; then
		echo "\${Wan_ip}" > \${IP_name}
		echo "更新IP完成"
	fi
fi
echo \${Wan_ip}
EOF
if [ ! -n "$(echo ${Cron_text} | grep "${File_name}")" ]; then
	echo "*/10 * * * * bash ${File_name}" >> ${Cron_file} && chmod +x ${File_name}
fi
service cron restart
echo "配置完成"