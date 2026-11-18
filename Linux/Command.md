# Linux命令

## 应用
#### 应用商城
```
sudo apt install gnome-software
```
## Ubuntu Dock 显示可移动磁盘
#### 不显示挂载的 SD 卡、U 盘
```
gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts false
```
#### 恢复默认显示
```
gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts true
```

## 截图
#### 安装软件
```
sudo apt install gnome-screenshot wl-clipboard
```
#### 编辑快捷键命令
```
bash -c 'f=$(mktemp --suffix=.png -p /tmp ss-XXXXXX); gnome-screenshot -af "$f" && wl-copy < "$f" && rm -f "$f"'
```
