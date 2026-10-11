# MacOS命令

## 系统命令
#### 查看后台任务管理（BTM）数据库
```
sudo sfltool dumpbtm
```
#### 开启允许安装运行任何来源的App
```
sudo spctl --master-disable
```
#### 关闭允许安装运行任何来源的App
```
sudo spctl --master-enable
```

## 应用程序
#### 程序清除隔离属性
```
xattr -dr com.apple.quarantine /<path>/<*>.app
```
#### 程序重新[ad-hoc]签名
```
codesign --force --deep --sign - /<path>/<*>.app
```
#### 锁定app文件
```
chflags uchg /<path>/<*>.app
```
#### 解除锁定app文件
```
chflags nouchg /<path>/<*>.app
```

## 图标缓存
#### 重置启动台数据库
```
rm ~/Library/Application\ Support/Dock/*.db
defaults write com.apple.dock ResetLaunchPad -bool true
killall Dock
killall Finder
```
#### 重建 LaunchServices 注册信息
```
sudo /System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -kill -r -domain local -domain system -domain user
killall Finder
```