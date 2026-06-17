@echo off
cd /d D:\traecx\openwrt2\wol
set SDK_TAR=build-env\sdk\sdk.tar.xz
set SDK_URL=https://downloads.openwrt.org/releases/23.05.5/targets/rockchip/armv8/openwrt-sdk-23.05.5-rockchip-armv8_gcc-12.3.0_musl.Linux-x86_64.tar.xz
echo === Building luci-app-wol-pro v1.1.0 ===
if not exist "%SDK_TAR%" (
    echo Downloading SDK (first time only, ~178MB)...
    mkdir build-env\sdk >nul 2>&1
    curl -L -o "%SDK_TAR%" "%SDK_URL%"
    if errorlevel 1 (echo Download failed! & pause & exit /b 1)
) else (echo Using cached SDK...)
echo.
docker run --rm -v "%cd%\luci-app-wol-pro:/tmp/luci-app-wol-pro:ro" -v "%cd%\build-env\sdk:/sdk-cache:ro" -v "%cd%\build-env\output:/output" -w /builder openwrt/sdk:rockchip-armv8-openwrt-23.05 bash -c "set -ex && tar -xJf /sdk-cache/sdk.tar.xz --strip-components=1 -C /builder/ && mkdir -p package && cp -r /tmp/luci-app-wol-pro ./package/luci-app-wol-pro && ./scripts/feeds update luci && ./scripts/feeds install -a -p luci && echo CONFIG_PACKAGE_luci-app-wol-pro=m >> .config && make defconfig && make package/luci-app-wol-pro/clean V=s && make package/luci-app-wol-pro/compile V=s -j1 && find bin/packages -name 'luci-app-wol-pro*.ipk' -exec cp -v {} /output/ \;"
if errorlevel 1 (echo. & echo === Build failed ===) else (echo. & echo === Build successful! === & dir build-env\output\luci-app-wol-pro*.ipk)
pause
