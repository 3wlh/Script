#!/bin/sh
# 重命名目录
mv "www.photopea.com" "photopea"
JS_File=$(find $(pwd)/photopea/code/pp/ -name *.js)
# 隐藏元素
sed -i "s/color:#ffffff; background-color:#/display:none; background-color:#/g" ${JS_File}
sed -i "s/float:right.*index:1.*app-region:no-drag;/opacity:0; pointer-events:none;/g" ${JS_File}
sed -i "s/padding: 8px.*13:36.*px; cursor:pointer;/display:none;/g" ${JS_File}
# 直接跳转
sed -i "s/function addPP()/window.onload = function()/g" $(pwd)/www.photopea.com/index.html
(cd photopea && {
JS_DBS=$(find $(pwd)/code/dbs/ -name *.js)
sed -i '/var FNTS = {/,/};/d' ${JS_DBS} && \
cat $(pwd)/rsrc/fonts/function.js >> ${JS_DBS} && \
rm -f $(pwd)/rsrc/fonts/function.js && \
mv -f $(pwd)/rsrc/fonts/22.js $(pwd)/code/lang/
})
