# shellcheck shell=ash
# uninstall.sh for OpenList Magisk/KSU/APatch Module
# 自动清理所有数据，静默卸载

#==== 侦探：Magisk or KernelSU or APatch ====
if [ -n "$MAGISK_VER" ]; then
    MODROOT="$MODPATH"
elif [ -n "$KSU" ] || [ -n "$KERNELSU" ]; then
    MODROOT="$MODULEROOT"
elif [ -n "$APATCH" ]; then
    MODROOT="$MODULEROOT"
else
    MODROOT="$MODPATH"
fi
#==== 侦探结束 ====

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 停止守护进程 + OpenList 服务
stop_service() {
    # 先杀守护进程，防止它在 55 秒后把 OpenList 复活
    WATCHDOG_PID_FILE="$MODROOT/watchdog.pid"
    if [ -f "$WATCHDOG_PID_FILE" ]; then
        WATCHDOG_PID=$(cat "$WATCHDOG_PID_FILE")
        if [ -n "$WATCHDOG_PID" ]; then
            kill "$WATCHDOG_PID" 2>/dev/null && \
                log "守护进程已终止 (PID: $WATCHDOG_PID)" || \
                log "守护进程已不存在 (PID: $WATCHDOG_PID)"
        fi
        rm -f "$WATCHDOG_PID_FILE"
    fi

    # 再杀 OpenList 主进程
    if pgrep -f openlist > /dev/null 2>&1; then
        log "正在停止 OpenList 服务..."
        pkill -f openlist
        sleep 1
        if pgrep -f openlist > /dev/null 2>&1; then
            log "警告: 无法完全停止 OpenList 服务"
            return 1
        fi
        log "OpenList 服务已停止"
    else
        log "OpenList 服务未运行"
    fi

    # 释放唤醒锁
    echo "openlist_wake_lock" > /sys/power/wake_unlock 2>/dev/null && \
        log "唤醒锁已释放" || log "唤醒锁释放失败（可能已自动过期）"

    return 0
}

# 清理二进制文件
clean_binaries() {
    local found=0
    for path in \
        /data/adb/openlist/bin/openlist \
        "$MODROOT/bin/openlist" \
        "$MODROOT/system/bin/openlist"; do
        if [ -f "$path" ]; then
            log "正在删除二进制文件：$path"
            rm -f "$path"
            found=1
        fi
    done
    [ $found -eq 0 ] && log "未找到 OpenList 二进制文件"
}

# 自动清理所有数据目录
clean_data() {
    log "开始自动清理数据目录..."
    local found=0
    for dir in "/data/adb/openlist" "/sdcard/Android/openlist"; do
        if [ -d "$dir" ]; then
            log "正在删除数据目录：$dir"
            rm -rf "$dir"
            found=1
        fi
    done
    [ $found -eq 1 ] && log "数据目录清理完成" || log "未找到 OpenList 数据目录"
}

main() {
    log "开始卸载 OpenList Magisk 模块..."
    stop_service
    clean_binaries
    clean_data
    log "卸载完成"
    echo "请重启设备以完成卸载"
}

main
