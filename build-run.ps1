$ErrorActionPreference = "Continue"
$host.ui.RawUI.WindowTitle = "Building luci-app-wol-pro v1.1.0"

$PROXY = "http://192.168.53.179:10808"
$WORKDIR = "D:\traecx\openwrt2\wol"

Write-Host "=== Building luci-app-wol-pro v1.1.0 ===" -ForegroundColor Cyan

$bashScript = @"
set -ex

echo '>>> Configuring git proxy...'
git config --global http.proxy $PROXY
git config --global https.proxy $PROXY

echo '>>> Initializing SDK...'
./setup.sh

echo '>>> Copying plugin source...'
mkdir -p package
cp -r /tmp/luci-app-wol-pro ./package/luci-app-wol-pro

echo '>>> Updating feeds...'
./scripts/feeds update luci
./scripts/feeds install -a -p luci

echo '>>> Configuring build...'
echo CONFIG_PACKAGE_luci-app-wol-pro=m >> .config
make defconfig

echo '>>> Cleaning old build...'
make package/luci-app-wol-pro/clean V=s

echo '>>> Compiling...'
make package/luci-app-wol-pro/compile V=s -j1

echo '>>> Copying output...'
find bin/packages -name 'luci-app-wol-pro*.ipk' -exec cp -v {} /output/ \;

echo '>>> Build complete!'
ls -la /output/
"@

$bashScript | docker run --rm `
  -i `
  -e HTTP_PROXY=$PROXY `
  -e HTTPS_PROXY=$PROXY `
  -e http_proxy=$PROXY `
  -e https_proxy=$PROXY `
  -v "${WORKDIR}\luci-app-wol-pro:/tmp/luci-app-wol-pro:ro" `
  -v "${WORKDIR}\build-env\output:/output" `
  -w /builder `
  openwrt/sdk:rockchip-armv8-openwrt-23.05 `
  bash -s

if ($LASTEXITCODE -eq 0) {
    Write-Host "=== BUILD SUCCESS ===" -ForegroundColor Green
    Get-ChildItem "$WORKDIR\build-env\output\luci-app-wol-pro*.ipk" | ForEach-Object { Write-Host "Output: $($_.Name) ($($_.Length) bytes)" -ForegroundColor Green }
} else {
    Write-Host "=== BUILD FAILED (exit code: $LASTEXITCODE) ===" -ForegroundColor Red
}
