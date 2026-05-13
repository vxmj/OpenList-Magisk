#!/system/bin/sh
# shellcheck shell=ash
# action.sh for OpenList Magisk Module

MODDIR="${0%/*}"
MODULE_PROP="$MODDIR/module.prop"
SERVICE_SH="$MODDIR/service.sh"
OPENLIST_BINARY="__PLACEHOLDER_BINARY_PATH__"
WATCHDOG_PID_FILE="$MODDIR/watchdog.pid"
REPO_URL="https://github.com/Alien-Et/OpenList-Magisk"

# 查找可用的 busybox 路径，兼容 Magisk / KSU / APatch
find_busybox() {
    local busybox_paths="/data/adb/magisk/busybox /data/adb/ksu/bin/busybox /data/adb/ap/bin/busybox /data/adb/bin/busybox /system/xbin/busybox /system/bin/busybox"

    for path in $busybox_paths; do
        if [ -x "$path" ]; then
            echo "$path"
            return 0
        fi
    done

    local which_busybox
    which_busybox=$(which busybox 2>/dev/null)
    if [ -x "$which_busybox" ]; then
        echo "$which_busybox"
        return 0
    fi

    echo "错误:找不到BusyBox！" >&2
    exit 1
}

# 初始化 BusyBox 绝对路径
BUSYBOX=$(find_busybox)

# 核心函数：检查 OpenList 服务状态
check_openlist_status() {
    if "$BUSYBOX" pgrep -f "$OPENLIST_BINARY server" 2>/dev/null; then
        return 0  # 运行中，同时打印 PID
    else
        return 1  # 未运行
    fi
}

# 更新模块状态为"已停止"
update_module_prop_stopped() {
    "$BUSYBOX" sed -i "s|^description=.*|description=【已停止】请点击\"操作\"启动程序。项目地址：${REPO_URL}|" "$MODULE_PROP"
}

# ──────────────────────────────────────────────
# 停止守护进程并释放内核唤醒锁
# ──────────────────────────────────────────────
stop_watchdog_and_release_lock() {
    # 1. 杀守护进程，防止它在 55 秒后把 OpenList 复活
    if [ -f "$WATCHDOG_PID_FILE" ]; then
        WATCHDOG_PID=$(cat "$WATCHDOG_PID_FILE")
        if [ -n "$WATCHDOG_PID" ]; then
            kill "$WATCHDOG_PID" 2>/dev/null && \
                echo "✅ 守护进程已终止 (PID: $WATCHDOG_PID)" || \
                echo "⚠️ 守护进程已不存在 (PID: $WATCHDOG_PID)"
        fi
        rm -f "$WATCHDOG_PID_FILE"
    else
        echo "⚠️ 未找到守护进程 PID 文件，跳过"
    fi

    # 2. 释放内核唤醒锁，避免息屏后持续耗电
    echo "openlist_wake_lock" > /sys/power/wake_unlock 2>/dev/null && \
        echo "✅ 唤醒锁已释放" || \
        echo "⚠️ 唤醒锁释放失败（可能已自动过期）"
}

# ──────────────────────────────────────────────
# 主逻辑：启停服务
# ──────────────────────────────────────────────
if check_openlist_status; then
    # ── 服务已运行：执行完整停止流程 ──
    echo "正在停止 OpenList 服务..."

    "$BUSYBOX" pkill -f "$OPENLIST_BINARY"
    sleep 1

    # 停止守护进程 + 释放唤醒锁
    stop_watchdog_and_release_lock

    if check_openlist_status; then
        echo "❌ 停止失败"
        exit 1
    else
        echo "✅ 停止成功"
        update_module_prop_stopped
    fi

else
    # ── 服务未运行：执行启动流程 ──
    echo "正在启动 OpenList 服务..."

    if [ -f "$SERVICE_SH" ]; then
        sh "$SERVICE_SH"
        sleep 2
        if check_openlist_status; then
            echo "✅ 启动成功"
            "$BUSYBOX" sed -i "s|^description=.*|description=【已启动】OpenList 服务运行中，点击\"操作\"可停止。项目地址：${REPO_URL}|" "$MODULE_PROP"
        else
            echo "❌ 启动失败"
            exit 1
        fi
    else
        echo "❌ service.sh 不存在"
        exit 1
    fi
fi
