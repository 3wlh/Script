#/bin/bash
File="/usr/share/IP/updateip.sh"
Cron="/etc/crontabs/root"
Cron_text=$(cat "/etc/crontabs/root" 2>/dev/null)
test  -d ${File%/*} || mkdir -p ${File%/*}
cat>$File<<EOF
#/bin/bash
log="/tmp/log/updateip.log"
time=\$(date +"%Y/%m/%d %H:%M.%S")
web=\$(http://ip.3wlh.cn)
# Webpage=\$(wget -qO - http://ip.3wlh.cn)
# ip=\$(wget -qO - http://members.3322.org/dyndns/getip)
ip=\$(ubus call network.interface.wan status | grep \"address\" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
test  -d \${log%/*} || mkdir -p \${log%/*}
if [ ! -n "\$(sed -n '\$p' \${log} 2>/dev/null | grep "\${ip}")" ]; then
	result=\$(wget -qO - "\${web}/update.php?IP=\${ip}")
	if [ -n "\$(echo \${result} | grep "数据保存完成")" ]; then
		echo "\${time} update:\${ip}" >> \${log}
		echo "更新IP完成"
	fi
fi
echo \${ip}
EOF
if [ ! -n "$(echo ${Cron_text} | grep "${File}")" ]; then
	echo "*/10 * * * * bash ${File}" >> ${Cron} && chmod +x ${File}
fi
service cron restart
echo "配置完成"