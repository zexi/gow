ARG BASE_APP_IMAGE
ARG CTR_GAME_CUSTOMIZE_IMAGE

######################################
# The issue here is, that you don't want to give privileged,
# but bwrap needs CAP_SYS_ADMIN.
# However if you explicitly give CAP_SYS_ADMIN, bwrap throws an error,
# because it detects that capabilities have been tempered with
FROM registry.cn-beijing.aliyuncs.com/zexi/ubuntu:24.10 AS bwrap-builder

ENV DEBIAN_FRONTEND=non-interactive
WORKDIR /root
COPY ignore_capabilities.patch /root/
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends git meson ca-certificates dpkg-dev && \
    git clone https://github.com/containers/bubblewrap && \
    cd bubblewrap && \
    ./ci/builddeps.sh && \
    patch -p1 < ../ignore_capabilities.patch && \
    meson _builddir && \
    meson compile -C _builddir

######################################

FROM ${CTR_GAME_CUSTOMIZE_IMAGE} as customize

# hadolint ignore=DL3006
FROM ${BASE_APP_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive

ARG REQUIRED_PACKAGES=" \
    steam \
    dbus-daemon dbus-system-bus-common dbus-session-bus-common whoopsie network-manager bluez \
    ibus curl pkexec xz-utils zenity file xdg-user-dirs xdg-utils pciutils lsb-release mesa-utils \
    libfontconfig1:i386 libfontconfig1:amd64 libfreetype6 libfreetype6:i386 wl-clipboard \
    wget \
    gnupg2 \
    dbus-x11 \
    flatpak \
    sudo \
    xdotool \
    wmctrl \
    xsel \
    scrot \
"
    # firefox \

ARG AVOID_PACKAGES=" \
    nvidia-driver-libs- nvidia-vulkan-icd- \
"

ARG DE_PACKAGES=" \
    xfce4 \
    xfce4-settings \
    xubuntu-default-settings \
    xubuntu-icon-theme \
    papirus-icon-theme arc-theme \
    at-spi2-core \
    "

ARG ADDITIONAL_PACKAGES=" \
    xfce4-terminal \
    xfce4-taskmanager \
    xfce4-whiskermenu-plugin \
    xfce4-docklike-plugin \
    xfce4-genmon-plugin \
    xarchiver \
    mousepad \
    zip unzip p7zip-full \
    gnome-software gnome-software-plugin-flatpak \
    "

# Prevent firefox snap
# COPY scripts/ff-unsnap /etc/apt/preferences.d/ff-unsnap


    # add-apt-repository -y ppa:mozillateam/ppa && \

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends software-properties-common gpg-agent && \
    apt-get install -y python3-six software-properties-common && \
    # \
    # Install steam (Steam is 32-bit only) \
    dpkg --add-architecture i386 && \
    add-apt-repository multiverse && \
    apt-get update -y && \
    apt-get install -y $REQUIRED_PACKAGES $AVOID_PACKAGES && \
    # \
    # Install de \
    apt-get install -y $DE_PACKAGES && \
    # \
    # Install additional apps \
    apt-get install -y --no-install-recommends $ADDITIONAL_PACKAGES && \
    # \
    # Fixes \
    rm -f \
    /etc/xdg/autostart/xscreensaver.desktop && \
    # \
    # Fix steam updater UI font file \
    ln -s /usr/share/fonts/truetype/dejavu /usr/share/fonts/truetype/ttf-dejavu && \
    # \
    # Cleanup \
    apt-get remove -y python3-six software-properties-common && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /config/.cache \
        /var/tmp/* \
        /tmp/*
# fix NetworkManager not picking up devices
RUN touch /etc/NetworkManager/conf.d/10-globally-managed-devices.conf

# skip annoying debian dialog
RUN rm /usr/bin/zenity && ln -s /usr/bin/true /usr/bin/zenity

# refresh system font cache. For font warnings on startup see: https://github.com/ValveSoftware/steam-runtime/issues/482
RUN fc-cache -f -v

# 
# Replace launch scripts
COPY --chmod=777 scripts/launch-comp.sh scripts/startup.sh scripts/start-steam.sh scripts/steam-fullscreen.sh /opt/gow/
COPY --chmod=777 scripts/startdbus.sh /opt/gow/startdbus
#
# Include default xfce config
COPY --chmod=777 --chown=retro:retro scripts/xfce4 /opt/gow/xfce4
# Include GTK3 CSS for notification font customization
COPY --chmod=777 --chown=retro:retro scripts/gtk-3.0 /opt/gow/gtk-3.0

# 
# Fix locals
COPY scripts/locale /etc/default/locale
# 
# Allow anyone to start dbus without password
RUN echo "\nALL ALL=NOPASSWD: /opt/gow/startdbus" >> /etc/sudoers
# 
# Fix bwarp perms for flatpaks
RUN chmod u+s /usr/bin/bwrap

COPY --chmod=777 scripts/system-services.sh /etc/cont-init.d/system-services.sh
COPY --chmod=777 steamos-update /usr/bin/steamos-update
COPY --chmod=777 steamos-update /usr/bin/steamos-polkit-helpers/steamos-update
COPY --chmod=777 steamos-session-select /usr/bin/steamos-session-select
COPY --chmod=777 jupiter-biosupdate /usr/bin/jupiter-biosupdate
COPY --chmod=777 jupiter-biosupdate /usr/bin/steamos-polkit-helpers/jupiter-biosupdate
COPY --from=bwrap-builder --chmod=755 /root/bubblewrap/_builddir/bwrap /usr/bin/bwrap

COPY --from=customize --chmod=755 /etc/cont-init.d/10-setup_user.sh /etc/cont-init.d/10-setup_user.sh
#COPY --from=customize --chmod=755 /etc/cont-init.d/30-nvidia.sh /etc/cont-init.d/30-nvidia.sh

COPY --chmod=777 wolf-hook /opt/bin/wolf-hook
COPY --chmod=777 wolf-input /opt/bin/wolf-input
COPY --chmod=777 steam-helper /opt/bin/steam-helper

# Delete these as they are not needed at all
RUN rm -f \
  /usr/share/applications/xfce4-about.desktop \
  /usr/share/applications/xfce4-session-logout.desktop \
  # Hide these apps. They can be displayed if a user really wants them.
  && sed -i '/[Desktop Entry]/a\NoDisplay=true' /usr/share/applications/xfce4-accessibility-settings.desktop \
  && sed -i '/[Desktop Entry]/a\NoDisplay=true' /usr/share/applications/xfce4-color-settings.desktop \
  && sed -i '/[Desktop Entry]/a\NoDisplay=true' /usr/share/applications/xfce4-mail-reader.desktop \
  && sed -i '/[Desktop Entry]/a\NoDisplay=true' /usr/share/applications/xfce4-web-browser.desktop \
  && sed -i '/[Desktop Entry]/a\NoDisplay=true' /usr/share/applications/thunar-settings.desktop \
  && sed -i '/[Desktop Entry]/a\NoDisplay=true' /usr/share/applications/thunar.desktop \
  # Force these apps to be "System" Apps rather than "Categories=System;Utility;Core;GTK;Filesystem;"
  && sed -i 's/^Categories=.*$/Categories=System;/' /usr/share/applications/xfce4-appfinder.desktop \
  && sed -i 's/^Categories=.*$/Categories=System;/' /usr/share/applications/thunar-bulk-rename.desktop

ENV XDG_RUNTIME_DIR=/tmp/.X11-unix

ARG IMAGE_SOURCE
LABEL org.opencontainers.image.source=$IMAGE_SOURCE
