#!/bin/bash
# Folia 服务器全平台安装脚本 (修复权限问题)
# 支持 Termux (Android) 和 Linux (x86_64, aarch64, armv7)

# 检测运行环境
detect_environment() {
    if command -v termux-setup-storage &> /dev/null; then
        echo "termux"
    else
        echo "linux"
    fi
}

# 检测系统架构
detect_architecture() {
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)    echo "x86_64" ;;
        aarch64)   echo "aarch64" ;;
        armv7l)    echo "armv7" ;;
        *)         echo "unsupported" ;;
    esac
}

# 安装基本依赖
install_dependencies() {
    ENV=$1
    ARCH=$2
    
    echo "安装基本依赖..."
    
    case "$ENV" in
        termux)
            echo "检测到 Termux 环境 (Android)"
            echo "请确保已授予存储权限"
            termux-setup-storage
            
            echo "更新软件包..."
            pkg update -y
            pkg upgrade -y
            
            echo "安装必要工具..."
            pkg install -y wget curl jq openjdk-17 openssl
            ;;
        linux)
            echo "检测到 Linux 环境"
            DISTRO=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"' || echo "unknown")
            
            case "$DISTRO" in
                ubuntu|debian)
                    sudo apt update
                    sudo apt upgrade -y
                    sudo apt install -y wget curl jq openjdk-17-jdk
                    ;;
                centos|fedora|rhel)
                    sudo yum update -y
                    sudo yum install -y wget curl jq java-17-openjdk-devel
                    ;;
                arch|manjaro)
                    sudo pacman -Syu --noconfirm
                    sudo pacman -S --noconfirm wget curl jq jdk-openjdk
                    ;;
                *)
                    echo "警告: 无法识别的发行版 - 尝试通用安装"
                    if command -v apt &> /dev/null; then
                        sudo apt update
                        sudo apt install -y wget curl jq openjdk-17-jdk
                    elif command -v yum &> /dev/null; then
                        sudo yum install -y wget curl jq java-17-openjdk-devel
                    elif command -v pacman &> /dev/null; then
                        sudo pacman -S --noconfirm wget curl jq jdk-openjdk
                    else
                        install_manual_tools "$ARCH"
                    fi
                    ;;
            esac
            ;;
    esac
    
    # 验证Java安装
    if ! command -v java &> /dev/null; then
        echo "错误: Java安装失败"
        exit 1
    fi
}

# 手动安装工具
install_manual_tools() {
    ARCH=$1
    echo "手动安装必要工具..."
    
    # 安装wget
    if ! command -v wget &> /dev/null; then
        echo "安装wget..."
        if [ "$ARCH" = "x86_64" ]; then
            curl -o wget.tar.gz https://ftp.gnu.org/gnu/wget/wget-1.21.4.tar.gz
        else
            curl -o wget.tar.gz https://ftp.gnu.org/gnu/wget/wget-1.21.4.tar.gz
        fi
        tar -xzf wget.tar.gz
        cd wget-1.21.4
        ./configure
        make
        sudo make install
        cd ..
        rm -rf wget*
    fi
    
    # 安装jq
    if ! command -v jq &> /dev/null; then
        echo "安装jq..."
        case "$ARCH" in
            x86_64)
                curl -L https://github.com/jqlang/jq/releases/download/jq-1.6/jq-linux64 -o jq
                ;;
            aarch64)
                curl -L https://github.com/jqlang/jq/releases/download/jq-1.6/jq-linux64 -o jq
                ;;
            armv7)
                curl -L https://github.com/jqlang/jq/releases/download/jq-1.6/jq-linux32 -o jq
                ;;
            *)
                curl -L https://github.com/jqlang/jq/releases/download/jq-1.6/jq-linux64 -o jq
                ;;
        esac
        chmod +x jq
        sudo mv jq /usr/local/bin/
    fi
    
    # 安装Java
    install_java_for_arch "$ARCH"
}

# 根据架构安装Java
install_java_for_arch() {
    ARCH=$1
    
    case "$ARCH" in
        x86_64)
            echo "为x86_64安装Java 17..."
            curl -L https://download.java.net/java/GA/jdk17.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-17.0.2_linux-x64_bin.tar.gz -o jdk.tar.gz
            ;;
        aarch64)
            echo "为aarch64安装Java 17..."
            curl -L https://download.java.net/java/GA/jdk17.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-17.0.2_linux-aarch64_bin.tar.gz -o jdk.tar.gz
            ;;
        armv7)
            echo "为armv7安装Java 17..."
            curl -L https://download.java.net/java/GA/jdk17.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-17.0.2_linux-arm_bin.tar.gz -o jdk.tar.gz
            ;;
        *)
            echo "为通用架构安装Java 17..."
            curl -L https://download.java.net/java/GA/jdk17.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-17.0.2_linux-x64_bin.tar.gz -o jdk.tar.gz
            ;;
    esac
    
    tar -xzf jdk.tar.gz
    sudo mv jdk-17.0.2 /opt/
    sudo ln -s /opt/jdk-17.0.2/bin/java /usr/local/bin/java
    rm jdk.tar.gz
}

# 获取所有可用版本
get_available_versions() {
    echo "正在获取Folia可用版本..."
    api_url="https://api.papermc.io/v2/projects/folia"
    
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
    api_url="https://api.papermc.io/v2/projects/folia/versions/$version"
    
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
    api_url="https://api.papermc.io/v2/projects/folia/versions/$version/builds/$build"
    
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

# 安装Folia服务器
install_folia() {
    ENV=$1
    ARCH=$2
    
    # 获取用户输入
    read -p "请输入Minecraft版本 (例如: 1.20.1): " selected_version
    
    # 检查版本是否存在
    if ! check_version_exists "$selected_version"; then
        echo "错误: 版本 $selected_version 不可用"
        echo "可用版本:"
        get_available_versions
        exit 1
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
    case "$ENV" in
        termux)
            folder_name="/sdcard/folia-${selected_version//./_}"
            ;;
        *)
            folder_name="$HOME/folia-${selected_version//./_}"
            ;;
    esac
    
    counter=1
    while [ -d "$folder_name" ]; do
        folder_name="${folder_name}-$counter"
        ((counter++))
    done
    
    mkdir -p "$folder_name"
    cd "$folder_name" || { echo "无法进入目录 $folder_name"; exit 1; }
    echo "已创建安装目录: $(pwd)"
    
    # 下载Folia服务器
    download_url="https://api.papermc.io/v2/projects/folia/versions/$selected_version/builds/$build_number/downloads/$filename"
    echo "正在下载Folia服务器..."
    echo "下载地址: $download_url"
    
    if command -v wget &> /dev/null; then
        wget --show-progress -O "$filename" "$download_url"
    else
        curl -L -o "$filename" "$download_url"
    fi
    
    if [ ! -f "$filename" ]; then
        echo "错误: 文件下载失败"
        exit 1
    fi
    
    file_size=$(($(stat -c%s "$filename" 2>/dev/null || stat -f%z "$filename") / 1024 / 1024))
    echo "下载成功: $filename (大小: ${file_size}MB)"
    
    # 创建启动脚本
    create_start_script "$selected_version" "$build_number" "$filename" "$ENV" "$ARCH"
    
    # 创建服务器配置文件
    create_server_config "$ENV" "$ARCH"
    
    # 首次启动服务器
    first_launch "$ENV" "$ARCH"
}

# 创建启动脚本 (环境优化)
create_start_script() {
    local version=$1
    local build=$2
    local filename=$3
    local env=$4
    local arch=$5
    
    # 根据环境和架构设置参数
    case "$env" in
        termux)
            memory="2G"
            gc_args="-XX:+UseSerialGC"
            extra_args=""
            java_cmd="java"
            ;;
        *)
            case "$arch" in
                x86_64)
                    memory="4G"
                    gc_args="-XX:+UseG1GC"
                    extra_args=""
                    ;;
                aarch64)
                    memory="4G"
                    gc_args="-XX:+UseZGC"
                    extra_args=""
                    ;;
                armv7)
                    memory="2G"
                    gc_args="-XX:+UseSerialGC"
                    extra_args="-XX:MaxRAMFraction=2"
                    ;;
                *)
                    memory="3G"
                    gc_args="-XX:+UseG1GC"
                    extra_args=""
                    ;;
            esac
            
            # 自动检测Java路径
            java_cmd="java"
            if [ -f "/usr/lib/jvm/java-17-openjdk-amd64/bin/java" ]; then
                java_cmd="/usr/lib/jvm/java-17-openjdk-amd64/bin/java"
            elif [ -f "/usr/lib/jvm/java-17-openjdk-arm64/bin/java" ]; then
                java_cmd="/usr/lib/jvm/java-17-openjdk-arm64/bin/java"
            fi
            ;;
    esac
    
    cat > start.sh <<EOF
#!/bin/bash
# Folia 服务器启动脚本
# 环境: $env
# 架构: $arch
# 版本: $version
# 构建号: $build
# 文件: $filename

# 设置Java内存大小
MEMORY="$memory"

# 启动服务器
echo "启动 Folia $version (构建 $build)"
echo "运行环境: $env"
echo "系统架构: $arch"
echo "分配内存: \$MEMORY"
echo "服务器文件: $filename"

# Folia优化参数
$java_cmd -Xms\$MEMORY -Xmx\$MEMORY $gc_args \\
    -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 \\
    -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC \\
    -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 \\
    -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M \\
    -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 \\
    -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 \\
    -XX:G1MixedGCLiveThresholdPercent=90 \\
    -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 \\
    -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 \\
    -Dfolia.metrics-token=disabled \\
    $extra_args \\
    -jar "$filename" nogui
EOF

    # 确保权限正确
    chmod +x start.sh
    echo "已创建启动脚本 (针对 $env/$arch 优化)"
    
    # 验证权限
    if [ ! -x "start.sh" ]; then
        echo "警告: 无法设置执行权限，尝试使用替代方法启动"
        echo "启动命令: bash start.sh"
    fi
}

# 创建服务器配置文件 (环境优化)
create_server_config() {
    ENV=$1
    ARCH=$2
    
    # eula.txt
    echo "eula=true" > eula.txt
    
    # 根据环境设置玩家数量
    case "$ENV" in
        termux)
            max_players=10
            ;;
        *)
            max_players=100
            ;;
    esac
    
    # server.properties
    cat > server.properties <<EOF
# Folia服务器属性
# 生成时间: $(date)
# 环境: $ENV
# 架构: $ARCH
server-port=25565
level-seed=
gamemode=survival
difficulty=easy
max-players=$max_players
online-mode=true
white-list=false
motd=Folia服务器 ($ENV/$ARCH)
view-distance=6
simulation-distance=6
spawn-protection=0
enable-command-block=true
announce-player-achievements=false
pvp=true
allow-flight=true
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

# Folia特定配置
# 线程池设置
folia.region-thread-count=4
folia.io-threads=2

# 区域设置
folia.region-size=16x16
folia.region-tick-overlap=1

# 性能优化
folia.reduce-concurrent-chunk-loads=true
folia.use-optimized-worldgen=true
folia.async-light-updates=true
folia.async-chunk-saving=true

# 调试设置
folia.debug=false
folia.profile=false
EOF

    # Folia需要额外的配置文件
    mkdir -p config
    cat > config/folia-global.yml <<EOF
# Folia 全局配置
# 此文件适用于整个服务器
# 环境: $ENV
# 架构: $ARCH

# 线程池设置
thread-pools:
  region:
    threads: 4
    priority: 5
  io:
    threads: 2
    priority: 5
  generation:
    threads: 2
    priority: 4
    
# 区域设置
region:
  size: 16x16  # 区域大小（以区块为单位）
  tick-overlap: 1  # 区域间的重叠区块数
  
# 性能优化
performance:
  reduce-concurrent-chunk-loads: true
  use-optimized-worldgen: true
  async-light-updates: true
  async-chunk-saving: true
  
# 调试
debug: false
profile: false
EOF
}

# 首次启动服务器
first_launch() {
    ENV=$1
    ARCH=$2
    
    echo "首次启动Folia服务器..."
    case "$ENV" in
        termux)
            echo "在Termux中运行服务器..."
            echo "提示:"
            echo "1. 保持应用在前台运行"
            echo "2. 不要锁定屏幕或切换到其他应用"
            echo "3. 服务器可能会在后台被终止"
            ;;
        *)
            echo "这可能需要几分钟时间，请耐心等待..."
            ;;
    esac
    echo "--------------------------------------"
    
    # 双重验证执行权限
    if [ ! -x "start.sh" ]; then
        echo "修复执行权限..."
        chmod +x start.sh
    fi
    
    # 确保脚本可执行
    if [ -x "start.sh" ]; then
        echo "使用: ./start.sh 启动服务器"
        ./start.sh
    else
        echo "警告: 无法执行启动脚本，使用替代方法"
        echo "启动命令: bash start.sh"
        bash start.sh
    fi
    
    echo ""
    echo "======================================"
    echo "Folia 服务器安装完成！"
    echo "目录: $(pwd)"
    echo "环境: $ENV"
    echo "架构: $ARCH"
    echo ""
    echo "启动命令:"
    echo "  cd $(pwd) && ./start.sh"
    echo ""
    echo "备选启动命令:"
    echo "  bash start.sh"
    echo ""
    echo "管理命令:"
    echo "  stop          - 在控制台输入 'stop'"
    echo "  restart       - 在控制台输入 'restart'"
    echo "  backup        - 手动备份整个服务器目录"
    echo ""
    echo "注意事项:"
    case "$ENV" in
        termux)
            echo "1. Termux环境下建议最大玩家数不超过10人"
            echo "2. 避免在后台运行服务器"
            echo "3. 使用2GB内存配置"
            echo "4. 可能需要手动允许电池优化例外"
            ;;
        *)
            echo "1. 建议使用4GB以上内存"
            echo "2. 可编辑start.sh增加内存: MEMORY=\"8G\""
            ;;
    esac
    echo "3. Folia官网: https://papermc.io/software/folia"
    echo "4. 遇到问题请查看日志: logs/latest.log"
    echo "======================================"
}

# 主程序
main() {
    clear
    echo "======================================"
    echo "    Folia 服务器全平台安装脚本"
    echo "      修复权限问题版"
    echo "======================================"
    echo "支持 Termux (Android) 和 Linux 系统"
    echo "10秒钟后开始安装..."
    sleep 10
    
    # 检测环境
    ENV=$(detect_environment)
    ARCH=$(detect_architecture)
    
    echo "检测到环境: $ENV"
    echo "检测到架构: $ARCH"
    
    if [ "$ARCH" = "unsupported" ]; then
        echo "错误: 不支持的架构 $ARCH"
        exit 1
    fi
    
    # 安装依赖
    install_dependencies "$ENV" "$ARCH"
    
    # 安装Folia
    install_folia "$ENV" "$ARCH"
}

# 启动主程序
main
