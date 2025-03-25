FROM registry.cn-beijing.aliyuncs.com/zexi/ubuntu:22.04 AS nvidia-installer

ARG NV_VERSION
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends curl ca-certificates kmod pkg-config libglvnd-dev vulkan-tools
#RUN curl -LO https://cn.download.nvidia.com/XFree86/Linux-x86_64/$NV_VERSION/NVIDIA-Linux-x86_64-$NV_VERSION.run && \
RUN curl -LO http://192.168.6.60:8000/NVIDIA-Linux-x86_64-$NV_VERSION.run
RUN chmod +x NVIDIA-Linux-x86_64-$NV_VERSION.run && mkdir -p /usr/nvidia
RUN ./NVIDIA-Linux-x86_64-$NV_VERSION.run --silent -z --skip-depmod --skip-module-unload --no-nvidia-modprobe --no-kernel-modules --no-kernel-module-source --opengl-prefix=/usr/nvidia --wine-prefix=/usr/nvidia --utility-prefix=/usr/nvidia --utility-libdir=lib --compat32-prefix=/usr/nvidia --compat32-libdir=lib32 --egl-external-platform-config-path=/usr/nvidia/share/egl/egl_external_platform.d --glvnd-egl-config-path=/usr/nvidia/share/glvnd/egl_vendor.d --no-distro-scripts && \
    rm ./NVIDIA-Linux-x86_64-$NV_VERSION.run

# shellcheck disable=SC3037
RUN echo -e "/usr/nvidia/lib\n/usr/nvidia/lib32" > /etc/ld.so.conf.d/nvidia.conf && ldconfig

################
FROM scratch

COPY --from=nvidia-installer /usr/nvidia/ /usr/nvidia
COPY --from=nvidia-installer /etc/vulkan/icd.d/nvidia_icd.json /usr/nvidia/share/vulkan/icd.d/
