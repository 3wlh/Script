#!/bin/sh
# 修改目录
mv "www.photopea.com" "photopea"
JS_File=$(find $(pwd)/photopea/code/pp/ -name *.js)
# 隐藏元素
sed -i "s/color:#ffffff; background-color:#/display:none; background-color:#/g" ${JS_File}
sed -i "s/float:right.*index:1.*app-region:no-drag;/opacity:0; pointer-events:none;/g" ${JS_File}
sed -i "s/padding: 8px.*13:36.*px; cursor:pointer;/display:none;/g" ${JS_File}
(cd photopea && {
# 修改html
sed -i "s|img/table.webp||g" $(pwd)/index.html
sed -i "s|img/hand_phone.webp||g" $(pwd)/index.html
sed -i "s|img/goats.mp4||g" $(pwd)/index.html
sed -i "s|img/laptop.webp||g" $(pwd)/index.html
sed -i "s|addPP()||g" $(pwd)/index.html
sed -i "s/function addPP()/window.onload = function()/g" $(pwd)/index.html
# 添加修改JS	
JS_DBS=$(find $(pwd)/code/dbs/ -name *.js)
sed -i '/var FNTS = {/,/};/d' ${JS_DBS} && \
wget -qO - http://script.11121314.xyz/Docker/photopea/function.js >> ${JS_DBS}
wget -qO - http://script.11121314.xyz/Docker/photopea/zh_cn.js > $(pwd)/code/lang/22.js
wget -qO - http://script.11121314.xyz/Docker/photopea/fnts-module.js > $(pwd)/rsrc/fonts/fnts-module.js
})
