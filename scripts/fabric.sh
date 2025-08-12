#!/bin/bash

# 全自动跨平台Fabric服务器安装脚本
# 支持Termux和各种Linux发行版

clear
echo "========================================"
echo "    跨平台Fabric服务器安装脚本"
echo "  支持Termux, Ubuntu, Debian, CentOS等"
echo "========================================"
echo "允许输入任意Minecraft版本（如1.20.1）"
echo "脚本将自动检查Fabric官网是否支持该版本"
echo "========================================"

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

# 安装必要软件
install_dependencies() {
    echo "正在安装必要软件..."
    
    if $IS_TERMUX; then
        echo "检测到Termux环境"
        $PKG_MANAGER update -y
        $PKG_MANAGER upgrade -y
        
        # 解决镜像问题
        if ! termux-change-repo; then
            echo "提示：运行 termux-change-repo 选择中国镜像源可加速下载"
        fi
        
        $PKG_MANAGER install wget curl jq -y
    else
        echo "检测到Linux环境"
        case $PKG_MANAGER in
            "apt")
                sudo $PKG_MANAGER update
                sudo $PKG_MANAGER install -y curl jq wget
                ;;
            "yum")
                sudo $PKG_MANAGER install -y epel-release
                sudo $PKG_MANAGER install -y curl jq wget
                ;;
            "apk")
                sudo $PKG_MANAGER update
                sudo $PKG_MANAGER add curl jq wget
                ;;
        esac
    fi
    
    if ! command -v curl &> /dev/null || ! command -v jq &> /dev/null; then
        echo "错误：无法安装curl或jq，请检查网络连接"
        exit 1
    fi
}

install_dependencies

# 检查Java安装
install_java() {
    echo "检测到Java未安装或版本不兼容，正在安装Java环境..."
    
    if $IS_TERMUX; then
        $PKG_MANAGER install openjdk-17 -y
        echo "Java环境安装完成！"
    else
        case $PKG_MANAGER in
            "apt")
                sudo $PKG_MANAGER install -y openjdk-17-jdk
                ;;
            "yum")
                sudo $PKG_MANAGER install -y java-17-openjdk
                ;;
            "apk")
                sudo $PKG_MANAGER add openjdk17-jdk
                ;;
        esac
        echo "Java 17 安装完成！"
    fi
    
    # Termux 需要额外的权限
    if $IS_TERMUX; then
        termux-setup-storage
    fi
}

if ! command -v java &> /dev/null; then
    install_java
else
    # 检查Java版本是否兼容
    JAVA_VERSION=$(java -version 2>&1 | head -1 | cut -d '"' -f2 | cut -d '.' -f1)
    if [ "$JAVA_VERSION" -lt 17 ]; then
        echo "检测到旧版Java (版本 $JAVA_VERSION)，需要Java 17+"
        install_java
    fi
fi

# 固定安装器版本
INSTALLER_VERSION="1.1.0"

# 函数：检查版本是否受支持
check_version_supported() {
    local mc_version=$1
    local api_url="https://meta.fabricmc.net/v2/versions/loader/$mc_version"
    local response=$(curl -s "$api_url")
    
    # 检查响应是否包含有效数据
    if [ -z "$response" ] || [ "$response" == "[]" ]; then
        return 1
    fi
    
    # 尝试解析加载器版本
    local loader_version=$(echo "$response" | jq -r '.[0].loader.version' 2>/dev/null)
    
    if [ -z "$loader_version" ] || [ "$loader_version" == "null" ]; then
        return 1
    fi
    
    return 0
}

# 函数：获取Fabric加载器版本
get_fabric_loader() {
    local mc_version=$1
    local api_url="https://meta.fabricmc.net/v2/versions/loader/$mc_version"
    
    # 获取API响应
    local response=$(curl -s "$api_url")
    
    if [ -z "$response" ]; then
        echo "错误：无法获取 $mc_version 的加载器信息" >&2
        return 1
    fi
    
    # 解析JSON数据
    local loader_version=$(echo "$response" | jq -r '.[0].loader.version')
    
    if [ -z "$loader_version" ] || [ "$loader_version" == "null" ]; then
        echo "错误：无法获取 $mc_version 的Fabric加载器版本" >&2
        return 1
    fi
    
    echo "$loader_version"
}

# 函数：获取推荐版本
get_recommended_versions() {
    echo "正在获取推荐的Minecraft版本..." >&2
    local api_url="https://meta.fabricmc.net/v2/versions/game"
    local response=$(curl -s "$api_url")
    
    if [ -z "$response" ]; then
        echo "错误：无法获取推荐版本列表" >&2
        return 1
    fi
    
    local versions=($(echo "$response" | jq -r '.[].version' | sort -Vr | head -5))
    
    if [ ${#versions[@]} -eq 0 ]; then
        echo "错误：无法解析推荐版本列表" >&2
        return 1
    fi
    
    echo "${versions[@]}"
}

# 主程序开始
while true; do
    echo "========================================"
    echo "请输入要安装的Minecraft版本（例如: 1.20.1）"
    echo "----------------------------------------"
    
    # 显示推荐版本
    recommended_versions=($(get_recommended_versions 2>/dev/null || true))
    if [ ${#recommended_versions[@]} -gt 0 ]; then
        echo "推荐版本:"
        for version in "${recommended_versions[@]}"; do
            echo "  - $version"
        done
    fi
    
    echo "输入 'exit' 退出脚本"
    echo "========================================"
    
    # 获取用户输入
    read -p "请输入Minecraft版本号: " selected_version
    
    # 检查是否退出
    if [ "$selected_version" == "exit" ]; then
        echo "退出脚本"
        exit 0
    fi
    
    # 验证输入格式
    if [[ ! "$selected_version" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
        echo "错误：版本号格式无效 (示例: 1.20.1 或 1.18)" >&2
        sleep 2
        continue
    fi
    
    # 检查版本是否受支持
    echo "正在检查 $selected_version 是否受Fabric支持..."
    if check_version_supported "$selected_version"; then
        echo "✅ $selected_version 受Fabric支持!"
        break
    else
        echo "❌❌ 错误：$selected_version 不受Fabric支持或版本号无效" >&2
        echo "请尝试其他版本或检查拼写是否正确" >&2
        sleep 2
    fi
done

sleep 2

# 获取Fabric加载器版本
echo "正在获取Fabric加载器信息..."
loader_version=$(get_fabric_loader "$selected_version")
if [ $? -ne 0 ]; then
    echo "$loader_version" >&2
    echo "无法获取Fabric加载器版本，请稍后重试" >&2
    exit 1
fi

echo "----------------------------------------"
echo "Minecraft版本: $selected_version"
echo "Fabric加载器: $loader_version"
echo "安装器版本:   $INSTALLER_VERSION"
echo "----------------------------------------"
sleep 3

# 创建文件夹
folder_name="${selected_version//./_}_fabric"
counter=1
while [ -d "$folder_name" ]; do
    folder_name="${selected_version//./_}_fabric$counter"
    ((counter++))
done

echo "创建服务器目录: $folder_name"
mkdir -p "$folder_name"
cd "$folder_name" || exit 1

# 下载服务器文件
echo "正在下载Fabric服务器..."
download_url="https://meta.fabricmc.net/v2/versions/loader/$selected_version/$loader_version/$INSTALLER_VERSION/server/jar"
echo "下载链接: $download_url"

# 确保文件名正确
target_file="fabric-server-mc.${selected_version}-loader.${loader_version}-launcher.${INSTALLER_VERSION}.jar"

# 使用curl下载，添加超时和重试
curl -L --retry 3 --retry-delay 5 --connect-timeout 30 -o "$target_file" "$download_url"

# 检查下载是否成功
if [ ! -f "$target_file" ]; then
    echo "错误：下载服务器文件失败" >&2
    echo "请检查URL是否有效: $download_url" >&2
    exit 1
fi

# 检查文件大小 - 至少100KB
file_size=$(stat -c%s "$target_file" 2>/dev/null || stat -f%z "$target_file")
if [ "$file_size" -lt 102400 ]; then
    echo "错误：下载的文件过小（${file_size}字节），可能是无效文件" >&2
    echo "文件内容:"
    head -c 500 "$target_file"
    rm -f "$target_file"
    exit 1
fi

echo "服务器文件已保存为: $target_file (大小: $((file_size/1024))KB)"
sleep 2

# ==========================================================
# 先生成所有配置文件
# ==========================================================

echo "创建配置文件..."

# 创建eula.txt
echo "eula=true" > eula.txt
echo "  - 已创建并同意EULA协议 (eula.txt)"

# 创建server.properties
cat > server.properties <<EOL
# Minecraft服务器配置
# 版本: $selected_version
# 时间: $(date)
max-tick-time=60000
generator-settings=
force-gamemode=false
allow-nether=true
gamemode=survival
broadcast-console-to-ops=true
enable-query=false
player-idle-timeout=0
difficulty=easy
spawn-monsters=true
op-permission-level=4
pvp=true
snooper-enabled=false
level-type=default
hardcore=false
enable-command-block=false
max-players=20
network-compression-threshold=256
resource-pack-sha1=
max-world-size=29999984
server-port=25565
server-ip=
spawn-npcs=true
allow-flight=false
level-name=world
view-distance=10
resource-pack=
spawn-animals=true
white-list=false
generate-structures=true
online-mode=true
max-build-height=256
level-seed=
prevent-proxy-connections=false
enable-rcon=false
motd=Fabric服务器 - $selected_version
EOL
echo "  - 已创建服务器配置文件 (server.properties)"

# 创建启动脚本
cat > start.sh <<EOL
#!/bin/bash
# Fabric服务器启动脚本
# 版本: $selected_version
# 自动生成于: $(date)

echo "========================================"
echo "启动Fabric服务器 - $selected_version"
echo "内存分配: 2GB (可根据需要修改-Xmx参数)"
echo "启动命令: java -Xmx2G -jar $target_file nogui"
echo "========================================"

# 根据架构设置内存
ARCH=\$(uname -m)
if [[ "\$ARCH" == *"arm"* || "\$ARCH" == *"aarch"* ]]; then
    MEM_OPTIONS="-Xmx1024M -Xms512M"
else
    MEM_OPTIONS="-Xmx2G -Xms1G"
fi

java \$MEM_OPTIONS -jar "$target_file" nogui
EOL

chmod +x start.sh
echo "  - 已创建启动脚本 (start.sh)"

# 创建停止脚本
cat > stop.sh <<EOL
#!/bin/bash
# Fabric服务器停止脚本
echo "正在停止Fabric服务器..."
pkill -f "$target_file"
echo "服务器已停止"
EOL

chmod +x stop.sh
echo "  - 已创建停止脚本 (stop.sh)"

# ==========================================================
# 首次运行服务器（使用--installServer参数）
# ==========================================================

echo "首次运行服务器（安装必要组件）..."
echo "使用参数: --installServer"

# 运行安装命令
if ! java -Xmx2G -jar "$target_file" --installServer > server_install.log 2>&1; then
    echo "首次运行服务器时出现问题，请检查日志: $(pwd)/server_install.log" >&2
    echo "日志内容:"
    head -n 20 server_install.log
    
    # Termux特定错误处理
    if $IS_TERMUX; then
        echo "========================================"
        echo "Termux特定建议:"
        echo "1. 确保已授予存储权限: termux-setup-storage"
        echo "2. 如果内存不足，尝试编辑start.sh减小内存设置"
        echo "3. 使用命令: pkg install openjdk-17 确保Java安装正常"
        echo "4. 尝试运行: termux-change-repo 选择其他镜像源"
        echo "========================================"
    fi
    
    exit 1
fi

echo "服务器组件安装完成！"
sleep 2

# ==========================================================
# 完成信息
# ==========================================================

echo "========================================"
echo "Fabric服务器安装完成！"
echo "----------------------------------------"
echo "服务器目录: $(pwd)"
echo "启动命令: ./start.sh"
echo "停止命令: ./stop.sh"
echo "配置文件: server.properties (可修改服务器设置)"
echo "EULA协议: eula.txt (已自动同意)"
echo "----------------------------------------"
echo "管理命令:"
echo "  - 停止服务器: 输入 stop"
echo "  - 保存世界: 输入 save-all"
echo "  - 重新加载: 输入 reload"
echo "----------------------------------------"

# 根据环境显示特定信息
if $IS_TERMUX; then
    echo "Termux使用说明:"
    echo "1. 启动服务器后按Ctrl+A+D保持后台运行"
    echo "2. 重新连接会话: screen -r"
    echo "3. 防止系统休眠: termux-wake-lock"
    echo "4. 关闭服务器: 先输入stop，然后按Ctrl+C"
else
    echo "*** Java版本帮助:"
    echo "如果出现Java版本错误，使用以下命令切换JDK版本:"
    echo "sudo update-alternatives --config java"
fi

echo "========================================"
echo "安装的Fabric版本信息:"
echo "  - Minecraft: $selected_version"
echo "  - 加载器: $loader_version"
echo "  - 安装器: $INSTALLER_VERSION"
echo "========================================"
echo ""
echo "要启动服务器，请运行:"
echo "cd $(pwd) && ./start.sh"
