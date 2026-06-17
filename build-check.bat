@echo off
cd /d D:\traecx\openwrt2\wol
echo === Debug: Checking SDK image structure ===
docker run --rm -w /builder openwrt/sdk:rockchip-armv8-openwrt-23.05 ^
  sh -c "pwd && echo --- && ls -la && echo === && ls -d */ 2>/dev/null"
echo.
pause
