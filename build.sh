#!/bin/bash
# OpenWRT SDK Docker 编译脚本
# 用于 luci-app-wol-pro 插件

set -e

echo "=== 开始编译 luci-app-wol-pro ==="

docker run --rm \
  -v "$(pwd)/luci-app-wol-pro:/tmp/luci-app-wol-pro:ro" \
  -v "$(pwd)/build-env/output:/output" \
  -e VERSION_PATH="releases/23.05.5" \
  -e TARGET="rockchip/armv8" \
  -w /builder \
  openwrt/sdk:rockchip-armv8-openwrt-23.05 \
  bash << 'INNER_SCRIPT'
set -ex

# 1. 初始化 SDK
echo ">>> 初始化 SDK..."
./setup.sh

# 2. 复制插件
echo ">>> 复制插件源码..."
cp -r /tmp/luci-app-wol-pro ./package/luci-app-wol-pro

# 3. 更新 feeds
echo ">>> 更新 feeds..."
./scripts/feeds update luci
./scripts/feeds install -a -p luci

# 4. 配置
echo ">>> 配置编译选项..."
echo "CONFIG_PACKAGE_luci-app-wol-pro=m" >> .config
make defconfig

# 5. 清理并编译 (单线程详细模式)
echo ">>> 清理旧编译..."
make package/luci-app-wol-pro/clean V=s

echo ">>> 开始编译..."
make package/luci-app-wol-pro/compile V=s -j1

# 6. 复制输出
echo ">>> 复制生成的 ipk..."
find bin/packages -name "luci-app-wol-pro*.ipk" -exec cp -v {} /output/ \;

echo ">>> 编译完成!"
ls -la /output/
INNER_SCRIPT

echo "=== 本地输出文件 ==="
ls -la build-env/output/