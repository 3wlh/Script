#!/bin/bash

# 检查脚本是否以root权限运行
if [ "$EUID" -ne 0 ]
  then echo "请使用sudo运行这个脚本。"
  exit
fi

echo "请输入新的root密码："
read -s new_password
echo ""
echo "请再次输入新的root密码以确认："
read -s confirm_password

# 检查两次输入的密码是否一致
if [ "$new_password" != "$confirm_password" ]; then
    echo "两次输入的密码不一致，请重新运行脚本。"
    exit 1
fi

# 修改root密码
echo -e "$new_password\n$new_password" | sudo passwd root

if [ $? -eq 0 ]; then
    echo "Root密码已成功更改。"
else
    echo "更改Root密码失败，请检查权限或手动更改。"
    exit 1
fi

# 修改配置文件
echo "正在修改SSH配置以启用root登录和密码认证..."

# 启用root登录
sudo sed -i -e 's/^#*PermitRootLogin.*/PermitRootLogin yes/' -e 's/^PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config

# 启用密码认证
sudo sed -i -e 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' -e 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# 检查配置是否已更改
if sudo grep -q "PermitRootLogin yes" /etc/ssh/sshd_config && sudo grep -q "PasswordAuthentication yes" /etc/ssh/sshd_config; then
    echo "SSH配置文件已成功修改。"
else
    echo "修改SSH配置文件失败，请手动检查配置文件。"
    exit 1
fi

# 重启SSH服务以应用更改
sudo systemctl restart sshd

if [ $? -eq 0 ]; then
    echo "SSH服务已重启，root登录和密码认证已启用。"
else
    echo "SSH服务重启失败，请手动重启或检查系统日志。"
    exit 1
fi