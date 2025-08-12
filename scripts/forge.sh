#!/bin/bash

# 检测运行环境
if [ -d "/data/data/com.termux/files/usr" ]; then
    IS_TERMUX=true
    PKG_MANAGER="pkg"
    JAVA_HOME="/data/data/com.termux/files/usr"
else
    IS_TERMUX=false
    if command -v apt-get &> /dev/null; then
        PKG_MANAGER="apt"
    elif command -v yum &> /dev/null; then
        PKG_MANAGER="yum"
    elif command -v apk &> /dev/null; then
        PKG_MANAGER="apk"
    else
        echo "不支持的包管理器！"
        exit 1
    fi
fi

# 安装依赖函数
install_dependencies() {
    echo "安装必要依赖..."
    
    if $IS_TERMUX; then
        $PKG_MANAGER update -y && $PKG_MANAGER upgrade -y
        $PKG_MANAGER install wget openjdk-17 openjdk-11 openjdk-8 -y
    else
        case $PKG_MANAGER in
            "apt")
                sudo $PKG_MANAGER update && sudo $PKG_MANAGER upgrade -y
                sudo $PKG_MANAGER install wget openjdk-17-jdk openjdk-11-jdk openjdk-8-jdk -y
                ;;
            "yum")
                sudo $PKG_MANAGER update -y
                sudo $PKG_MANAGER install wget java-17-openjdk java-11-openjdk java-1.8.0-openjdk -y
                ;;
            "apk")
                sudo $PKG_MANAGER update
                sudo $PKG_MANAGER add wget openjdk17-jdk openjdk11-jdk openjdk8-jdk
                ;;
        esac
    fi
    
    # 检测架构并安装兼容库
    ARCH=$(uname -m)
    if $IS_TERMUX; then
        case $ARCH in
            "aarch64"|"armv7l"|"armv8l")
                $PKG_MANAGER install libandroid-spawn -y
                ;;
        esac
    else
        case $ARCH in
            "armv7l"|"armv8l")
                sudo $PKG_MANAGER install libc6:armhf -y
                ;;
            "aarch64")
                sudo $PKG_MANAGER install libc6:arm64 -y
                ;;
        esac
    fi
}

clear
echo "多系统兼容版 Minecraft Forge 服务器安装脚本"
echo "支持系统: Termux, Ubuntu, Debian, CentOS, Alpine"
echo "支持架构: x86_64, arm64, armv7"
echo "10秒后开始..."
sleep 10

# 安装依赖
install_dependencies

# 创建工作目录
WORK_DIR="$HOME/minecraft_servers"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

echo "欢迎使用跨平台Forge服务器一键安装脚本！"
echo "请选择服务器版本："
echo "1. 1.7.10"
echo "2. 1.8.9"
echo "3. 1.9.4"
echo "4. 1.10.2"
echo "5. 1.11.2"
echo "6. 1.12.2"
echo "7. 1.14.4"
echo "8. 1.15.2"
echo "9. 1.16.5"
echo "10. 1.17.1"
echo "11. 1.18.2"
echo "12. 1.19"
echo "13. 1.19.2"
echo "14. 1.19.4"
echo "15. 1.20.1"
echo "16. 1.20.2"
echo "17. 1.20.3"
echo "18. 1.20.4"
echo "19. 1.20.6"
echo "20. 1.21"
echo "21. 1.21.1"
echo "22. 1.21.3"
echo "23. 1.21.4"
echo "24. 1.21.5"
read version

case $version in
    1) selected_version="1.7.10";;
    2) selected_version="1.8.9";;
    3) selected_version="1.9.4";;
    4) selected_version="1.10.2";;
    5) selected_version="1.11.2";;
    6) selected_version="1.12.2";;
    7) selected_version="1.14.4";;
    8) selected_version="1.15.2";;
    9) selected_version="1.16.5";;
    10) selected_version="1.17.1";;
    11) selected_version="1.18.2";;
    12) selected_version="1.19";;
    13) selected_version="1.19.2";;
    14) selected_version="1.19.4";;
    15) selected_version="1.20.1";;
    16) selected_version="1.20.2";;
    17) selected_version="1.20.3";;
    18) selected_version="1.20.4";;
    19) selected_version="1.20.6";;
    20) selected_version="1.21";;
    21) selected_version="1.21.1";;
    22) selected_version="1.21.3";;
    23) selected_version="1.21.4";;
    24) selected_version="1.21.5";;
    *) echo "无效的选择"; exit 1;;
esac

echo "您选择的服务器版本是：$selected_version"
sleep 3

# 创建唯一目录
folder_name="${selected_version}forge"
counter=1
while [ -d "$folder_name" ]; do
    folder_name="${selected_version}forge$counter"
    ((counter++))
done

mkdir "$folder_name"
cd "$folder_name"

echo "正在下载Forge安装器..."
case $version in
    1) wget https://maven.minecraftforge.net/net/minecraftforge/forge/1.7.10-10.13.4.1614-1.7.10/forge-1.7.10-10.13.4.1614-1.7.10-installer.jar;;
    2) wget https://maven.minecraftforge.net/net/minecraftforge/forge/1.8.9-11.15.1.2318-1.8.9/forge-1.8.9-11.15.1.2318-1.8.9-installer.jar;;
    3) wget https://maven.minecraftforge.net/net/minecraftforge/forge/1.9.4-12.17.0.2317-1.9.4/forge-1.9.4-12.17.0.2317-1.9.4-installer.jar;;
    4) wget https://maven.minecraftforge.net/net/minecraftforge/forge/1.10.2-12.18.3.2511/forge-1.10.2-12.18.3.2511-installer.jar;;
    5) wget https://maven.minecraftforge.net/net/minecraftforge/forge/1.11.2-13.20.1.2588/forge-1.11.2-13.20.1.2588-installer.jar;;
    6) wget https://maven.minecraftforge.net/net/minecraftforge/forge/1.12.2-14.23.5.2860/forge-1.12.2-14.23.5.2860-installer.jar;;
    7) wget https://maven.minecraftforge.net/net/minecraftforge/forge/1.14.4-28.2.26/forge-1.14.4-28.2.26-installer.jar;;
    8) wget https://maven.minecraftforge.net/net/minecraftforge/forge/1.15.2-31.2.57/forge-1.15.2-31.2.57-installer.jar;;
    9) wget https://maven.minecraftforge.net/net/minecraftforge/forge/1.16.5-36.2.41/forge-1.16.5-36.2.41-installer.jar;;
    10) wget https://maven.minecraftforge.net/net/minecraftforge/forge/1.17.1-37.1.1/forge-1.17.1-37.1.1-installer.jar;;
    11) wget https://maven.minecraftforge.net/net/minecraftforge/forge/1.18.2-40.2.14/forge-1.18.2-40.2.14-installer.jar;;
    12) wget https://maven.minecraftforge.net/net/minecraftforge/forge/1.19-41.1.0/forge-1.19-41.1.0-installer.jar;;
    13) wget https://maven.minecraftforge.net/net/minecraftforge/forge/1.19.2-43.3.8/forge-1.19.2-43.3.8-installer.jar;;
    14) wget https://maven.minecraftforge.net/net/minecraftforge/forge/1.19.4-45.2.6/forge-1.19.4-45.2.6-installer.jar;;
    15) wget https://maven.minecraftforge.net/net/minecraftforge/forge/1.20.1-47.2.18/forge-1.20.1-47.2.18-installer.jar;;
    16) wget https://maven.minecraftforge.net/net/minecraftforge/forge/1.20.2-48.1.0/forge-1.20.2-48.1.0-installer.jar;;
    17) wget https://maven.minecraftforge.net/net/minecraftforge/forge/1.20.3-49.0.2/forge-1.20.3-49.0.2-installer.jar;;
    18) wget https://maven.minecraftforge.net/net/minecraftforge/forge/1.20.4-49.0.26/forge-1.20.4-49.0.26-installer.jar;;
    19) wget https://maven.minecraftforge.net/net/minecraftforge/forge/1.20.6-50.1.6/forge-1.20.6-50.1.6-installer.jar;;
    20) wget https://maven.minecraftforge.net/net/minecraftforge/forge/1.21-51.0.8/forge-1.21-51.0.8-installer.jar;;
    21) wget https://maven.minecraftforge.net/net/minecraftforge/forge/1.21.1-52.0.24/forge-1.21.1-52.0.24-installer.jar;;
    22) wget https://maven.minecraftforge.net/net/minecraftforge/forge/1.21.3-53.0.7/forge-1.21.3-53.0.7-installer.jar;;
    23) wget https://maven.minecraftforge.net/net/minecraftforge/forge/1.21.4-54.1.3/forge-1.21.4-54.1.3-installer.jar;;
    24) wget https://maven.minecraftforge.net/net/minecraftforge/forge/1.21.5-55.0.23/forge-1.21.5-55.0.23-installer.jar;;
esac

echo "安装Forge服务器..."
sleep 3

# 自动选择最佳Java版本
if command -v java-17 &> /dev/null; then
    JAVA_CMD="java-17"
elif command -v java17 &> /dev/null; then
    JAVA_CMD="java17"
elif command -v java &> /dev/null; then
    JAVA_CMD="java"
else
    echo "未找到Java环境！"
    exit 1
fi

# 安装服务器
$JAVA_CMD -jar *installer.jar --installServer

# 配置服务器
echo "eula=true" > eula.txt

cat << EOF > server.properties
# Minecraft跨平台服务器配置
max-tick-time=60000
force-gamemode=false
allow-nether=true
gamemode=0
broadcast-console-to-ops=true
enable-query=false
player-idle-timeout=0
difficulty=1
spawn-monsters=true
op-permission-level=4
pvp=true
snooper-enabled=false
level-type=DEFAULT
hardcore=false
enable-command-block=true
max-players=20
network-compression-threshold=256
max-world-size=29999984
server-port=25565
spawn-npcs=true
allow-flight=false
level-name=world
view-distance=8
spawn-animals=true
white-list=false
generate-structures=true
online-mode=true
max-build-height=256
prevent-proxy-connections=false
enable-rcon=false
motd=跨平台Forge服务器
EOF

# 创建启动脚本
cat << EOF > start.sh
#!/bin/bash

# 自动检测最佳Java版本
if [ -f /usr/lib/jvm/java-17/bin/java ]; then
    JAVA_CMD="/usr/lib/jvm/java-17/bin/java"
elif [ -f /usr/bin/java-17 ]; then
    JAVA_CMD="java-17"
elif [ -f /data/data/com.termux/files/usr/bin/java ]; then
    JAVA_CMD="/data/data/com.termux/files/usr/bin/java"
else
    JAVA_CMD="java"
fi

# 根据架构设置内存
ARCH=\$(uname -m)
if [[ "\$ARCH" == *"arm"* || "\$ARCH" == *"aarch"* ]]; then
    MEM_OPTIONS="-Xmx1024M -Xms512M"
else
    MEM_OPTIONS="-Xmx2048M -Xms1024M"
fi

# 启动服务器
\$JAVA_CMD \$MEM_OPTIONS -jar \$(ls | grep -E 'forge-.*.jar$') nogui
EOF

chmod +x start.sh

echo "================================================="
echo "Forge服务器安装完成！"
echo "目录位置: $WORK_DIR/$folder_name"
echo "启动命令: ./start.sh"
echo "服务器端口: 25565"
echo ""
echo "注意事项:"
echo "1. ARM设备可能需要手动选择Java版本"
echo "2. 低内存设备建议编辑start.sh调整内存设置"
echo "3. 首次启动可能需要几分钟时间生成世界"
echo "================================================="
