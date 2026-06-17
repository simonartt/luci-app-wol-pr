$ErrorActionPreference = "Stop"
Write-Host "=== Building luci-app-wol-pro ===" -ForegroundColor Cyan

docker run --rm `
  -v "$(Get-Location)\luci-app-wol-pro:/tmp/luci-app-wol-pro:ro" `
  -v "$(Get-Location)\build-env\output:/output" `
  -e VERSION_PATH="releases/23.05.5" `
  -e TARGET="rockchip/armv8" `
  -w /builder `
  openwrt/sdk:rockchip-armv8-openwrt-23.05 `
  bash -c "set -ex && ./setup.sh && cp -r /tmp/luci-app-wol-pro ./package/luci-app-wol-pro && ./scripts/feeds update luci && ./scripts/feeds install -a -p luci && echo CONFIG_PACKAGE_luci-app-wol-pro=m >> .config && make defconfig && make package/luci-app-wol-pro/clean V=s && make package/luci-app-wol-pro/compile V=s -j1 && find bin/packages -name 'luci-app-wol-pro*.ipk' -exec cp -v {} /output/ \;"

if ($LASTEXITCODE -eq 0) {
    Write-Host "=== Build successful! ===" -ForegroundColor Green
    Get-ChildItem .\build-env\output\ -Name
} else {
    Write-Host "=== Build failed (exit code: $LASTEXITCODE) ===" -ForegroundColor Red
}
