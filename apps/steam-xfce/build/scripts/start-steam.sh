#!/bin/bash

xhost +local:root

# Steam Big Picture 启动脚本
source /opt/gow/bash-lib/utils.sh

# 等待XFCE完全启动
# sleep 2

# 启动Steam Big Picture模式
#
# Recursively creating Steam necessary folders (https://github.com/ValveSoftware/steam-for-linux/issues/6492)
mkdir -p "$HOME/.steam/ubuntu12_32/steam-runtime"

# Use the new big picture mode by default
STEAM_STARTUP_FLAGS=${STEAM_STARTUP_FLAGS:-"-bigpicture"}

# Some game fixes taken from the Steam Deck
export SDL_VIDEO_MINIMIZE_ON_FOCUS_LOSS=0

# Enable Mangoapp
# Note: Ubuntus Mangoapp doesn't support Presets, so disable this for now
#export STEAM_MANGOAPP_PRESETS_SUPPORTED=1
export STEAM_USE_MANGOAPP=1
export MANGOHUD_CONFIGFILE=$(mktemp /tmp/mangohud.XXXXXXXX)
# Enable horizontal mangoapp bar
export STEAM_MANGOAPP_HORIZONTAL_SUPPORTED=1

# Enable Variable Rate Shading
# Note: this only works on gallium drivers and with new enough mesa
#       unfortunately there is no good way to check and disable this flag otherwise
export STEAM_USE_DYNAMIC_VRS=1
export RADV_FORCE_VRS_CONFIG_FILE=$(mktemp /tmp/radv_vrs.XXXXXXXX)
# To expose vram info from radv
export WINEDLLOVERRIDES=dxgi=n

# Initially write no_display to our config file
# so we don't get mangoapp showing up before Steam initializes
# on OOBE and stuff.
mkdir -p "$(dirname "$MANGOHUD_CONFIGFILE")"
echo "position=top-right" > "$MANGOHUD_CONFIGFILE"
echo "no_display" > "$MANGOHUD_CONFIGFILE"

# Prepare our initial VRS config file
# for dynamic VRS in Mesa.
mkdir -p "$(dirname "$RADV_FORCE_VRS_CONFIG_FILE")"
# By default don't do half shading
echo "1x1" > "$RADV_FORCE_VRS_CONFIG_FILE"


# Scaling support
export STEAM_GAMESCOPE_FANCY_SCALING_SUPPORT=1

# Have SteamRT's xdg-open send http:// and https:// URLs to Steam
export SRT_URLOPEN_PREFER_STEAM=1

# Set input method modules for Qt/GTK that will show the Steam keyboard
export QT_IM_MODULE=steam
export GTK_IM_MODULE=Steam
export SDL_VIDEO_FULLSCREEN_HEAD=1
export STEAM_FORCE_DESKTOPUI_SCALING=1

gow_log "[steam] Starting Steam Big Picture..."

#/usr/games/steam ${STEAM_STARTUP_FLAGS} >/tmp/steam.log 2>&1 &
/usr/games/steam ${STEAM_STARTUP_FLAGS} &

# 等待Steam启动
sleep 5

# 启动Steam全屏化监控脚本（后台运行）
gow_log "[steam] Starting Steam fullscreen monitor..."
/opt/gow/steam-fullscreen.sh &
FULLSCREEN_PID=$!
gow_log "[steam] Steam fullscreen monitor started with PID: $FULLSCREEN_PID"

# 给 http://localhost:8080/hook/de-check 发送 POST 请求
gow_log "[hook] Sending POST request to hook/de-check"
curl -X POST http://localhost:8080/hook/de-check

# 监控Steam进程，如果退出则终止容器
gow_log "[steam] Monitoring Steam process..."
while true; do
    # 首先尝试从PID文件读取当前PID
    CURRENT_PID=""
    if [ -f "/home/retro/.steam/steam.pid" ]; then
        CURRENT_PID=$(cat /home/retro/.steam/steam.pid 2>/dev/null)
    fi
    
    # 如果PID文件不存在或进程不存在，检查是否有Steam进程在运行
    if [ -z "$CURRENT_PID" ] || ! kill -0 "$CURRENT_PID" 2>/dev/null; then
        # 尝试查找Steam进程
        CURRENT_PID=$(pgrep -f "steam.*bigpicture" | head -1)
        if [ -z "$CURRENT_PID" ]; then
            gow_log "[steam] Steam process has exited, terminating container..."
            # 清理XFCE进程
            pkill -f xfce4-session 2>/dev/null || true
            pkill -f Xwayland 2>/dev/null || true
            # 退出容器
            exit 0
        else
            gow_log "[steam] Steam process found with new PID: $CURRENT_PID"
        fi
    fi
    sleep 2
done
