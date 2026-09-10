# SmartWrt

**SmartWrt** is a fork of [OpenWrt](https://openwrt.org/) that delivers a pre-configured, ready-to-use router firmware: a curated set of packages, pre-tuned UCI defaults and device-specific configuration files, built with a modern, hardened toolchain and shipped as images that are ready to flash and work out of the box.

The fork is intentionally thin. It preserves full compatibility with the OpenWrt project, tracking the upstream branch through periodic merges and limiting its own changes to package selection, default configurations and adjustments tailored to an advanced residential environment. The goal is not a completely different distribution, but an variant that already comes with its features integrated and configured.

## SmartWrt features and package additions

#### Features

* Advanced DNS server capable of caching (with persistence), prefetching, fast IP selection, configurable upstream servers and optimized domain resolution.
* System-wide ad and tracker blocking, integrated with the DNS server.
* Per-device bandwidth monitoring and visualization, including connection states and DNS query analysis.
* Dynamic DNS client updates to keep hostnames in sync with changing IP addresses.
* Network filtering to help prevent IP address spoofing from the local network.
* WireGuard VPN with LuCI configuration and management.
* Full IEEE 802.1X authentication and supplicant implementation with OpenSSL, enabling advanced Wi-Fi roaming, including 802.11r Fast BSS Transition and 802.11k Radio Resource Management.
* Wi-Fi client steering and access-point load balancing.
* Management and sharing of upstream Wi-Fi connections.
* Scheduled Wi-Fi enable/disable and Wi-Fi client association history visualization.
* Automatic network connectivity monitoring and recovery.
* Wake-on-LAN management through LuCI.
* Kernel-based SMB/CIFS file server with Web Services Dynamic Discovery for improved Windows network discovery.
* DLNA/UPnP media server for sharing multimedia content over the network.
* LuCI-based file manager, command runner, apk package management and embedded web server configuration.
* Compressed RAM-based block devices (ZRAM) using the Zstd compression algorithm.
* TCP BBR as the default TCP congestion-control algorithm.
* Hardware and Software flow offloading through nftables to accelerate packet forwarding and reduce CPU overhead.
* Hardware-accelerated cryptographic operations through the AF_ALG sockets engine.
* OpenSSL as the primary cryptographic and TLS library instead of mbedTLS.
* Automatic distribution of hardware interrupts across available CPU cores.
* Configurable hard-drive spindown/standby for connected storage devices.
* Alternative LuCI themes: Argon and Footstrap.
* Architecture-specific build and runtime optimizations.
* Compiler, linker and runtime hardening: ASLR/PIE, stack protector, FORTIFY_SOURCE and full RELRO.
* Modern toolchain: GCC 15.2.0 and GNU Binutils 2.45.1.

#### Packages

* **adblock-fast** + `luci-app-adblock-fast` — system-wide ad and tracker blocking.
* **bandix** + `luci-app-bandix` — eBPF-based network traffic monitoring.
* **bcp38** + `luci-app-bcp38` — BCP38 spoofing prevention.
* **ddns-scripts** + `ddns-scripts-services` + `luci-app-ddns` — dynamic DNS client and service definitions.
* **etherwake** + `luci-app-wol` — Wake-on-LAN.
* **hd-idle** + `luci-app-hd-idle` — hard-drive spindown/standby.
* **irqbalance** + `luci-app-irqbalance` — hardware interrupt balancing.
* **kmod-nft-offload** — nftables flow offloading.
* **kmod-tcp-bbr** — TCP BBR congestion control, set as default by the bundled sysctl.
* **ksmbd-server** + `kmod-fs-ksmbd` + `luci-app-ksmbd` + **wsdd2** — kernel SMB/CIFS server and Windows discovery.
* **libopenssl** + `libustream-openssl` — OpenSSL TLS library and ustream integration.
* **luci-app-commands** — LuCI command runner.
* **luci-app-filemanager** — LuCI file manager.
* **luci-app-package-manager** — LuCI package management UI for apk.
* **luci-app-uhttpd** — LuCI configuration for the embedded web server.
* **luci-app-wifihistory** — Wi-Fi client history visualization.
* **luci-theme-argon** + `luci-app-argon-config` + **luci-theme-footstrap** — LuCI themes and theme configuration.
* **minidlna** + `luci-app-minidlna` — DLNA/UPnP media server.
* **smartdns** + `luci-app-smartdns` — advanced DNS server.
* **travelmate** — upstream Wi-Fi connection manager.
* **usteer** — Wi-Fi client steering and AP load balancing.
* **watchcat** — connectivity monitoring and recovery.
* **wifischedule** + `luci-app-wifischedule` — scheduled Wi-Fi.
* **wpad-openssl** — full IEEE 802.1X authenticator and supplicant with OpenSSL.
* **wireguard-tools** + `kmod-wireguard` + `luci-proto-wireguard` — WireGuard VPN.
* **zram-swap** + `kmod-zram` — ZRAM swap with Zstd compression.

> **Note:** Bandix requires switching to *software flow offloading* during traffic monitoring. 
> If you enable Bandix, change the *flow offloading* setting under Network → Firewall.

## Status and Usage

SmartWrt should not currently be considered a stable or production-ready distribution.

The project is primarily being developed for:

* development;
* testing;
* configuration validation;
* experimentation with additional packages and features;
* evaluation of changes to OpenWrt.

The use of SmartWrt in production environments or commercial applications is not recommended. Its intended use at this stage is testing and experimentation, particularly on the currently supported hardware.

## Current Support

At this time, the project is in an experimental development, testing, and validation phase, with an exclusive focus on this devices:

* [**D-Link DIR-3040 A1**](https://techinfodepot.shoutwiki.com/wiki/D-Link_DIR-3040_rev_A1)

> **Note:** Support for other devices and platforms is not a priority at this stage. As the project evolves, stability, compatibility, and support for additional devices may be evaluated and expanded.

## Development

### Repository layout

* `devices/dir-3040/configs/` — source build configuration (copied to `.config`)
* `devices/dir-3040/files/` — device-specific UCI configs (copied to `files/`)
* `files/` — root overlay applied to the image
* `.config` is generated from the device config via `make defconfig`; edit
  `devices/dir-3040/configs/dir-3040.config`, never `.config` directly

### Build

To build your own SmartWrt firmware you need a GNU/Linux, BSD or macOS system (case
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

```
git clone https://github.com/jpcc/smartwrt.git
cd smartwrt
./scripts/feeds update -a
./scripts/feeds install -a
cp devices/dir-3040/configs/dir-3040.config .config
cp -a devices/dir-3040/files/. files/
make -j$(nproc) defconfig download clean world
```

### Build artifacts

The resulting firmware files will be located in `bin/targets/ramips/mt7621/`. 
The build produces three artifacts:

* **`smartwrt-ramips-mt7621-dlink_dir-3040-a1-initramfs-kernel.bin`** — Kernel and root filesystem loaded entirely into RAM, without touching the flash. Used for testing and validating builds before installing them permanently.
* **`smartwrt-ramips-mt7621-dlink_dir-3040-a1-squashfs-sysupgrade.bin`** — The regular firmware image. Used to install SmartWrt on a device already running OpenWrt/SmartWrt, via `sysupgrade` or LuCI.
* **`smartwrt-ramips-mt7621-dlink_dir-3040-a1-squashfs-recovery.bin`** — Recovery image in the layout accepted by the vendor bootloader. It must be used to unlock the DIR-3040 with the **D-Link recovery tool**, which is how SmartWrt is installed on a device still running the stock firmware, and it also serves as a recovery path after a failed flash.

## Flashing SmartWrt on a stock device

On a device still running the stock D-Link firmware, SmartWrt is installed through the **D-Link recovery GUI** using the recovery image (`smartwrt-ramips-mt7621-dlink_dir-3040-a1-squashfs-recovery.bin`). The steps below follow the OpenWrt installation instructions for the DIR-3040 A1.

> **Note:** The recovery GUI seems to only work in Firefox on Windows.

1. Push and hold the reset button (on the bottom of the device) while plugging in the power cable, until the power LED starts flashing (about 10 seconds or so).
2. Give it ~30 seconds to boot the recovery mode GUI.
3. Connect your client computer to **LAN1** of the device.
4. Set your client IP address manually to `192.168.0.2` / `255.255.255.0`.
5. Open the recovery page of the device at `http://192.168.0.1/`.
6. Use the emergency web GUI to upload and flash the SmartWrt recovery image to the device.

After the flash completes, the device boots SmartWrt.

## Licensing

SmartWrt is based on OpenWrt and includes third-party components
distributed under their respective licenses.

The OpenWrt build system is licensed under GPL-2.0-only. Individual
packages and components included in SmartWrt may be distributed under
different open-source licenses.

Each component retains its original copyright notices and license
requirements. Refer to the respective package source and license files
for the applicable license.
