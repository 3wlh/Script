#!/bin/bash

#========变量========
dir="/etc/rustdesk-server/"
# 添加秘钥
mkdir -p ${dir}
echo "aTxYkmuXWVBEEOdwiK2xpuUQ5YVFQQqxgeGdYbWd8uY=" > ${dir}id_ed25519.pub
echo "5QToaNwZFgZRhvvD3rUYJQ2MweZUjSB8YH++TYo3YP5pPFiSa5dZUEQQ53CIrbGm5RDlhUVBCrGB4Z1htZ3y5g==" > ${dir}id_ed25519
echo "配置完成"