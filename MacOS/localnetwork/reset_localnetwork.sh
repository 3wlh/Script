#!/bin/bash
# reset_localnetwork.sh - 重置 macOS 本地网络权限
# 建议在恢复模式（Recovery Mode）的终端里运行

# ---------- 自动探测 Data 卷路径 ----------
DATA_VOLUME=""

for candidate in \
    "/Volumes/Macintosh HD - Data" \
    "/Volumes/Data" \
    "/Volumes/Macintosh HD" \
    "/System/Volumes/Data"; do
    if [ -d "$candidate/Library/Preferences" ]; then
        DATA_VOLUME="$candidate"
        break
    fi
done

if [ -z "$DATA_VOLUME" ]; then
    echo "❌ 未找到数据卷！当前 /Volumes/ 内容："
    ls /Volumes/
    echo ""
    echo "请先在磁盘工具中装载 Macintosh HD - Data，然后重试。"
    exit 1
fi

echo "✅ 数据卷位置: $DATA_VOLUME"
echo ""

# ---------- 删除权限文件 ----------
PLIST_DIR="$DATA_VOLUME/Library/Preferences"
TARGETS=(
    "com.apple.networkextension.plist"
    "com.apple.networkextension.uuidcache.plist"
    "com.apple.networkextension.cache.plist"
)

DELETED=0
for plist in "${TARGETS[@]}"; do
    FILE="$PLIST_DIR/$plist"
    if [ -f "$FILE" ]; then
        echo "🗑  正在删除: $FILE"
        if rm -f "$FILE" 2>/dev/null; then
            echo "    ✔ 删除成功"
            DELETED=$((DELETED+1))
        else
            echo "    ✘ 删除失败 (Operation not permitted)"
            echo "      → 说明 SIP 仍开启或当前环境无权限"
        fi
    else
        echo "ℹ  不存在，跳过: $plist"
    fi
done

echo ""

# ---------- 验证结果 ----------
if [ -f "$PLIST_DIR/com.apple.networkextension.plist" ]; then
    echo "❌ 主文件仍存在，重置未完成。"
    echo "   请确认："
    echo "   1. 在恢复模式终端运行本脚本"
    echo "   2. 或先执行 csrutil disable 关闭 SIP"
    exit 2
else
    if [ "$DELETED" -gt 0 ]; then
        echo "🎉 重置完成！共删除 $DELETED 个文件。"
        echo "   现在请重启进入正常系统，"
        echo "   在 系统设置 → 隐私与安全性 → 本地网络 查看结果。"
    else
        echo "✅ 本地网络权限列表已是干净状态，无需操作。"
    fi
fi
