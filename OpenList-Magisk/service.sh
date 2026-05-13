#!/system/bin/sh
# shellcheck shell=ash
# service.sh for OpenList Magisk Module

MODDIR="${0%/*}"
DATA_DIR="__PLACEHOLDER_DATA_DIR__"
OPENLIST_BINARY="__PLACEHOLDER_BINARY_PATH__"
MODULE_PROP_FILE="$MODDIR/module.prop"
LOG_FILE="$MODDIR/service.log"
TEMP_IP_FILE="$MODDIR/ip_result.tmp"
TEMP_PORT_FILE="$MODDIR/port_result.tmp"
WATCHDOG_PID_FILE="$MODDIR/watchdog.pid"

# 查找可用的 busybox 路径，兼容 Magisk 和 KSU
toast_find_busybox() {
    if [ -x "/data/adb/magisk/busybox" ]; then
        echo "/data/adb/magisk/busybox"
    elif [ -x "/data/adb/ksu/bin/busybox" ]; then
        echo "/data/adb/ksu/bin/busybox"
    elif [ -x "/data/adb/ap/bin/busybox" ]; then
        echo "/data/adb/ap/bin/busybox"
    elif command -v busybox >/dev/null; then
        echo "$(command -v busybox)"
    else
        echo ""
    fi
}

log() {
    # 日志轮转（限制日志文件大小 1MB）
    if [ -f "$LOG_FILE" ] && [ $(stat -c %s "$LOG_FILE" 2>/dev/null) -gt 1048576 ]; then
        mv "$LOG_FILE" "${LOG_FILE}.bak"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 日志文件已轮转" >> "$LOG_FILE"
    fi
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

get_lan_ip() {
    BUSYBOX=$(toast_find_busybox)
    if [ -x "$BUSYBOX" ]; then
        IP_CMD="$BUSYBOX ip"
        IFCONFIG_CMD="$BUSYBOX ifconfig"
        GREP_CMD="$BUSYBOX grep"
        AWK_CMD="$BUSYBOX awk"
        CUT_CMD="$BUSYBOX cut"
        HEAD_CMD="$BUSYBOX head"
    else
        IP_CMD="ip"
        IFCONFIG_CMD="ifconfig"
        GREP_CMD="grep"
        AWK_CMD="awk"
        CUT_CMD="cut"
        HEAD_CMD="head"
        log "警告: BusyBox 未找到，使用系统命令"
    fi

    MAX_RETRY=30
    RETRY_COUNT=0

    while [ $RETRY_COUNT -lt $MAX_RETRY ]; do
        WLAN_INTERFACE=$($IP_CMD link | $GREP_CMD "state UP" | $AWK_CMD '{print $2}' | $CUT_CMD -d: -f1 | $GREP_CMD -E "^wlan" | $HEAD_CMD -n 1)

        if [ -z "$WLAN_INTERFACE" ]; then
            log "未检测到活跃的 Wi-Fi 连接，使用移动数据模式"
            echo "localhost" > "$TEMP_IP_FILE"
            return 0
        fi

        INTERFACE=$($IP_CMD link | $GREP_CMD "state UP" | $AWK_CMD '{print $2}' | $CUT_CMD -d: -f1 | $GREP_CMD -E "wlan|eth|rmnet" | $HEAD_CMD -n 1)
        [ -z "$INTERFACE" ] && INTERFACE="wlan0"
        ip_address=$($IP_CMD addr show $INTERFACE | $GREP_CMD 'inet ' | $AWK_CMD '{print $2}' | $CUT_CMD -d/ -f1)
        if [ -z "$ip_address" ]; then
            ip_address=$($IFCONFIG_CMD $INTERFACE 2>/dev/null | $GREP_CMD "inet addr" | $AWK_CMD '{print $2}' | $CUT_CMD -d: -f2)
        fi
        if [ -n "$ip_address" ] && [ "$ip_address" != "无法获取IP" ]; then
            log "成功获取 IP: ip_address=$ip_address (尝试次数: $((RETRY_COUNT + 1)))"
            echo "$ip_address" > "$TEMP_IP_FILE"
            return 0
        fi
        log "未获取到有效 IP (尝试 $((RETRY_COUNT + 1))/$MAX_RETRY)，1秒后重试"
        sleep 1
        RETRY_COUNT=$((RETRY_COUNT + 1))
    done
    ip_address="无法获取IP"
    log "错误: 获取 IP 超时，ip_address=$ip_address"
    echo "$ip_address" > "$TEMP_IP_FILE"
}

get_port() {
    pid=$1
    BUSYBOX=$(toast_find_busybox)
    if [ -x "$BUSYBOX" ]; then
        GREP_CMD="$BUSYBOX grep"
        AWK_CMD="$BUSYBOX awk"
        CUT_CMD="$BUSYBOX cut"
        HEAD_CMD="$BUSYBOX head"
    else
        GREP_CMD="grep"
        AWK_CMD="awk"
        CUT_CMD="cut"
        HEAD_CMD="head"
        log "警告: BusyBox 未找到，使用系统命令"
    fi

    MAX_RETRY=30
    RETRY_COUNT=0
    port=""

    while [ $RETRY_COUNT -lt $MAX_RETRY ]; do
        port=$(ss -tulnp 2>/dev/null | $GREP_CMD "$pid" | $AWK_CMD '{print $5}' | $CUT_CMD -d':' -f2 | sort -u | $HEAD_CMD -n 1)
        if [ -z "$port" ] && command -v netstat >/dev/null; then
            port=$(netstat -tulnp 2>/dev/null | $GREP_CMD "$pid" | $AWK_CMD '{print $4}' | $CUT_CMD -d':' -f2 | sort -u | $HEAD_CMD -n 1)
        fi
        if [ -n "$port" ]; then
            log "成功获取 Openlist 端口: $port (尝试次数: $((RETRY_COUNT + 1)))"
            echo "$port" > "$TEMP_PORT_FILE"
            return 0
        fi
        log "未获取到 Openlist 端口 (PID: $pid, 尝试 $((RETRY_COUNT + 1))/$MAX_RETRY)，1秒后重试"
        sleep 1
        RETRY_COUNT=$((RETRY_COUNT + 1))
    done
    log "错误: 获取 Openlist 端口超时 (PID: $pid)"
    echo "" > "$TEMP_PORT_FILE"
}

update_module_prop_running() {
    get_lan_ip &
    IP_PID=$!
    pid=$(pgrep -f "$OPENLIST_BINARY server --data" 2>/dev/null | head -n 1)
    if [ -z "$pid" ]; then
        log "错误: 未找到运行中的 openlist"
        NEW_DESC="description=【未运行】无法找到 openlist 进程，请检查日志 $LOG_FILE"
        grep -v '^description=' "$MODULE_PROP_FILE" > "${MODULE_PROP_FILE}.tmp" 2>/dev/null
        echo "$NEW_DESC" >> "${MODULE_PROP_FILE}.tmp"
        mv "${MODULE_PROP_FILE}.tmp" "$MODULE_PROP_FILE" 2>/dev/null
        return 1
    else
        log "找到 Openlist PID: $pid"
        get_port "$pid" &
        PORT_PID=$!
    fi

    MAX_WAIT=30
    ELAPSED=0
    while [ $ELAPSED -lt $MAX_WAIT ]; do
        if [ -f "$TEMP_IP_FILE" ] && { [ -f "$TEMP_PORT_FILE" ] || [ -z "$pid" ]; }; then
            log "IP 和端口获取任务完成 (耗时: $ELAPSED 秒)"
            break
        fi
        sleep 1
        ELAPSED=$((ELAPSED + 1))
    done

    if [ $ELAPSED -ge $MAX_WAIT ]; then
        log "警告: 异步任务超时，强制终止后台任务"
        kill $IP_PID 2>/dev/null
        [ -n "$pid" ] && kill $PORT_PID 2>/dev/null
    fi

    CURRENT_IP=$(cat "$TEMP_IP_FILE" 2>/dev/null || echo "无法获取IP")
    rm -f "$TEMP_IP_FILE" 2>/dev/null
    log "最终 IP: $CURRENT_IP"

    if [ -n "$pid" ]; then
        port=$(cat "$TEMP_PORT_FILE" 2>/dev/null || echo "")
        rm -f "$TEMP_PORT_FILE" 2>/dev/null
        log "最终端口: $port"

        PASSWORD_TEXT=""
        if [ -f "${DATA_DIR}/初始密码.txt" ]; then
            PASSWORD_TEXT=" | 初始密码：$(cat "${DATA_DIR}/初始密码.txt")"
        fi

        if [ -n "$port" ] && [ "$CURRENT_IP" != "无法获取IP" ]; then
            NEW_DESC="description=【运行中】当前地址：http://${CURRENT_IP}:${port} | PID:$pid | 数据目录：${DATA_DIR} | 点击▲操作关闭程序${PASSWORD_TEXT}"
        else
            log "错误: IP 或端口获取失败 (IP: $CURRENT_IP, 端口: $port)"
            NEW_DESC="description=【运行中】无法检测 openlist 地址（IP: $CURRENT_IP, 端口: $port，PID:$pid），请检查日志 $LOG_FILE | 数据目录：${DATA_DIR} | 点击▲操作关闭程序${PASSWORD_TEXT}"
        fi
    fi

    if [ ! -f "$MODULE_PROP_FILE" ]; then
        log "错误: $MODULE_PROP_FILE 不存在"
        return 1
    fi
    if [ ! -w "$MODULE_PROP_FILE" ]; then
        log "警告: $MODULE_PROP_FILE 不可写，尝试修复权限"
        chmod 644 "$MODULE_PROP_FILE" 2>/dev/null || log "错误: 无法设置 $MODULE_PROP_FILE 的权限"
    fi

    grep -v '^description=' "$MODULE_PROP_FILE" > "${MODULE_PROP_FILE}.tmp" 2>/dev/null
    echo "$NEW_DESC" >> "${MODULE_PROP_FILE}.tmp"
    mv "${MODULE_PROP_FILE}.tmp" "$MODULE_PROP_FILE" 2>/dev/null
}

log "启动 service.sh 于 $(date '+%Y-%m-%d %H:%M:%S')"

if ! command -v ip >/dev/null; then
    log "错误: 未找到 ip 命令"
    exit 1
fi

if [ ! -f "$OPENLIST_BINARY" ]; then
    log "错误: $OPENLIST_BINARY 不存在"
    exit 1
fi
if [ ! -x "$OPENLIST_BINARY" ]; then
    log "警告: $OPENLIST_BINARY 不可执行，尝试修复"
    chmod 755 "$OPENLIST_BINARY" 2>/dev/null || {
        log "错误: 无法设置 $OPENLIST_BINARY 的执行权限"
        exit 1
    }
fi

mkdir -p "$DATA_DIR" 2>/dev/null
if [ $? -ne 0 ]; then
    log "错误: 无法创建数据目录 $DATA_DIR"
    exit 1
fi
if [ ! -w "$DATA_DIR" ]; then
    log "警告: 数据目录 $DATA_DIR 不可写，尝试修复权限"
    chmod 777 "$DATA_DIR" 2>/dev/null || {
        log "错误: 无法设置 $DATA_DIR 的写权限"
        exit 1
    }
fi
log "已创建或验证数据目录：$DATA_DIR"

export HOME="$DATA_DIR"
export TMPDIR="$DATA_DIR/tmp"
export USER="root"
mkdir -p "$TMPDIR"
chmod 777 "$TMPDIR"

cd "$DATA_DIR" || log "警告: 无法切换到数据目录"

ELAPSED=0
MAX_WAIT=60
while [ $ELAPSED -lt $MAX_WAIT ]; do
    if [ "$(getprop sys.boot_completed)" = "1" ]; then
        log "Android 系统启动完成"
        break
    fi
    log "等待 Android 系统启动... ($ELAPSED/$MAX_WAIT 秒)"
    sleep 1
    ELAPSED=$((ELAPSED + 1))
done

# ==========================================
# 息屏网络保活
# ==========================================
settings put global wifi_sleep_policy 2 2>/dev/null && \
    log "已设置 WiFi 永不休眠策略" || log "警告: WiFi 休眠策略设置失败"

echo "openlist_wake_lock" > /sys/power/wake_lock 2>/dev/null && \
    log "已申请内核唤醒锁" || log "警告: 无法申请唤醒锁"

dumpsys deviceidle whitelist +com.android.shell 2>/dev/null
log "已尝试配置 Doze 白名单"
# ==========================================

log "启动 OpenList: $OPENLIST_BINARY server --data $DATA_DIR"

"$OPENLIST_BINARY" server --data "$DATA_DIR" >/dev/null 2>&1 &
OPENLIST_PID=$!

if ps -p $OPENLIST_PID >/dev/null || pgrep -f "$OPENLIST_BINARY server --data" >/dev/null; then
    log "OpenList 服务启动成功 (PID: $OPENLIST_PID)"
    update_module_prop_running
else
    log "错误: 无法启动 OpenList 服务"
    exit 1
fi

# ==========================================
# 守护循环：续期唤醒锁 + 进程保活
# ==========================================
(
    while true; do
        sleep 55
        # 续期唤醒锁
        echo "openlist_wake_lock" > /sys/power/wake_lock 2>/dev/null
        # 检测进程，挂了就重启
        if ! pgrep -f "$OPENLIST_BINARY server --data" > /dev/null 2>&1; then
            log "守护: OpenList 进程意外退出，正在重启..."
            "$OPENLIST_BINARY" server --data "$DATA_DIR" > /dev/null 2>&1 &
            log "守护: OpenList 已重启 (PID: $!)"
            update_module_prop_running
        fi
    done
) &
WATCHDOG_PID=$!
echo "$WATCHDOG_PID" > "$WATCHDOG_PID_FILE"
log "守护进程已启动 (Watchdog PID: $WATCHDOG_PID)"
# ==========================================
