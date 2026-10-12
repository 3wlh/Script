#!/bin/bash
clear
RED='\033[0;31m'
GRN='\033[0;32m'
GREY='\033[0;37m'
NC='\033[0m'

# 固定的基础路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="/Applications"

# ====== 创建快捷方式函数 ======
# 参数1: 源名称 (如 AppCleaner.app)
# 参数2: 链接名称 (如 AppCleaner，若不传则默认同参数1)
create_symlink() {
    local src_name="$1"
    # 核心逻辑：如果 $2 为空，则默认取 $1 的值
    local link_name="${2:-$1}"
    
    # 拼接完整路径
    local src_path="$SCRIPT_DIR/$src_name"
    local dest_path="$APP_DIR/$link_name"

    # 检查源是否存在
    if [ ! -e "$src_path" ]; then
        echo -e "${RED}错误：源文件不存在 $src_path${NC}"
        return 1
    fi

    # 检查链接是否已存在 (使用 -L 明确判断是否为软链接)
    if [ -e "$dest_path" ] || [ -L "$dest_path" ]; then
        echo -e "${GREY}快捷方式已存在，跳过：$dest_path${NC}"
        return 0
    fi

    # 创建软链接
    ln -s "$src_path" "$dest_path"
    if [ $? -eq 0 ]; then
        echo -e "${GRN}成功：$src_path -> $dest_path${NC}"
        return 0
    else
        echo -e "${RED}失败：权限不足，请尝试 sudo 运行${NC}"
        return 1
    fi
}

# ====== 主流程 ======
echo ""
echo -e "创建快捷方式"
echo ""

# 用法1：指定不同的源名和链接名
create_symlink "AppCleaner.app"
create_symlink "MuMuPlayer Pro.app"
create_symlink "AI Work 助手.app"
create_symlink "Trae CN.app"
create_symlink "IINA.app"

echo -e "\n"
read -n 1 -s -p "按任意键退出..."
osascript -e 'tell application "Terminal" to close front window' & exit
