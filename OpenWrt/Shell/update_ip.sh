#/bin/bash
File_dir="/usr/share/IP"
File_name="${File_dir}/update.sh"
Cron_file="/etc/crontabs/root"
Cron_text=$(cat "/etc/crontabs/root" 2>/dev/null)
test  -d ${File_dir} || mkdir -p ${File_dir}
cat>$File_name<<EOF
#/bin/bash
IP=\$(wget -qO - http://members.3322.org/dyndns/getip)
Webpage=\$(wget -qO - http://ip.3wlh.cn)
if [ ! -n "\$(echo \${Webpage} | grep "\${IP}")" ]; then
	echo "then"
	wget -qO - "http://ip.3wlh.cn/update.php?IP=\${IP}"
fi
echo \${IP}
EOF
if [ ! -n "$(echo ${Cron_text} | grep "${File_name}")" ]; then
	echo "*/10 * * * * bash ${File_name}" >> ${Cron_file} && chmod +x ${File_name}
fi
service cron restart
echo "配置完成"