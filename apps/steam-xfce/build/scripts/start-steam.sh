#!/bin/bash

# Steam Big Picture 启动脚本
source /opt/gow/bash-lib/utils.sh

# 等待XFCE完全启动
sleep 2

# 启动Steam Big Picture模式
gow_log "[steam] Starting Steam Big Picture..."
/usr/games/steam -bigpicture >/tmp/steam.log 2>&1 &

# Big Picture模式通常会自动全屏，但我们可以确保它最大化
sleep 5

# 查找Steam Big Picture窗口并确保全屏
STEAM_WINDOW_ID=""
for i in {1..100}; do
    # 查找Steam窗口
    # STEAM_WINDOW_ID=$(xwininfo -name "Steam" 2>/dev/null | grep "Window id:" | awk '{print $4}')
    # if [ -z "$STEAM_WINDOW_ID" ]; then
    #     STEAM_WINDOW_ID=$(xwininfo -name "steam" 2>/dev/null | grep "Window id:" | awk '{print $4}')
    # fi
    if [ -z "$STEAM_WINDOW_ID" ]; then
        STEAM_WINDOW_ID=$(wmctrl -l | grep -i steam | head -1 | awk '{print $1}')
    fi
    
    if [ -n "$STEAM_WINDOW_ID" ]; then
        gow_log "[steam] Found Steam window: $STEAM_WINDOW_ID"
        break
    fi
    sleep 1
done

if [ -n "$STEAM_WINDOW_ID" ]; then
    # 确保Steam窗口全屏
    gow_log "[steam] Ensuring Steam is fullscreen..."
    
    # 尝试全屏化
    wmctrl -i -r "$STEAM_WINDOW_ID" -b add,fullscreen 2>/dev/null && \
        gow_log "[steam] Set to fullscreen using wmctrl" || \
    wmctrl -i -r "$STEAM_WINDOW_ID" -b add,maximized_vert,maximized_horz 2>/dev/null && \
        gow_log "[steam] Maximized using wmctrl" || \
    xdotool windowstate "$STEAM_WINDOW_ID" add FULLSCREEN 2>/dev/null && \
        gow_log "[steam] Set to fullscreen using xdotool" || \
    gow_log "[steam] Big Picture mode should handle fullscreen automatically"
else
    gow_log "[steam] Warning: Could not find Steam window"
fi
