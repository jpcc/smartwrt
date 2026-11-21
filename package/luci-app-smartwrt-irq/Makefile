# This is free software, licensed under the Apache License, Version 2.0.

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI support for smartwrt-irq
LUCI_DEPENDS:=+luci-base +libuci-lua +irqbalance

PKG_LICENSE:=Apache-2.0
PKG_MAINTAINER:=jpcc <8264267+jpcc@users.noreply.github.com>

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
