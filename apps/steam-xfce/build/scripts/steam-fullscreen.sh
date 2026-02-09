#!/bin/bash

# Steam和游戏窗口监控脚本
# 支持全屏和最大化两种模式
# 通过 FULLSCREEN 环境变量控制：
#   FULLSCREEN=TRUE  - 全屏模式（默认）
#   FULLSCREEN=FALSE - 最大化窗口模式
# 
# 功能：
# - 监控Steam窗口并应用窗口设置
# - 自动检测游戏窗口并强制全屏
# - 支持多种游戏平台和引擎
source /opt/gow/bash-lib/utils.sh

# 全局变量
SCREEN_WIDTH=""
SCREEN_HEIGHT=""

# 配置变量 - 设置为 TRUE 启用全屏，FALSE 使用最大化窗口
FULLSCREEN=${FULLSCREEN:-"FALSE"}

# 游戏窗口检测配置
GAME_WINDOW_PATTERNS=(
    "steam_app_"
    "Red Dead Redemption" 
    "Launcher"
    "Unity"
    "Unreal"
    "Godot"
    "Minecraft"
    "Wine"
    "Proton"
    "Lutris"
    "Heroic"
    "Epic"
    "Origin"
    "Battle.net"
    "Uplay"
    "GOG"
    "itch.io"
)

# 函数：查找Steam窗口
find_steam_window() {
    local steam_window_id=$(wmctrl -l | grep -i ' steam ' | head -1 | awk '{print $1}')
    
    if [ -n "$steam_window_id" ]; then
        # gow_log "[steam-fullscreen] Found Steam window: $steam_window_id" >&2
        echo "$steam_window_id"
        return 0
    fi
    
    # 备用方法
    # steam_window_id=$(xwininfo -name "Steam" 2>/dev/null | grep "Window id:" | awk '{print $4}')
    # if [ -n "$steam_window_id" ]; then
    #     gow_log "[steam-fullscreen] Found Steam window: $steam_window_id" >&2
    #     echo "$steam_window_id"
    #     return 0
    # fi
    
    # steam_window_id=$(xwininfo -name "steam" 2>/dev/null | grep "Window id:" | awk '{print $4}')
    # if [ -n "$steam_window_id" ]; then
    #     gow_log "[steam-fullscreen] Found Steam window: $steam_window_id" >&2
    #     echo "$steam_window_id"
    #     return 0
    # fi
    
    # steam_window_id=$(xwininfo -name "Big Picture" 2>/dev/null | grep "Window id:" | awk '{print $4}')
    # if [ -n "$steam_window_id" ]; then
    #     gow_log "[steam-fullscreen] Found Steam window: $steam_window_id" >&2
    #     echo "$steam_window_id"
    #     return 0
    # fi
    
    return 1
}

# 函数：查找游戏窗口
find_game_window() {
    # 遍历游戏窗口模式
    for pattern in "${GAME_WINDOW_PATTERNS[@]}"; do
        # 使用 wmctrl 查找匹配的窗口
        window_id=$(wmctrl -l | grep -i "$pattern" | head -1 | awk '{print $1}')
        if [ -n "$window_id" ]; then
            # gow_log "[game-fullscreen] Found game window: $pattern (ID: $window_id)" >&2
            echo "$window_id"
            return 0
        fi
    done
    
    return 1
}

# 函数：获取屏幕尺寸
get_screen_size() {
    SCREEN_SIZE=$(xrandr | grep '*' | head -1 | awk '{print $1}' | cut -d'x' -f1,2)
    SCREEN_WIDTH=$(echo $SCREEN_SIZE | cut -d'x' -f1)
    SCREEN_HEIGHT=$(echo $SCREEN_SIZE | cut -d'x' -f2)
}

# 函数：打印窗口详细信息
print_window_info() {
    local window_id="$1"
    local action="$2"
    
    # 获取窗口信息
    local window_info=$(wmctrl -l | grep "$window_id")
    local window_title=$(echo "$window_info" | cut -d' ' -f4-)
    local window_class=$(xprop -id "$window_id" WM_CLASS 2>/dev/null | cut -d'"' -f4)
    local window_state=$(xprop -id "$window_id" _NET_WM_STATE 2>/dev/null)
    
    # 打印窗口信息
    gow_log "[steam-fullscreen] $action:"
    gow_log "[steam-fullscreen]   Window ID: $window_id"
    gow_log "[steam-fullscreen]   Window Title: $window_title"
    gow_log "[steam-fullscreen]   Window Class: $window_class"
    gow_log "[steam-fullscreen]   Current State: $window_state"
}

# 函数：检查wmctrl全屏状态
check_wmctrl_fullscreen() {
    local window_id="$1"
    if wmctrl -l -G | grep "$window_id" | grep -q "fullscreen\|maximized"; then
        return 0  # 已全屏
    else
        return 1  # 未全屏
    fi
}

# 函数：检查xprop全屏状态
check_xprop_fullscreen() {
    local window_id="$1"
    local window_state=$(xprop -id "$window_id" _NET_WM_STATE 2>/dev/null)
    if echo "$window_state" | grep -q "_NET_WM_STATE_FULLSCREEN"; then
        return 0  # 已全屏
    else
        return 1  # 未全屏
    fi
}

# 函数：检查窗口尺寸是否全屏
check_window_size_fullscreen() {
    local window_id="$1"
    get_screen_size
    local window_info=$(xwininfo -id "$window_id" 2>/dev/null)
    local window_width=$(echo "$window_info" | grep "Width:" | awk '{print $2}')
    local window_height=$(echo "$window_info" | grep "Height:" | awk '{print $2}')
    
    if [ "$window_width" = "$SCREEN_WIDTH" ] && [ "$window_height" = "$SCREEN_HEIGHT" ]; then
        return 0  # 已全屏
    else
        return 1  # 未全屏
    fi
}

# 函数：检查窗口是否已全屏
is_window_fullscreen() {
    local window_id="$1"
    
    # 方法1: 检查wmctrl全屏状态
    if check_wmctrl_fullscreen "$window_id"; then
        return 0
    fi
    
    # 方法2: 检查xprop全屏状态
    if check_xprop_fullscreen "$window_id"; then
        return 0
    fi
    
    # 方法3: 检查窗口大小是否等于屏幕大小
    if check_window_size_fullscreen "$window_id"; then
        return 0
    fi
    
    return 1  # 未全屏
}

# 函数：检查wmctrl最大化状态
check_wmctrl_maximized() {
    local window_id="$1"
    if wmctrl -l -G | grep "$window_id" | grep -q "maximized"; then
        return 0  # 已最大化
    else
        return 1  # 未最大化
    fi
}

# 函数：检查xprop最大化状态
check_xprop_maximized() {
    local window_id="$1"
    local window_state=$(xprop -id "$window_id" _NET_WM_STATE 2>/dev/null)
    if echo "$window_state" | grep -q "_NET_WM_STATE_MAXIMIZED_VERT\|_NET_WM_STATE_MAXIMIZED_HORZ"; then
        return 0  # 已最大化
    else
        return 1  # 未最大化
    fi
}

# 函数：检查窗口是否已最大化
is_window_maximized() {
    local window_id="$1"
    
    # 方法1: 检查wmctrl最大化状态
    if check_wmctrl_maximized "$window_id"; then
        return 0
    fi
    
    # 方法2: 检查xprop最大化状态
    if check_xprop_maximized "$window_id"; then
        return 0
    fi
    
    return 1  # 未最大化
}

# 函数：使用wmctrl设置全屏
set_fullscreen_wmctrl() {
    local window_id="$1"
    
    # 打印窗口信息
    print_window_info "$window_id" "Setting window to fullscreen using wmctrl"
    
    if wmctrl -i -r "$window_id" -b add,fullscreen 2>/dev/null; then
        gow_log "[steam-fullscreen] Successfully set fullscreen using wmctrl"
        return 0
    else
        # 尝试最大化
        if wmctrl -i -r "$window_id" -b add,maximized_vert,maximized_horz 2>/dev/null; then
            gow_log "[steam-fullscreen] Successfully maximized using wmctrl"
            return 0
        fi
    fi
    return 1
}

# 函数：使用xdotool设置全屏
set_fullscreen_xdotool() {
    local window_id="$1"
    
    # 打印窗口信息
    print_window_info "$window_id" "Setting window to fullscreen using xdotool"
    
    if xdotool windowstate "$window_id" add FULLSCREEN 2>/dev/null; then
        gow_log "[steam-fullscreen] Successfully set fullscreen using xdotool"
        return 0
    else
        # 尝试调整窗口大小
        get_screen_size
        if xdotool windowmove "$window_id" 0 0 2>/dev/null && \
           xdotool windowsize "$window_id" "$SCREEN_WIDTH" "$SCREEN_HEIGHT" 2>/dev/null; then
            gow_log "[steam-fullscreen] Successfully resized to fullscreen using xdotool"
            return 0
        fi
    fi
    return 1
}

# 函数：使用xprop设置全屏
set_fullscreen_xprop() {
    local window_id="$1"
    
    # 打印窗口信息
    print_window_info "$window_id" "Setting window to fullscreen using xprop"
    
    if xprop -id "$window_id" -f _NET_WM_STATE 32a -set _NET_WM_STATE "_NET_WM_STATE_FULLSCREEN" 2>/dev/null; then
        gow_log "[steam-fullscreen] Successfully set fullscreen using xprop"
        return 0
    fi
    return 1
}

# 函数：设置最大化窗口
set_maximized_window() {
    local window_id="$1"
    
    # 打印窗口信息
    print_window_info "$window_id" "Setting window to maximized mode"
    
    # 使用wmctrl设置最大化
    if wmctrl -i -r "$window_id" -b add,maximized_vert,maximized_horz 2>/dev/null; then
        gow_log "[steam-fullscreen] Successfully maximized window using wmctrl"
        return 0
    fi
    
    # 备用方法：使用xdotool
    if xdotool windowstate "$window_id" add MAXIMIZED_VERT MAXIMIZED_HORZ 2>/dev/null; then
        gow_log "[steam-fullscreen] Successfully maximized window using xdotool"
        return 0
    fi
    
    # 备用方法：使用xprop
    if xprop -id "$window_id" -f _NET_WM_STATE 32a -set _NET_WM_STATE "_NET_WM_STATE_MAXIMIZED_VERT,_NET_WM_STATE_MAXIMIZED_HORZ" 2>/dev/null; then
        gow_log "[steam-fullscreen] Successfully maximized window using xprop"
        return 0
    fi
    
    gow_log "[steam-fullscreen] Warning: Could not maximize window"
    return 1
}

# 函数：应用窗口设置（全屏或最大化）
apply_window_setting() {
    local window_id="$1"
    gow_log "[steam-fullscreen] Found Steam window: $window_id, applying window setting..."
    gow_log "[steam-fullscreen] FULLSCREEN mode: $FULLSCREEN"
    
    # 等待窗口完全加载
    sleep 1
    
    if [ "$FULLSCREEN" = "TRUE" ]; then
        # 全屏模式：按优先级尝试不同的全屏方法
        if set_fullscreen_wmctrl "$window_id"; then
            return 0
        elif set_fullscreen_xdotool "$window_id"; then
            return 0
        elif set_fullscreen_xprop "$window_id"; then
            return 0
        else
            gow_log "[steam-fullscreen] Warning: Could not set fullscreen, falling back to maximized mode"
            set_maximized_window "$window_id"
            return $?
        fi
    else
        # 最大化模式
        set_maximized_window "$window_id"
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

# 函数：检查游戏窗口是否已全屏
is_game_window_fullscreen() {
    local window_id="$1"
    
    # 方法1: 检查wmctrl全屏状态
    if wmctrl -l -G | grep "$window_id" | grep -q "fullscreen\|maximized"; then
        return 0  # 已全屏
    fi
    
    # 方法2: 检查xprop全屏状态
    local window_state=$(xprop -id "$window_id" _NET_WM_STATE 2>/dev/null)
    if echo "$window_state" | grep -q "_NET_WM_STATE_FULLSCREEN"; then
        return 0  # 已全屏
    fi
    
    # 方法3: 检查窗口大小是否等于屏幕大小
    get_screen_size
    local window_info=$(xwininfo -id "$window_id" 2>/dev/null)
    local window_width=$(echo "$window_info" | grep "Width:" | awk '{print $2}')
    local window_height=$(echo "$window_info" | grep "Height:" | awk '{print $2}')
    
    if [ "$window_width" = "$SCREEN_WIDTH" ] && [ "$window_height" = "$SCREEN_HEIGHT" ]; then
        return 0  # 已全屏
    fi
    
    return 1  # 未全屏
}

# 函数：设置游戏窗口全屏
set_game_window_fullscreen() {
    local window_id="$1"
    
    # 打印窗口信息
    print_window_info "$window_id" "Setting game window to fullscreen"
    
    # 使用wmctrl设置全屏
    if wmctrl -i -r "$window_id" -b add,fullscreen 2>/dev/null; then
        gow_log "[game-fullscreen] Successfully set game window fullscreen using wmctrl"
        return 0
    fi
    
    # 使用xdotool设置全屏
    if xdotool windowstate "$window_id" add FULLSCREEN 2>/dev/null; then
        gow_log "[game-fullscreen] Successfully set game window fullscreen using xdotool"
        return 0
    fi
    
    # 使用xprop设置全屏
    if xprop -id "$window_id" -f _NET_WM_STATE 32a -set _NET_WM_STATE "_NET_WM_STATE_FULLSCREEN" 2>/dev/null; then
        gow_log "[game-fullscreen] Successfully set game window fullscreen using xprop"
        return 0
    fi
    
    gow_log "[game-fullscreen] Warning: All fullscreen methods failed"
    return 1
}

# 函数：处理游戏窗口全屏
handle_game_window() {
    local game_window_id="$1"
    
    if [ -n "$game_window_id" ]; then
        # 检查游戏窗口是否已全屏
        if is_game_window_fullscreen "$game_window_id"; then
            # gow_log "[game-fullscreen] Game window is already fullscreen, skipping..."
            return 0
        fi
        
        # 强制设置游戏窗口为全屏
        gow_log "[game-fullscreen] Setting game window to fullscreen..."
        
        # 等待窗口完全加载
        sleep 2
        
        # 使用多种方法尝试设置全屏
        if set_game_window_fullscreen "$game_window_id"; then
            gow_log "[game-fullscreen] Successfully set game window fullscreen"
        else
            gow_log "[game-fullscreen] Warning: Could not set game window fullscreen"
        fi
    fi
}

# 函数：处理Steam窗口
handle_steam_window() {
    local steam_window_id="$1"
    
    if [ "$FULLSCREEN" = "TRUE" ]; then
        # 全屏模式：检查是否已全屏
        if is_window_fullscreen "$steam_window_id"; then
            # gow_log "[steam-fullscreen] Steam window is already fullscreen, skipping..."
            # 窗口已全屏，执行空命令（什么都不做）
            :
        else
            apply_window_setting "$steam_window_id"
        fi
    else
        # 最大化模式：检查是否已最大化
        if is_window_maximized "$steam_window_id"; then
            # gow_log "[steam-fullscreen] Steam window is already maximized, skipping..."
            # 窗口已最大化，执行空命令（什么都不做）
            :
        else
            apply_window_setting "$steam_window_id"
        fi
    fi
}

# 主监控循环
main_monitor_loop() {
    gow_log "[steam-fullscreen] Starting Steam and game window fullscreen monitor..."
    
    while true; do
        # 查找Steam窗口
        steam_window_id=$(find_steam_window)
        
        if [ -n "$steam_window_id" ]; then
            handle_steam_window "$steam_window_id"
        fi
        
        # 查找游戏窗口
        game_window_id=$(find_game_window)
        
        if [ -n "$game_window_id" ]; then
            handle_game_window "$game_window_id"
        fi
        
        # 检查Steam进程是否还在运行
        if ! is_steam_running; then
            # Steam进程已退出，执行空命令（什么都不做）
            :
        fi
        
        # 等待一段时间再检查
        sleep 3
    done
    
    gow_log "[steam-fullscreen] Steam and game window fullscreen monitor exited"
}

# 启动主监控循环
main_monitor_loop
