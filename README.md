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
```
echo 123456789 | openssl aes-128-cbc -k <key> -base64 2>/dev/null
echo U2FsdGVkX19eot/2yA78EZZ0+lBa7O5ShnVMg9Iiock= | openssl aes-128-cbc -d -k <key> -base64 2>/dev/null
```