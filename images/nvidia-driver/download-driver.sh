#!/bin/bash
NV_VERSION=`cat /sys/module/nvidia/version`
curl -LO https://download.nvidia.com/XFree86/Linux-x86_64/$NV_VERSION/NVIDIA-Linux-x86_64-$NV_VERSION.run
