#!/bin/bash

#========变量========
Etc="/etc/synoinfo.conf"
Defaults="/etc.defaults/synoinfo.conf"
Hosts="/etc/hosts"

function Etc() {
	sed -i "s|myds_region_api_base_url=.*|myds_region_api_base_url=\"https://account.synologyexample.com/\"|g" $Etc
	sed -i "s|rss_server=.*|rss_server=\"http://update7.synologyexample.com/autoupdate/genRSS.php\"|g" $Etc
	sed -i "s|rss_server_ssl=.*|rss_server_ssl=\"https://update7.synologyexample.com/autoupdate/genRSS.php\"|g" $Etc
	sed -i "s|rss_server_v2=.*|rss_server_v2=\"https://update7.synologyexample.com/autoupdate/v2/getList\"|g" $Etc
	sed -i "s|security_version_server=.*|security_version_server=\"https://update7.synologyexample.com/securityVersion\"|g" $Etc
	sed -i "s|small_info_path=.*|small_info_path=\"https://update7.synologyexample.com/smallupdate\"|g" $Etc
	sed -i "s|update_server=.*|update_server=\"http://update7.synologyexample.com/\"|g" $Etc
	sed -i "s|update_server_ssl=.*|update_server_ssl=\"https://update7.synologyexample.com/\"|g" $Etc
	sed -i "s|updateurl=.*|updateurl=\"http://www.synologyexample.com/\"|g" $Etc
}

function Defaults() {
	sed -i "s|myds_region_api_base_url=.*|myds_region_api_base_url=\"https://account.synologyexample.com/\"|g" $Defaults
	sed -i "s|rss_server=.*|rss_server=\"http://update7.synologyexample.com/autoupdate/genRSS.php\"|g" $Defaults
	sed -i "s|rss_server_ssl=.*|rss_server_ssl=\"https://update7.synologyexample.com/autoupdate/genRSS.php\"|g" $Defaults
	sed -i "s|rss_server_v2=.*|rss_server_v2=\"https://update7.synologyexample.com/autoupdate/v2/getList\"|g" $Defaults
	sed -i "s|security_version_server=.*|security_version_server=\"https://update7.synologyexample.com/securityVersion\"|g" $Defaults
	sed -i "s|small_info_path=.*|small_info_path=\"https://update7.synologyexample.com/smallupdate\"|g" $Defaults
	sed -i "s|update_server=.*|update_server=\"http://update7.synologyexample.com/\"|g" $Defaults
	sed -i "s|update_server_ssl=.*|update_server_ssl=\"https://update7.synologyexample.com/\"|g" $Defaults
	sed -i "s|updateurl=.*|updateurl=\"http://www.synologyexample.com/\"|g" $Defaults
}

function Hosts() {
	if ! grep -q "global.download.synology.com" $Hosts; then
		sed -i '$a\127.0.0.1	global.download.synology.com' $Hosts
	fi
	if ! grep -q "global.synologydownload.com" $Hosts; then
		sed -i '$a\127.0.0.1	global.synologydownload.com' $Hosts 
	fi
	if ! grep -q "update7.synology.com" $Hosts; then
		sed -i '$a\127.0.0.1	update7.synology.com' $Hosts
	fi
	if ! grep -q "autoupdate7.synology.com" $Hosts; then
		sed -i '$a\127.0.0.1	autoupdate7.synology.com' $Hosts
	fi
	if ! grep -q "autoupdate7.synology.cn" $Hosts; then
		sed -i '$a\127.0.0.1	autoupdate7.synology.cn' $Hosts
	fi
}

(cd / && {
	[ -a $Etc ] && Etc && echo "Etc配置......OK"
    sleep 1
    [ -a $Defaults ] && Defaults && echo "Defaults配置......OK"
    sleep 1
    [ -a $Hosts ] && Hosts && echo "Hosts配置......OK"
    sleep 1
    echo  
	echo '================================='
	echo '=           配置完成            ='
	echo '================================='
})
