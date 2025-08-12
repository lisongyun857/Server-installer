#!/bin/bash
# PaperMC 服务器跨平台安装脚本
# 支持Termux、Ubuntu、Debian、CentOS等系统

clear
echo "======================================"
echo "    PaperMC 服务器跨平台安装脚本"
echo "  支持Termux、Ubuntu、Debian、CentOS等"
echo "======================================"
echo "10秒钟后开始安装..."
sleep 10

# 检测运行环境
if [ -d "/data/data/com.termux/files/usr" ]; then
    IS_TERMUX=true
    PKG_MANAGER="pkg"
    JAVA_HOME="/data/data/com.termux/files/usr"
    echo "检测到Termux环境"
else
    IS_TERMUX=false
    if command -v apt &> /dev/null; then
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

# 安装基本依赖
install_dependencies() {
    echo "安装基本依赖..."
    
    if $IS_TERMUX; then
        # Termux环境
        $PKG_MANAGER update -y
        $PKG_MANAGER upgrade -y
        $PKG_MANAGER install -y wget jq openjdk-17
        
        # 解决镜像问题
        if ! termux-change-repo; then
            echo "提示：运行 termux-change-repo 选择中国镜像源可加速下载"
        fi
    else
        # 常规Linux环境
        case $PKG_MANAGER in
            "apt")
                sudo $PKG_MANAGER update
                sudo $PKG_MANAGER install -y wget curl jq openjdk-17-jdk
                ;;
            "yum")
                sudo $PKG_MANAGER update -y
                sudo $PKG_MANAGER install -y wget curl jq java-17-openjdk-devel
                ;;
            "apk")
                sudo $PKG_MANAGER update
                sudo $PKG_MANAGER add wget curl jq openjdk17-jdk
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

# 获取所有可用版本
get_available_versions() {
    echo "正在获取PaperMC可用版本..."
    api_url="https://api.papermc.io/v2/projects/paper"
    
    # 尝试多次获取
    for i in {1..3}; do
        versions=$(curl -s "$api_url" | jq -r '.versions[]' | sort -Vr)
        if [ -n "$versions" ]; then
            echo "$versions"
            return 0
        fi
        echo "尝试 $i 获取版本列表失败，2秒后重试..."
        sleep 2
    done
    
    echo "错误: 无法获取版本列表"
    echo "请检查网络连接或访问: https://papermc.io/downloads"
    return 1
}

# 检查版本是否存在
check_version_exists() {
    local version="$1"
    versions=$(get_available_versions)
    if [ -z "$versions" ]; then
        return 1
    fi
    
    if echo "$versions" | grep -q "^$version$"; then
        return 0
    else
        return 1
    fi
}

# 获取最新构建信息
get_latest_build_info() {
    local version="$1"
    api_url="https://api.papermc.io/v2/projects/paper/versions/$version"
    
    # 尝试多次获取
    for i in {1..3}; do
        build_info=$(curl -s "$api_url")
        if [ -n "$build_info" ]; then
            builds=$(echo "$build_info" | jq '.builds | map(tonumber) | max')
            if [ "$builds" != "null" ] && [ -n "$builds" ]; then
                echo "$builds"
                return 0
            fi
        fi
        echo "尝试 $i 获取构建信息失败，2秒后重试..."
        sleep 2
    done
    
    echo "错误: 无法获取构建信息"
    return 1
}

# 获取下载信息
get_download_info() {
    local version="$1"
    local build="$2"
    api_url="https://api.papermc.io/v2/projects/paper/versions/$version/builds/$build"
    
    # 尝试多次获取
    for i in {1..3}; do
        download_info=$(curl -s "$api_url")
        if [ -n "$download_info" ]; then
            filename=$(echo "$download_info" | jq -r '.downloads.application.name')
            sha256=$(echo "$download_info" | jq -r '.downloads.application.sha256')
            
            if [ -n "$filename" ] && [ -n "$sha256" ]; then
                echo "$filename $sha256"
                return 0
            fi
        fi
        echo "尝试 $i 获取下载信息失败，2秒后重试..."
        sleep 2
    done
    
    echo "错误: 无法获取下载信息"
    return 1
}

# 安装PaperMC服务器
install_paper() {
    # 显示可用版本
    echo "可用版本:"
    available_versions=$(get_available_versions)
    if [ -z "$available_versions" ]; then
        echo "无法获取版本列表，使用默认值1.20.1"
        selected_version="1.20.1"
    else
        echo "$available_versions" | head -5
        echo "更多版本请访问: https://papermc.io/downloads"
        
        # 获取用户输入
        read -p "请输入Minecraft版本 (例如: 1.20.1): " selected_version
    fi
    
    # 检查版本是否存在
    if ! check_version_exists "$selected_version"; then
        echo "警告: 版本 $selected_version 不可用，尝试使用最新版本"
        selected_version=$(echo "$available_versions" | head -1)
        echo "使用最新版本: $selected_version"
    fi
    
    echo "版本 $selected_version 可用"
    
    # 获取最新构建号
    build_number=$(get_latest_build_info "$selected_version")
    if [ -z "$build_number" ]; then
        echo "错误: 无法获取构建号"
        exit 1
    fi
    
    echo "最新构建号: $build_number"
    
    # 获取下载信息
    download_info=$(get_download_info "$selected_version" "$build_number")
    if [ -z "$download_info" ]; then
        echo "错误: 无法获取下载信息"
        exit 1
    fi
    
    filename=$(echo "$download_info" | cut -d' ' -f1)
    sha256=$(echo "$download_info" | cut -d' ' -f2)
    
    # 创建安装目录
    folder_name="paper-${selected_version//./_}"  # 替换点号为下划线
    counter=1
    while [ -d "$folder_name" ]; do
        folder_name="paper-${selected_version//./_}-$counter"
        ((counter++))
    done
    
    mkdir "$folder_name"
    cd "$folder_name" || exit
    echo "已创建安装目录: $(pwd)"
    
    # 下载Paper服务器
    download_url="https://api.papermc.io/v2/projects/paper/versions/$selected_version/builds/$build_number/downloads/$filename"
    echo "正在下载Paper服务器..."
    echo "下载地址: $download_url"
    
    # 根据环境选择下载工具
    if command -v wget &> /dev/null; then
        wget -q --show-progress -O "$filename" "$download_url"
    else
        curl -L -o "$filename" "$download_url"
    fi
    
    # 验证文件
    if [ ! -f "$filename" ]; then
        echo "错误: 文件下载失败"
        exit 1
    fi
    
    file_size=$(($(stat -c%s "$filename" 2>/dev/null || stat -f%z "$filename") / 1024 / 1024))
    echo "下载成功: $filename (大小: ${file_size}MB)"
    
    # 创建启动脚本
    create_start_script "$selected_version" "$build_number" "$filename"
    
    # 创建服务器配置文件
    create_server_config
    
    # 首次启动服务器
    first_launch
}

# 创建启动脚本
create_start_script() {
    local version=$1
    local build=$2
    local filename=$3
    
    cat > start.sh <<EOF
#!/bin/bash
# PaperMC 服务器启动脚本
# 版本: $version
# 构建号: $build
# 文件: $filename

# 设置Java内存大小 (默认: 1GB)
MEMORY="1G"
ARCH=\$(uname -m)

# 根据架构调整内存
if [[ "\$ARCH" == *"arm"* || "\$ARCH" == *"aarch"* ]]; then
    MEMORY="1G"
else
    MEMORY="2G"
fi

# 自动检测Java版本
JAVA_CMD="java"
if command -v java &> /dev/null; then
    # Termux环境使用默认Java
    if [ -d "/data/data/com.termux/files/usr" ]; then
        JAVA_CMD="java"
    # Linux环境优先使用Java 17
    elif [ -f "/usr/lib/jvm/java-17-openjdk-amd64/bin/java" ]; then
        JAVA_CMD="/usr/lib/jvm/java-17-openjdk-amd64/bin/java"
    elif [ -f "/usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java" ]; then
        JAVA_CMD="/usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java"
    fi
fi

# 启动服务器
echo "启动 PaperMC $version (构建 $build)"
echo "使用Java命令: \$JAVA_CMD"
echo "分配内存: \$MEMORY"
echo "服务器文件: $filename"

# 启用Aikar的内存优化参数
\$JAVA_CMD -Xms\$MEMORY -Xmx\$MEMORY -XX:+UseG1GC -XX:+ParallelRefProcEnabled \\
    -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC \\
    -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 \\
    -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 \\
    -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 \\
    -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 \\
    -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 \\
    -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true \\
    -jar "$filename" nogui
EOF

    chmod +x start.sh
    echo "已创建启动脚本"
}

# 创建服务器配置文件
create_server_config() {
    # eula.txt
    echo "eula=true" > eula.txt
    
    # server.properties
    cat > server.properties <<EOF
# Minecraft服务器属性
# 生成时间: $(date)
server-port=25565
level-seed=
gamemode=survival
difficulty=easy
max-players=20
online-mode=true
white-list=false
motd=PaperMC服务器一键安装脚本
view-distance=10
simulation-distance=10
spawn-protection=16
enable-command-block=false
announce-player-achievements=true
pvp=true
allow-flight=false
spawn-npcs=true
spawn-animals=true
spawn-monsters=true
generate-structures=true
max-tick-time=60000
enable-query=false
force-gamemode=false
hardcore=false
allow-nether=true
resource-pack=
network-compression-threshold=256
max-world-size=29999984
function-permission-level=2
rcon.port=25575
sync-chunk-writes=true
op-permission-level=4
prevent-proxy-connections=false
entity-broadcast-range-percentage=100
player-idle-timeout=0
broadcast-rcon-to-ops=true
broadcast-console-to-ops=true
EOF
}

# 首次启动服务器
first_launch() {
    echo "首次启动服务器，生成世界..."
    echo "这可能需要几分钟时间，请耐心等待..."
    echo "--------------------------------------"
    
    # 启动服务器
    ./start.sh
    
    echo ""
    echo "======================================"
    echo "PaperMC 服务器安装完成！"
    echo "目录: $(pwd)"
    echo ""
    echo "启动命令:"
    echo "  cd $(pwd) && ./start.sh"
    echo ""
    echo "管理命令:"
    echo "  stop          - 在控制台输入 'stop'"
    echo "  restart       - 在控制台输入 'restart'"
    echo "  backup        - 手动备份整个服务器目录"
    echo ""
    # 环境特定提示
    if $IS_TERMUX; then
        echo "Termux使用说明:"
        echo "1. 启动服务器前请运行: termux-wake-lock"
        echo "2. 后台运行: 按Ctrl+A然后按D"
        echo "3. 重新连接: screen -r"
        echo "4. 关闭服务器: 先输入stop，然后按Ctrl+C"
    else
        echo "Linux使用说明:"
        echo "1. 后台运行: nohup ./start.sh &"
        echo "2. 查看日志: tail -f logs/latest.log"
    fi
    echo ""
    echo "注意事项:"
    echo "1. 所有插件放入 plugins/ 目录"
    echo "2. 配置文件: server.properties"
    echo "3. 内存设置: 编辑 start.sh 中的 MEMORY 变量"
    echo "4. 服务器日志: logs/latest.log"
    echo "5. 下载的Paper版本: $selected_version (构建号: $build_number)"
    echo "6. 服务器端口: 25565 (确保防火墙开放此端口)"
    echo "======================================"
}

# 主程序
main() {
    install_dependencies
    install_paper
}

# 启动主程序
main
