#!/bin/bash
synoinfo="/etc.defaults/synoinfo.conf"

function Network() (
#取网口名称
eth=$(ip link | grep ^[0-9] | grep eth[0-9] | awk -F: '{print $2}')
echo -e "获取网口：" $eth
#取网口数量
int=$(echo $eth | grep -o eth | wc -l)
#修改网口数量
sed -i 's/maxlanport="[0-9]"/maxlanport="'$int'"/g' $synoinfo
#计次修改
for ((i=1;i<"$int+1";i++)) ; do
	net=$(echo $eth | awk -F ' ' '{print $'$i' }')
	if [ "${net}" == "eth0" ]; then
		echo "添加网口：$net."
		synodsmnotify -t dsm @administrators "Network" "添加网口：$net." >/dev/null
		if ! grep -q "${net}_mtu" $synoinfo; then
			sed -i '/sataportcfg/a\'$net'_mtu="1500"' $synoinfo
		fi
		if ! grep -q "${net}_wol" $synoinfo; then
			sed -i '/'$net'_mtu/a\'$net'_wol_options="d"' $synoinfo
		
		fi
	else
		tmp_eth=$(echo $eth | awk -F ' ' '{print $'$(($i-1))' }')
		echo "添加网口：$net."
		synodsmnotify -t dsm @administrators "Network" "添加网口：$net." >/dev/null
		if ! grep -q "${net}_mtu" $synoinfo; then
			sed -i '/'$tmp_eth'_wol/a\'$net'_mtu="1500"' $synoinfo
		fi
		if ! grep -q "${net}_wol" $synoinfo; then
			sed -i '/'$net'_mtu/a\'$net'_wol_options="d"' $synoinfo
		fi
	fi
	sleep 1	
done
)
Network