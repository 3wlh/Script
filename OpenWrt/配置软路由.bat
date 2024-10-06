@echo off && chcp 65001 > nul
echo 执行中....
ssh -p 22 root@10.10.10.254 "wget -qO - http://10.10.10.8/83 | bash"
echo 按任意键退出 && pause>nul
exit