# SmartWrt

**SmartWrt** is a fork of [OpenWrt](https://openwrt.org/) focused on providing a pre-configured and ready-to-use experience while maintaining maximum compatibility with and preserving the structure of the upstream project.

The goal of SmartWrt is to make **minimal changes to OpenWrt**, primarily focused on including pre-selected packages, default configurations, and adjustments specifically tailored for an advanced residential environment. The objective is not to create a completely different distribution, but rather to provide an OpenWrt variant with selected features already integrated and configured.

## Current Support

At this time, the project is in an **experimental development, testing, and validation phase**, with an exclusive focus on:

* **D-Link DIR-3040 A1**
* **ramips** architecture
* This platform is being used as the reference device for project development and validation

Support for other devices and platforms is **not a priority at this stage**. Adaptations for additional targets may be considered in the future as the project evolves.

## Status and Usage

SmartWrt **should not currently be considered a stable or production-ready distribution**.

The project is primarily being developed for:

* development;
* testing;
* configuration validation;
* experimentation with additional packages and features;
* evaluation of changes to OpenWrt.

**The use of SmartWrt in production environments or commercial applications is not recommended.** Its intended use at this stage is testing and experimentation, particularly on the currently supported hardware.

As the project evolves, stability, compatibility, and support for additional devices may be evaluated and expanded.

## Development

To build your own firmware you need a GNU/Linux, BSD or macOS system (case
sensitive filesystem required). Cygwin is unsupported because of the lack of a
case sensitive file system.

### Requirements

You need the following tools to compile, the package names vary between
distributions. A complete list with distribution specific packages is found in
the [Build System Setup](https://openwrt.org/docs/guide-developer/build-system/install-buildsystem)
documentation.

```
binutils bzip2 diff find flex gawk gcc-6+ getopt grep install libc-dev libz-dev
make4.1+ perl python3.8+ rsync subversion unzip which
```

### Quickstart

1. Run `./scripts/feeds update -a` to obtain all the latest package definitions
   defined in feeds.conf / feeds.conf.default

2. Run `./scripts/feeds install -a` to install symlinks for all obtained
   packages into package/feeds/

3. Run `make menuconfig` to select your preferred configuration for the
   toolchain, target system & firmware packages.

4. Run `make` to build your firmware. This will download all sources, build the
   cross-compile toolchain and then cross-compile the GNU/Linux kernel & all chosen
   applications for your target system.

### Related Repositories

The main repository uses multiple sub-repositories to manage packages of
different categories. All packages are installed via the OpenWrt package
manager called `opkg`. If you're looking to develop the web interface or port
packages to OpenWrt, please find the fitting repository below.

* [LuCI Web Interface](https://github.com/openwrt/luci): Modern and modular
  interface to control the device via a web browser.

* [OpenWrt Packages](https://github.com/openwrt/packages): Community repository
  of ported packages.

* [OpenWrt Routing](https://github.com/openwrt/routing): Packages specifically
  focused on (mesh) routing.

* [OpenWrt Video](https://github.com/openwrt/video): Packages specifically
  focused on display servers and clients (Xorg and Wayland).

## Licensing

SmartWrt is based on OpenWrt and includes third-party components
distributed under their respective licenses.

The OpenWrt build system is licensed under GPL-2.0-only. Individual
packages and components included in SmartWrt may be distributed under
different open-source licenses.

Each component retains its original copyright notices and license
requirements. Refer to the respective package source and license files
for the applicable license.
