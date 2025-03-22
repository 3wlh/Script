#!/bin/bash
# 备份
function backups() (
	# 开始备份《动漫》
	echo "开始备份<动漫>."
	synodsmnotify -t dsm @administrators "备份" "开始备份<动漫>." >/dev/null
	cp -ur /volume3/动漫 /volume2/Backup
	echo "<动漫>备份完成."
	synodsmnotify -t dsm @administrators "备份" "<动漫>备份完成." >/dev/null
	sleep 5
	# 开始备份《动漫里番》
	echo "开始备份<动漫里番>."
	synodsmnotify -t dsm @administrators "备份" "开始备份<动漫里番>." >/dev/null
	cp -ur /volume3/动漫里番 /volume2/Backup
	echo "<动漫里番>备份完成"
	synodsmnotify -t dsm @administrators "备份" "<动漫里番>备份完成." >/dev/null
	sleep 5
	# 开始备份《视频》
	echo "开始备份<视频>."
	synodsmnotify -t dsm @administrators "备份" "开始备份<视频>." >/dev/null
	cp -ur /volume3/视频 /volume2/Backup
	echo "<视频>备份完成"
	synodsmnotify -t dsm @administrators "备份" "<视频>备份完成." >/dev/null
	sleep 5
	#开始备份《源码》
	echo "开始备份<源码>."
	synodsmnotify -t dsm @administrators "备份" "开始备份<源码>." >/dev/null
	cp -ur /volume1/源码 /volume2/Backup
	echo "<源码>备份完成."
	synodsmnotify -t dsm @administrators "备份" "<源码>备份完成." >/dev/null
	sleep 5
	#开始备份《硬盘》
	echo "开始备份<硬盘>."
	synodsmnotify -t dsm @administrators "备份" "开始备份<硬盘>." >/dev/null
	cp -ur /volume3/硬盘 /volume2/Backup
	echo "<硬盘>备份完成."
	synodsmnotify -t dsm @administrators "备份" "<硬盘>备份完成." >/dev/null
)

backups
if [ $? -eq 0 ]; then
	echo "全部备份完成."
	synodsmnotify -t dsm @administrators "备份" "全部备份完成." >/dev/null