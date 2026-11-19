# Chrome
## 只关 GPU 光栅化
1. `chrome://settings/system` → 把图形加速 重新打开
2. 地址栏输入`chrome://flags/#enable-gpu-rasterization` → 改为 Disabled → 重启

## 画面合成交给 CPU
#### 写进启动器
```
sudo sed -i 's|^Exec=/usr/bin/google-chrome-stable|Exec=/usr/bin/google-chrome-stable --disable-gpu-compositing|g' /usr/share/applications/google-chrome.desktop
```
#### 删掉启动器
```
sudo sed -i 's| --disable-gpu-compositing||g' /usr/share/applications/google-chrome.desktop
```
#### 验证
```
grep '^Exec=' /usr/share/applications/google-chrome.desktop
```