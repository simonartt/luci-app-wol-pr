#!/bin/sh
# istoree status script for wol-pro

status() {
    local enabled
    enabled=$(uci get wol-pro.global.enabled 2>/dev/null)
    
    if [ "$enabled" = "1" ]; then
        echo '{"running": true, "version": "1.1.0"}'
    else
        echo '{"running": false, "version": "1.1.0"}'
    fi
}

case "$1" in
    status)
        status
        ;;
    *)
        echo "Usage: $0 {status}"
        exit 1
        ;;
esac
