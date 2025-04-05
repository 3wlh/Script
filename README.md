# Script脚本

#### 本地配置
```
wget -qO - http://10.10.10.8/80 | bash
```
```
wget -qO - http://10.10.10.8/82 | bash
```
## 加密配置
#### 下载加密脚本
```
wget -qO /usr/bin/AES.sh http://3wlh.github.io/Script/OpenWrt/Shell/AES.sh && chmod 755 /usr/bin/AES.sh && ln -s /usr/bin/AES.sh /usr/bin/AES && ln -s /usr/bin/AES.sh /usr/bin/aes
```
#### 加密和解密方式1
```
echo <加密文本> | openssl aes-128-cbc -k <key> -base64 2>/dev/null		//加密文本
echo <解密文本> | openssl aes-128-cbc -d -k <key> -base64 2>/dev/null	//解密文本
```
#### 加密和解密方式2
```
echo <加密文本> | openssl enc -e -aes-128-cbc -a -K ${key} -iv ${key} -base64 2>/dev/null	//加密文本
echo <解密文本> | openssl enc -e -aes-128-cbc -a -K ${key} -iv ${key} -base64 -d 2>/dev/null	//解密文本
```