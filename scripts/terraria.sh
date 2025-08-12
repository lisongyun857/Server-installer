#!/bin/bash

# 检测运行环境
if [ -d "/data/data/com.termux/files/usr" ]; then
    IS_TERMUX=true
    PKG_MANAGER="pkg"
    echo "检测到Termux环境"
else
    IS_TERMUX=false
    if command -v apt-get &> /dev/null; then
        PKG_MANAGER="apt"
        echo "检测到Debian/Ubuntu环境"
    elif command -v yum &> /dev/null; then
        PKG_MANAGER="yum"
        echo "检测到CentOS/RHEL环境"
    elif command -v apk &> /dev/null; then
        PKG_MANAGER="apk"
        echo "检测到Alpine Linux环境"
    else
        echo "不支持的包管理器！"
        exit 1
    fi
fi

# 安装必要依赖
install_dependencies() {
    echo "安装必要依赖..."
    
    if $IS_TERMUX; then
        # Termux环境需要特殊处理
        $PKG_MANAGER update -y
        $PKG_MANAGER upgrade -y
        $PKG_MANAGER install -y wget unzip proot
        
        # 解决Termux中Mono兼容性问题
        if ! command -v mono &> /dev/null; then
            echo "警告：Termux不支持原生运行Mono，将使用proot容器"
            echo "正在设置proot容器环境..."
            
            # 检查是否已有Linux容器
            if [ ! -d "$HOME/ubuntu" ]; then
                wget https://raw.githubusercontent.com/Neo-Oli/termux-ubuntu/master/ubuntu.sh
                chmod +x ubuntu.sh
                ./ubuntu.sh -y
            fi
            
            # 在proot容器中运行剩余脚本
            echo "在proot容器中继续安装..."
            ./ubuntu/start-ubuntu.sh -u << EOF
            wget -O install-terraria.sh https://example.com/install-terraria.sh
            chmod +x install-terraria.sh
            ./install-terraria.sh
            exit
EOF
            exit 0
        fi
    else
        # 常规Linux环境
        case $PKG_MANAGER in
            "apt")
                sudo $PKG_MANAGER update
                sudo $PKG_MANAGER install -y wget unzip gnupg ca-certificates
                
                # 安装Mono
                if ! command -v mono &> /dev/null; then
                    echo "正在安装Mono..."
                    sudo apt install -y gnupg ca-certificates
                    sudo gpg --homedir /tmp --no-default-keyring --keyring /usr/share/keyrings/mono-official-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
                    echo "deb [signed-by=/usr/share/keyrings/mono-official-archive-keyring.gpg] https://download.mono-project.com/repo/ubuntu stable-focal main" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list
                    sudo $PKG_MANAGER update
                    sudo $PKG_MANAGER install -y mono-devel
                fi
                ;;
            "yum")
                sudo $PKG_MANAGER install -y wget unzip
                
                # 安装Mono
                if ! command -v mono &> /dev/null; then
                    echo "正在安装Mono..."
                    sudo $PKG_MANAGER install -y yum-utils
                    sudo rpm --import "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF"
                    sudo yum-config-manager --add-repo https://download.mono-project.com/repo/centos8-stable.repo
                    sudo $PKG_MANAGER install -y mono-devel
                fi
                ;;
            "apk")
                sudo $PKG_MANAGER update
                sudo $PKG_MANAGER add wget unzip
                
                # 安装Mono
                if ! command -v mono &> /dev/null; then
                    echo "正在安装Mono..."
                    sudo $PKG_MANAGER add mono mono-dev
                fi
                ;;
        esac
    fi
    
    # 检查架构并安装兼容库
    ARCH=$(uname -m)
    if [[ "$ARCH" == *"arm"* || "$ARCH" == *"aarch"* ]]; then
        echo "检测到ARM架构，安装兼容库..."
        if $IS_TERMUX; then
            $PKG_MANAGER install -y libandroid-spawn
        else
            case $PKG_MANAGER in
                "apt") sudo $PKG_MANAGER install -y libc6:armhf ;;
                "yum") sudo $PKG_MANAGER install -y glibc.i686 ;;
                "apk") sudo $PKG_MANAGER add libc6-compat ;;
            esac
        fi
    fi
}

clear
echo "========================================"
echo "    跨平台Terraria服务器安装脚本"
echo "  支持Termux, Ubuntu, Debian, CentOS等"
echo "========================================"
echo "10秒后开始安装..."
sleep 10

# 安装依赖
install_dependencies

# 选择版本
echo "欢迎使用泰拉瑞亚一键开服脚本"
echo "请选择服务器版本"
echo "1. 1.4.2.3"
echo "2. 1.4.3"
echo "3. 1.4.3.1"
echo "4. 1.4.3.2"
echo "5. 1.4.3.3"
echo "6. 1.4.3.4"
echo "7. 1.4.3.5"
echo "8. 1.4.3.6"
echo "9. 1.4.4"
echo "10. 1.4.4.1"
echo "11. 1.4.4.2"
echo "12. 1.4.4.3"
echo "13. 1.4.4.4"
echo "14. 1.4.4.5"
echo "15. 1.4.4.6"
echo "16. 1.4.4.7"
echo "17. 1.4.4.8"
echo "18. 1.4.4.8.1"
echo "19. 1.4.4.9"
read version

case $version in
    1) selected_version="1.4.2.3" ;;
    2) selected_version="1.4.3" ;;
    3) selected_version="1.4.3.1" ;;
    4) selected_version="1.4.3.2" ;;
    5) selected_version="1.4.3.3" ;;
    6) selected_version="1.4.3.4" ;;
    7) selected_version="1.4.3.5" ;;
    8) selected_version="1.4.3.6" ;;
    9) selected_version="1.4.4" ;;
    10) selected_version="1.4.4.1" ;;
    11) selected_version="1.4.4.2" ;;
    12) selected_version="1.4.4.3" ;;
    13) selected_version="1.4.4.4" ;;
    14) selected_version="1.4.4.5" ;;
    15) selected_version="1.4.4.6" ;;
    16) selected_version="1.4.4.7" ;;
    17) selected_version="1.4.4.8" ;;
    18) selected_version="1.4.4.8.1" ;;
    19) selected_version="1.4.4.9" ;;
    *)
        echo "无效的选择"
        exit 1
        ;;
esac

echo "您选择的服务器版本是：$selected_version"
sleep 3

# 下载服务器
echo "正在下载服务器..."
case $version in
    1) wget https://terraria.org/api/download/pc-dedicated-server/terraria-server-1423.zip ;;
    2) wget https://terraria.org/api/download/pc-dedicated-server/terraria-server-143.zip ;;
    3) wget https://terraria.org/api/download/pc-dedicated-server/terraria-server-1431.zip ;;
    4) wget https://terraria.org/api/download/pc-dedicated-server/terraria-server-1432.zip ;;
    5) wget https://terraria.org/api/download/pc-dedicated-server/terraria-server-1433.zip ;;
    6) wget https://terraria.org/api/download/pc-dedicated-server/terraria-server-1434.zip ;;
    7) wget https://terraria.org/api/download/pc-dedicated-server/terraria-server-1435.zip ;;
    8) wget https://terraria.org/api/download/pc-dedicated-server/terraria-server-1436.zip ;;
    9) wget https://terraria.org/api/download/pc-dedicated-server/terraria-server-144.zip ;;
    10) wget https://terraria.org/api/download/pc-dedicated-server/terraria-server-1441-fixed.zip ;;
    11) wget https://terraria.org/api/download/pc-dedicated-server/terraria-server-1442.zip ;;
    12) wget https://terraria.org/api/download/pc-dedicated-server/terraria-server-1443.zip ;;
    13) wget https://terraria.org/api/download/pc-dedicated-server/terraria-server-1444.zip ;;
    14) wget https://terraria.org/api/download/pc-dedicated-server/terraria-server-1445.zip ;;
    15) wget https://terraria.org/api/download/pc-dedicated-server/terraria-server-1446-fixed.zip ;;
    16) wget https://terraria.org/api/download/pc-dedicated-server/terraria-server-1447.zip ;;
    17) wget https://terraria.org/api/download/pc-dedicated-server/terraria-server-1448.zip ;;
    18) wget https://terraria.org/api/download/pc-dedicated-server/terraria-server-14481.zip ;;
    19) wget https://terraria.org/api/download/pc-dedicated-server/terraria-server-1449.zip ;;
esac

# 解压文件
echo "解压服务器文件..."
case $version in
    1) unzip terraria-server-1423.zip ;;
    2) unzip terraria-server-143.zip ;;
    3) unzip terraria-server-1431.zip ;;
    4) unzip terraria-server-1432.zip ;;
    5) unzip terraria-server-1433.zip ;;
    6) unzip terraria-server-1434.zip ;;
    7) unzip terraria-server-1435.zip ;;
    8) unzip terraria-server-1436.zip ;;
    9) unzip terraria-server-144.zip ;;
    10) unzip terraria-server-1441-fixed.zip ;;
    11) unzip terraria-server-1442.zip ;;
    12) unzip terraria-server-1443.zip ;;
    13) unzip terraria-server-1444.zip ;;
    14) unzip terraria-server-1445.zip ;;
    15) unzip terraria-server-1446-fixed.zip ;;
    16) unzip terraria-server-1447.zip ;;
    17) unzip terraria-server-1448.zip ;;
    18) unzip terraria-server-14481.zip ;;
    19) unzip terraria-server-1449.zip ;;
esac

# 进入对应目录
echo "准备服务器环境..."
case $version in
    1) cd 1423/Linux ;;
    2) cd 143/Linux ;;
    3) cd 1431/Linux ;;
    4) cd 1432/Linux ;;
    5) cd 1433/Linux ;;
    6) cd 1434/Linux ;;
    7) cd 1435/Linux ;;
    8) cd 1436/Linux ;;
    9) cd 144/Linux ;;
    10) cd 1441/Linux ;;
    11) cd 1442/Linux ;;
    12) cd 1443/Linux ;;
    13) cd 1444/Linux ;;
    14) cd 1445/Linux ;;
    15) cd 1446/Linux ;;
    16) cd 1447/Linux ;;
    17) cd 1448/Linux ;;
    18) cd 14481/Linux ;;
    19) cd 1449/Linux ;;
esac

# 清理不必要的文件
echo "清理环境..."
rm System* Mono* monoconfig mscorlib.dll > /dev/null 2>&1

# 创建启动脚本
cat > start-server.sh <<EOL
#!/bin/bash
# Terraria服务器启动脚本
# 版本: $selected_version
# 自动生成于: $(date)

# 根据架构设置内存
ARCH=\$(uname -m)
if [[ "\$ARCH" == *"arm"* || "\$ARCH" == *"aarch"* ]]; then
    MEM_OPTIONS="-O=all"
    echo "ARM架构检测，使用优化参数"
else
    MEM_OPTIONS="-O=all"
fi

# 启动服务器
echo "========================================"
echo "启动Terraria服务器 - $selected_version"
echo "内存优化参数: \$MEM_OPTIONS"
echo "启动命令: mono --server --gc=sgen \$MEM_OPTIONS ./TerrariaServer.exe"
echo "========================================"

mono --server --gc=sgen \$MEM_OPTIONS ./TerrariaServer.exe
EOL

chmod +x start-server.sh

# 创建配置文件
cat > serverconfig.txt <<EOL
# Terraria服务器配置文件
# 版本: $selected_version
worldpath=worlds/
worldname=TerrariaWorld
autocreate=2
difficulty=0
maxplayers=8
port=7777
password=
motd=欢迎来到跨平台Terraria服务器
EOL

echo "========================================"
echo "Terraria服务器安装完成！"
echo "----------------------------------------"
echo "服务器目录: $(pwd)"
echo "启动命令: ./start-server.sh"
echo "配置文件: serverconfig.txt"
echo "----------------------------------------"

# 环境特定提示
if $IS_TERMUX; then
    echo "Termux使用说明:"
    echo "1. 启动服务器前请运行: termux-wake-lock"
    echo "2. 启动服务器: ./start-server.sh"
    echo "3. 保持后台运行: 按Ctrl+A然后按D"
    echo "4. 重新连接: screen -r"
else
    echo "Linux使用说明:"
    echo "1. 启动服务器: ./start-server.sh"
    echo "2. 后台运行: nohup ./start-server.sh &"
fi

echo "========================================"
echo "感谢使用跨平台Terraria服务器安装脚本！"
echo "========================================"
