#!/bin/bash
# 服务器安装脚本管理器 v1.0
# 仓库地址: https://gitee.com/li-songyun666/Server_installer

BASE_URL="https://gitee.com/li-songyun666/Server_installer/raw/master/scripts"

# 清理屏幕
clear

# 显示标题
echo "======================================"
echo "   游戏服务器安装脚本管理器"
echo "   仓库: $BASE_URL"
echo "======================================"
echo "请选择要安装的服务器类型："
echo "1. Fabric (Minecraft)"
echo "2. Forge (Minecraft)"
echo "3. 泰拉瑞亚"
echo "4. Spigot (Minecraft)"
echo "5. Paper (Minecraft)"
echo "6. Folia (Minecraft)"
echo "7. 退出"
echo "======================================"

# 获取用户输入
read -p "请输入选项 (1-6): " choice

# 根据选择设置脚本名称
case $choice in
    1) script="fabric.sh" ;;
    2) script="forge.sh" ;;
    3) script="terraria.sh" ;;
    4) script="spigot.sh" ;;
    5) script="paper.sh" ;;
    6) script="folia.sh" ;;
    7) 
        echo "已退出"
        exit 0 
        ;;
    *) 
        echo "无效选择"
        exit 1 
        ;;
esac

# 下载安装脚本
echo "正在下载安装脚本: $script"
echo "下载地址: $BASE_URL/$script"

# 尝试下载脚本
if ! curl -sSLf -o "$script" "$BASE_URL/$script"; then
    echo "错误：无法下载安装脚本"
    echo "可能原因:"
    echo "1. 网络连接问题"
    echo "2. 脚本地址变更"
    echo "3. 仓库不可访问"
    echo ""
    echo "请检查网络连接或访问仓库: $BASE_URL"
    exit 1
fi

# 设置可执行权限
chmod +x "$script"

# 准备执行
echo "======================================"
echo "已成功下载 ${script}"
echo "即将开始安装..."
echo "======================================"
sleep 2

# 执行安装脚本
echo "启动安装过程..."
echo "--------------------------------------"
./"$script"
