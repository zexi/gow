#!/bin/bash

# Steam窗口监控脚本
# 支持全屏和最大化两种模式
# 通过 FULLSCREEN 环境变量控制：
#   FULLSCREEN=TRUE  - 全屏模式（默认）
#   FULLSCREEN=FALSE - 最大化窗口模式
source /opt/gow/bash-lib/utils.sh

# 全局变量
STEAM_WINDOW_ID=""
SCREEN_WIDTH=""
SCREEN_HEIGHT=""

# 配置变量 - 设置为 TRUE 启用全屏，FALSE 使用最大化窗口
FULLSCREEN=${FULLSCREEN:-"FALSE"}

# 函数：查找Steam窗口
find_steam_window() {
    STEAM_WINDOW_ID=$(wmctrl -l | grep -i steam | head -1 | awk '{print $1}')
    # 备用方法（已注释）
    # if [ -z "$STEAM_WINDOW_ID" ]; then
    #     STEAM_WINDOW_ID=$(xwininfo -name "Steam" 2>/dev/null | grep "Window id:" | awk '{print $4}')
    # fi
    # if [ -z "$STEAM_WINDOW_ID" ]; then
    #     STEAM_WINDOW_ID=$(xwininfo -name "steam" 2>/dev/null | grep "Window id:" | awk '{print $4}')
    # fi
    # if [ -z "$STEAM_WINDOW_ID" ]; then
    #     STEAM_WINDOW_ID=$(xwininfo -name "Big Picture" 2>/dev/null | grep "Window id:" | awk '{print $4}')
    # fi
}

# 函数：获取屏幕尺寸
get_screen_size() {
    SCREEN_SIZE=$(xrandr | grep '*' | head -1 | awk '{print $1}' | cut -d'x' -f1,2)
    SCREEN_WIDTH=$(echo $SCREEN_SIZE | cut -d'x' -f1)
    SCREEN_HEIGHT=$(echo $SCREEN_SIZE | cut -d'x' -f2)
}

# 函数：检查wmctrl全屏状态
check_wmctrl_fullscreen() {
    if wmctrl -l -G | grep "$STEAM_WINDOW_ID" | grep -q "fullscreen\|maximized"; then
        return 0  # 已全屏
    else
        return 1  # 未全屏
    fi
}

# 函数：检查xprop全屏状态
check_xprop_fullscreen() {
    WINDOW_STATE=$(xprop -id "$STEAM_WINDOW_ID" _NET_WM_STATE 2>/dev/null)
    if echo "$WINDOW_STATE" | grep -q "_NET_WM_STATE_FULLSCREEN"; then
        return 0  # 已全屏
    else
        return 1  # 未全屏
    fi
}

# 函数：检查窗口尺寸是否全屏
check_window_size_fullscreen() {
    get_screen_size
    WINDOW_INFO=$(xwininfo -id "$STEAM_WINDOW_ID" 2>/dev/null)
    WINDOW_WIDTH=$(echo "$WINDOW_INFO" | grep "Width:" | awk '{print $2}')
    WINDOW_HEIGHT=$(echo "$WINDOW_INFO" | grep "Height:" | awk '{print $2}')
    
    if [ "$WINDOW_WIDTH" = "$SCREEN_WIDTH" ] && [ "$WINDOW_HEIGHT" = "$SCREEN_HEIGHT" ]; then
        return 0  # 已全屏
    else
        return 1  # 未全屏
    fi
}

# 函数：检查窗口是否已全屏
is_window_fullscreen() {
    # 方法1: 检查wmctrl全屏状态
    if check_wmctrl_fullscreen; then
        return 0
    fi
    
    # 方法2: 检查xprop全屏状态
    if check_xprop_fullscreen; then
        return 0
    fi
    
    # 方法3: 检查窗口大小是否等于屏幕大小
    if check_window_size_fullscreen; then
        return 0
    fi
    
    return 1  # 未全屏
}

# 函数：检查wmctrl最大化状态
check_wmctrl_maximized() {
    if wmctrl -l -G | grep "$STEAM_WINDOW_ID" | grep -q "maximized"; then
        return 0  # 已最大化
    else
        return 1  # 未最大化
    fi
}

# 函数：检查xprop最大化状态
check_xprop_maximized() {
    WINDOW_STATE=$(xprop -id "$STEAM_WINDOW_ID" _NET_WM_STATE 2>/dev/null)
    if echo "$WINDOW_STATE" | grep -q "_NET_WM_STATE_MAXIMIZED_VERT\|_NET_WM_STATE_MAXIMIZED_HORZ"; then
        return 0  # 已最大化
    else
        return 1  # 未最大化
    fi
}

# 函数：检查窗口是否已最大化
is_window_maximized() {
    # 方法1: 检查wmctrl最大化状态
    if check_wmctrl_maximized; then
        return 0
    fi
    
    # 方法2: 检查xprop最大化状态
    if check_xprop_maximized; then
        return 0
    fi
    
    return 1  # 未最大化
}

# 函数：使用wmctrl设置全屏
set_fullscreen_wmctrl() {
    if wmctrl -i -r "$STEAM_WINDOW_ID" -b add,fullscreen 2>/dev/null; then
        gow_log "[steam-fullscreen] Successfully set fullscreen using wmctrl"
        return 0
    else
        # 尝试最大化
        if wmctrl -i -r "$STEAM_WINDOW_ID" -b add,maximized_vert,maximized_horz 2>/dev/null; then
            gow_log "[steam-fullscreen] Successfully maximized using wmctrl"
            return 0
        fi
    fi
    return 1
}

# 函数：使用xdotool设置全屏
set_fullscreen_xdotool() {
    if xdotool windowstate "$STEAM_WINDOW_ID" add FULLSCREEN 2>/dev/null; then
        gow_log "[steam-fullscreen] Successfully set fullscreen using xdotool"
        return 0
    else
        # 尝试调整窗口大小
        get_screen_size
        if xdotool windowmove "$STEAM_WINDOW_ID" 0 0 2>/dev/null && \
           xdotool windowsize "$STEAM_WINDOW_ID" "$SCREEN_WIDTH" "$SCREEN_HEIGHT" 2>/dev/null; then
            gow_log "[steam-fullscreen] Successfully resized to fullscreen using xdotool"
            return 0
        fi
    fi
    return 1
}

# 函数：使用xprop设置全屏
set_fullscreen_xprop() {
    if xprop -id "$STEAM_WINDOW_ID" -f _NET_WM_STATE 32a -set _NET_WM_STATE "_NET_WM_STATE_FULLSCREEN" 2>/dev/null; then
        gow_log "[steam-fullscreen] Successfully set fullscreen using xprop"
        return 0
    fi
    return 1
}

# 函数：设置最大化窗口
set_maximized_window() {
    gow_log "[steam-fullscreen] Setting window to maximized mode..."
    
    # 使用wmctrl设置最大化
    if wmctrl -i -r "$STEAM_WINDOW_ID" -b add,maximized_vert,maximized_horz 2>/dev/null; then
        gow_log "[steam-fullscreen] Successfully maximized window using wmctrl"
        return 0
    fi
    
    # 备用方法：使用xdotool
    if xdotool windowstate "$STEAM_WINDOW_ID" add MAXIMIZED_VERT MAXIMIZED_HORZ 2>/dev/null; then
        gow_log "[steam-fullscreen] Successfully maximized window using xdotool"
        return 0
    fi
    
    # 备用方法：使用xprop
    if xprop -id "$STEAM_WINDOW_ID" -f _NET_WM_STATE 32a -set _NET_WM_STATE "_NET_WM_STATE_MAXIMIZED_VERT,_NET_WM_STATE_MAXIMIZED_HORZ" 2>/dev/null; then
        gow_log "[steam-fullscreen] Successfully maximized window using xprop"
        return 0
    fi
    
    gow_log "[steam-fullscreen] Warning: Could not maximize window"
    return 1
}

# 函数：应用窗口设置（全屏或最大化）
apply_window_setting() {
    gow_log "[steam-fullscreen] Found Steam window: $STEAM_WINDOW_ID, applying window setting..."
    gow_log "[steam-fullscreen] FULLSCREEN mode: $FULLSCREEN"
    
    # 等待窗口完全加载
    sleep 1
    
    if [ "$FULLSCREEN" = "TRUE" ]; then
        # 全屏模式：按优先级尝试不同的全屏方法
        if set_fullscreen_wmctrl; then
            return 0
        elif set_fullscreen_xdotool; then
            return 0
        elif set_fullscreen_xprop; then
            return 0
        else
            gow_log "[steam-fullscreen] Warning: Could not set fullscreen, falling back to maximized mode"
            set_maximized_window
            return $?
        fi
    else
        # 最大化模式
        set_maximized_window
        return $?
    fi
}

# 函数：检查Steam进程是否运行
is_steam_running() {
    if pgrep -f "steam.*bigpicture" >/dev/null; then
        return 0  # 正在运行
    else
        return 1  # 未运行
    fi
}

# 函数：处理Steam窗口
handle_steam_window() {
    if [ "$FULLSCREEN" = "TRUE" ]; then
        # 全屏模式：检查是否已全屏
        if is_window_fullscreen; then
            # gow_log "[steam-fullscreen] Steam window is already fullscreen, skipping..."
            # 窗口已全屏，执行空命令（什么都不做）
            :
        else
            apply_window_setting
        fi
    else
        # 最大化模式：检查是否已最大化
        if is_window_maximized; then
            # gow_log "[steam-fullscreen] Steam window is already maximized, skipping..."
            # 窗口已最大化，执行空命令（什么都不做）
            :
        else
            apply_window_setting
        fi
    fi
}

# 主监控循环
main_monitor_loop() {
    gow_log "[steam-fullscreen] Starting Steam fullscreen monitor..."
    
    while true; do
        # 查找Steam窗口
        find_steam_window
        
        if [ -n "$STEAM_WINDOW_ID" ]; then
            handle_steam_window
        fi
        
        # 检查Steam进程是否还在运行
        if ! is_steam_running; then
            # Steam进程已退出，执行空命令（什么都不做）
            :
        fi
        
        # 等待一段时间再检查
        sleep 3
    done
    
    gow_log "[steam-fullscreen] Steam fullscreen monitor exited"
}

# 启动主监控循环
main_monitor_loop
