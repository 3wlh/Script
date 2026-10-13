# macOS
## 配置
##### 屏蔽系统更新
```sh
curl -sSL http://3wlh.github.io/Script/MacOS/update/update-blocker.sh | sudo bash
```
##### 屏蔽隐藏文件
```sh
curl -sSL http://3wlh.github.io/Script/MacOS/cleanup/hidden-cleaner.sh | sudo bash
```
##### Win键盘适配
```sh
curl -sSL http://3wlh.github.io/Script/MacOS/keyboard/win-keyboard.sh | sudo bash
```
##### 全局保活（禁用App Nap）
```sh
curl -sSL http://3wlh.github.io/Script/MacOS/keepalive/keep-alive.sh | sudo bash
```
##### MuMu模拟器保活
```sh
curl -sSL http://3wlh.github.io/Script/MacOS/mumu/keep-alive.sh | sudo bash
```
##### 挂载盘隐藏
```sh
curl -sSL http://3wlh.github.io/Script/MacOS/disk/hide-disk-v1.sh | sudo bash
```
```sh
curl -sSL http://3wlh.github.io/Script/MacOS/disk/hide-disk-v2.sh | sudo bash
```
```sh
curl -sSL http://3wlh.github.io/Script/MacOS/disk/hide-disk-v3.sh | sudo bash
```
## PKG软件包卸载
#### 卸载命令
```sh
curl -sSL http://3wlh.github.io/Script/MacOS/pkg/卸载pkg软件包.sh | sudo bash
```

## 双击运行（.command）
各脚本在同目录提供 `.command` 版本（内容与 `.sh` 一致 + 自动提权），拷到 Mac 后首次运行前赋一次执行权限：
```sh
chmod +x */*.command
```
之后在访达双击即可运行：脚本自动以 sudo 重新执行自身，密码在弹出的终端窗口输入，无需手动 sudo。
（若双击提示「无法打开，因为来自身份不明的开发者」，到 终端 执行：`xattr -dr com.apple.quarantine 对应目录`）