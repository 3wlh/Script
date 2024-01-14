#!/bin/bash
for((i=1;i<=60;i++));do
	echo "运行次数"$i
	status_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "http://localhost:5700")
	if [[ $status_code == 200 ]]; then
		time=$(date "+%Y-%m-%d %H:%M:%S")
		echo $time
		curl -H "Content-Type:application/json" -X POST -d '{"message_type":"private","user_id":"1094890624","message":"群晖开机通知\n开机时间:\n'"$time"'"}' "http://localhost:5700/send_msg"
		text="成功"
		break
	fi
	sleep 10
	text="失败"
done
synodsmnotify -t dsm @administrators "开机通知" "发送开机通知：$text." >/dev/null