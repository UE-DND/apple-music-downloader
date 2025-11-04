#!/bin/bash
# Apple Music Downloader - Docker 入口脚本

# 将宿主机配置复制到容器内并替换网络地址
if [ -f /app/config-host.yaml ]; then
    # 复制并修改配置（127.0.0.1 → host.docker.internal）
    sed 's/127\.0\.0\.1/host.docker.internal/g' /app/config-host.yaml > /app/config.yaml
    echo "已配置容器网络 (wrapper: host.docker.internal:10020)"
fi

# 执行下载器
cd /app
exec /usr/local/bin/apple-music-downloader "$@"
