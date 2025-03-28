#/bin/bash
if [ -z "$(echo ${2} | grep ".*wan")" ];then
	exit
fi
echo "开始推送消息"
sleep 30s
message="更新IP：$(ubus call network.interface.wan status | grep \"address\" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')"
data=`curl --location --request POST "http://frp.3wlh.cn:3000/send_private_msg" \
--header "Content-Type: application/json" \
--data-raw "{\"user_id\":\"1094890624\",\"message\":[{\"type\":\"text\",\"data\":{\"text\":\"${message}\"}}]}"`
echo ${data}
