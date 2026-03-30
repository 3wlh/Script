# DDNS-GO
* 配置文件列表

## 运行配置
#### 加密配置文件:
* 加密配置方式1:
```
openssl enc -aes-256-cbc -in /etc/ddns-go/config.yaml -out /etc/ddns-go/config.key -base64 \
-K $(ip -o link show eth0 | awk '{print $NF}' | tr -d '\n' | md5sum | awk '{print $1}' | cut -c9-24) \
-iv $(ip -o link show eth0 | awk '{print $NF}' | tr -d '\n' | md5sum | awk '{print $1}' | cut -c9-24)
```
* 加密配置方式2:
```
openssl aes-128-cbc -in /etc/ddns-go/config.yaml -out /etc/ddns-go/config.key -base64 \
-k $(ip -o link show eth0 | awk '{print $NF}' | tr -d '\n' | md5sum | awk '{print $1}' | cut -c9-24)
```
#### 解密配置文件:
* 加密配置方式1:
```
openssl enc -aes-256-cbc -d -in /etc/ddns-go/config.key -base64 -out /etc/ddns-go/config1.yaml \
-K $(ip -o link show eth0 | awk '{print $NF}' | tr -d '\n' | md5sum | awk '{print $1}' | cut -c9-24) \
-iv $(ip -o link show eth0 | awk '{print $NF}' | tr -d '\n' | md5sum | awk '{print $1}' | cut -c9-24)
```
* 加密配置方式2:
```
openssl aes-128-cbc -d -in /etc/ddns-go/config.key -base64 -out /etc/ddns-go/config.yaml \
-k $(ip -o link show eth0 | awk '{print $NF}' | tr -d '\n' | md5sum | awk '{print $1}' | cut -c9-24)
```