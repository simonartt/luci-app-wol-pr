#
# Copyright (C) 2024-2026 Simon <simon@example.com>
#
# This is free software, licensed under the Apache License, Version 2.0.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-wol-pro
PKG_VERSION:=1.1.0
PKG_RELEASE:=1
PKG_MAINTAINER:=Simon
PKG_LICENSE:=Apache-2.0
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-wol-pro
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=Wake-on-LAN Pro - Tile-based device management
  DEPENDS:=+etherwake +luci-compat
  PKGARCH:=all
endef

define Package/luci-app-wol-pro/description
  Wake-on-LAN Pro plugin for LuCI with tile-based device management.
  Features: device memory, one-click wake, online detection, custom notes.
endef

# Note: No Build/Prepare needed.
# The package directory itself (luasrc/, root/, etc.) is automatically
# used as the source by OpenWrt's package build system.

define Build/Configure
endef

define Build/Compile
endef

define Package/luci-app-wol-pro/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/wol-pro
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DIR) $(1)/usr/libexec/istoree
	$(INSTALL_DIR) $(1)/usr/share/istore

	# Install Lua controller
	$(INSTALL_DATA) ./luasrc/controller/wol-pro.lua $(1)/usr/lib/lua/luci/controller/

	# Install Lua views
	$(INSTALL_DATA) ./luasrc/view/wol-pro/index.htm $(1)/usr/lib/lua/luci/view/wol-pro/
	if [ -f ./luasrc/view/wol-pro/logs.htm ]; then \
		$(INSTALL_DATA) ./luasrc/view/wol-pro/logs.htm $(1)/usr/lib/lua/luci/view/wol-pro/ ; \
	fi

	# Install config file
	$(INSTALL_DATA) ./root/etc/config/wol-pro $(1)/etc/config/

	# Install iStore status script
	$(INSTALL_BIN) ./root/usr/libexec/istoree/wol-pro.sh $(1)/usr/libexec/istoree/

	# Install iStore metadata
	$(INSTALL_DATA) ./istore_meta.json $(1)/usr/share/istore/$(PKG_NAME).json
endef

define Package/luci-app-wol-pro/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	rm -f /tmp/luci-indexcache.*
	rm -rf /tmp/luci-modulecache/
	killall -HUP rpcd 2>/dev/null || true
	exit 0
}
endef

define Package/luci-app-wol-pro/postrm
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	rm -f /tmp/luci-indexcache.*
	rm -rf /tmp/luci-modulecache/
	killall -HUP rpcd 2>/dev/null || true
	exit 0
}
endef

$(eval $(call BuildPackage,luci-app-wol-pro))
