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
        echo "在 Termux 环境中运行"
        
        # 解决镜像问题
        if ! termux-change-repo; then
            echo "自动更换镜像失败，请手动运行: termux-change-repo"
            echo "选择中国镜像源以提高下载速度"
        fi
        
        $PKG_MANAGER update -y && $PKG_MANAGER upgrade -y
        $PKG_MANAGER install wget git -y
        
        # Termux 特定的Java安装
        if $PKG_MANAGER install openjdk-17 -y; then
            echo "成功安装 openjdk-17"
        else
            echo "安装 openjdk-17 失败，尝试安装其他Java版本"
            $PKG_MANAGER install openjdk-17-jdk -y || $PKG_MANAGER install default-jdk -y
        fi
        
        # Termux 需要额外的权限
        termux-setup-storage
    else
        echo "在 Linux 环境中运行"
        case $PKG_MANAGER in
            "apt")
                sudo $PKG_MANAGER update && sudo $PKG_MANAGER upgrade -y
                sudo $PKG_MANAGER install wget openjdk-17-jdk openjdk-11-jdk openjdk-8-jdk git -y
                ;;
            "yum")
                sudo $PKG_MANAGER update -y
                sudo $PKG_MANAGER install wget java-17-openjdk java-11-openjdk java-1.8.0-openjdk git -y
                ;;
            "apk")
                sudo $PKG_MANAGER update
                sudo $PKG_MANAGER add wget openjdk17-jdk openjdk11-jdk openjdk8-jdk git
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
echo "Termux优化版 Spigot 服务器安装脚本"
echo "支持系统: Termux, Ubuntu, Debian, CentOS, Alpine"
echo "支持架构: x86_64, arm64, armv7"
echo "10秒后开始..."
sleep 10

# 安装依赖
install_dependencies

# 创建工作目录
WORK_DIR="$HOME/spigot_servers"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

echo "欢迎使用跨平台Spigot服务器一键安装脚本！"
echo "请选择服务器版本："
echo "1. 1.12.2"
echo "2. 1.13.2"
echo "3. 1.14.4"
echo "4. 1.15.2"
echo "5. 1.16.5"
echo "6. 1.17.1"
echo "7. 1.18.1"
echo "8. 1.19.4"
echo "9. 1.20.1"
echo "10. 1.20.2"
echo "11. 1.20.3"
echo "12. 1.20.4"
echo "13. 1.20.6"
echo "14. 1.21"
echo "15. 1.21.1"
echo "16. 1.21.3"
echo "17. 1.21.4"
echo "18. 1.21.5"
read version

case $version in
    1) selected_version="1.12.2";;
    2) selected_version="1.13.2";;
    3) selected_version="1.14.4";;
    4) selected_version="1.15.2";;
    5) selected_version="1.16.5";;
    6) selected_version="1.17.1";;
    7) selected_version="1.18.1";;
    8) selected_version="1.19.4";;
    9) selected_version="1.20.1";;
    10) selected_version="1.20.2";;
    11) selected_version="1.20.3";;
    12) selected_version="1.20.4";;
    13) selected_version="1.20.6";;
    14) selected_version="1.21";;
    15) selected_version="1.21.1";;
    16) selected_version="1.21.3";;
    17) selected_version="1.21.4";;
    18) selected_version="1.21.5";;
    *) echo "无效的选择"; exit 1;;
esac

echo "您选择的服务器版本是：$selected_version"
sleep 3

# 创建唯一目录
folder_name="${selected_version}spigot"
counter=1
while [ -d "$folder_name" ]; do
    folder_name="${selected_version}spigot$counter"
    ((counter++))
done

mkdir "$folder_name"
cd "$folder_name"

echo "下载BuildTools..."
wget https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar

echo "构建Spigot服务器..."
sleep 3

# 自动选择最佳Java版本
if $IS_TERMUX; then
    # Termux环境只使用openjdk-17
    JAVA_CMD="java"
    echo "Termux环境使用默认Java版本"
else
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
fi

# 根据架构优化构建参数
ARCH=$(uname -m)
if [[ "$ARCH" == *"arm"* || "$ARCH" == *"aarch"* ]]; then
    BUILD_OPTIONS="--rev $selected_version --compile craftbukkit --remapped"
    echo "ARM架构检测，使用优化构建参数"
else
    BUILD_OPTIONS="--rev $selected_version"
fi

# 执行构建
$JAVA_CMD -jar BuildTools.jar $BUILD_OPTIONS

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
motd=Termux优化Spigot服务器
EOF

# 创建启动脚本
cat << EOF > start.sh
#!/bin/bash

# 自动检测最佳Java版本
if $IS_TERMUX; then
    # Termux环境使用默认Java
    JAVA_CMD="java"
else
    if [ -f /usr/lib/jvm/java-17/bin/java ]; then
        JAVA_CMD="/usr/lib/jvm/java-17/bin/java"
    elif [ -f /usr/bin/java-17 ]; then
        JAVA_CMD="java-17"
    elif [ -f /data/data/com.termux/files/usr/bin/java ]; then
        JAVA_CMD="/data/data/com.termux/files/usr/bin/java"
    else
        JAVA_CMD="java"
    fi
fi

# 根据架构设置内存
ARCH=\$(uname -m)
if [[ "\$ARCH" == *"arm"* || "\$ARCH" == *"aarch"* ]]; then
    MEM_OPTIONS="-Xmx1024M -Xms512M"
else
    MEM_OPTIONS="-Xmx2048M -Xms1024M"
fi

# 查找最新构建的jar文件
SERVER_JAR=\$(ls -t spigot-*.jar | head -1)

if [ -z "\$SERVER_JAR" ]; then
    echo "错误: 未找到服务器JAR文件!"
    exit 1
fi

# 启动服务器
echo "使用Java版本: \$(\$JAVA_CMD -version 2>&1 | head -1)"
echo "内存设置: \$MEM_OPTIONS"
echo "启动服务器jar: \$SERVER_JAR"

\$JAVA_CMD \$MEM_OPTIONS -jar \$SERVER_JAR nogui
EOF

chmod +x start.sh

echo "================================================="
echo "Spigot服务器安装完成！"
echo "目录位置: $WORK_DIR/$folder_name"
echo "启动命令: ./start.sh"
echo "服务器端口: 25565"
echo ""
echo "Termux注意事项:"
echo "1. Termux目前只支持openjdk-17，旧版本可能无法构建"
echo "2. 若下载慢，请运行: termux-change-repo 选择中国镜像"
echo "3. ARM设备构建时间可能较长(30分钟以上)，请耐心等待"
echo "4. 首次启动后，按Ctrl+C停止服务器，然后编辑server.properties配置"
echo "5. 需要保持Termux后台运行: 执行 termux-wake-lock"
echo "================================================="
