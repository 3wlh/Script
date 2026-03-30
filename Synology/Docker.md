# 常用Docker
###### 阅读
```
docker run \
 --name reader \
  --restart always \
  -p 8080:8080 \
  -v /volume1/docker/Reader/log:/log \
  -v /volume1/docker/Reader/storage:/storage \
  -d hectorqin/reader
```
###### Alist
```sh
docker run \
  --name alist \
  --restart always \
  -p 5244:5244 \
  -v /volume1/docker/alist:/opt/alist/data \
  -e PUID=0 -e PGID=0 -e UMASK=022 \
  -d xhofe/alist:latest
```
###### Homarr
```
docker run \
  --name homarr \
  --restart unless-stopped \
  -p 7575:7575 \
  -e EDIT_MODE_PASSWORD=lh199711. \
  -v /volume1/docker/Homarr/configs:/app/data/configs \
  -v /volume1/docker/Homarr/icons:/app/public/icons \
  -v /volume1/docker/Homarr/imgs:/app/public/imgs \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -d ghcr.io/ajnart/homarr:latest
```

###### ddddocr_server
```sh
docker run \
  --name ddddocr_server \
  --restart always \
  -p 9898:9898 \
  -d xhofe/ddddocr_server:main
```