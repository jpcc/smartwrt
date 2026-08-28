# SmartWrt

**SmartWrt** is a fork of [OpenWrt](https://openwrt.org/) focused on providing a pre-configured and ready-to-use experience while maintaining maximum compatibility with and preserving the structure of the upstream project.

The goal of SmartWrt is to make **minimal changes to OpenWrt**, primarily focused on including pre-selected packages, default configurations, and adjustments specifically tailored for an advanced residential environment. The objective is not to create a completely different distribution, but rather to provide an OpenWrt variant with selected features already integrated and configured.

## Current Support

At this time, the project is in an **experimental development, testing, and validation phase**, with an exclusive focus on this devices:

* [**D-Link DIR-3040 A1**](https://techinfodepot.shoutwiki.com/wiki/D-Link_DIR-3040_rev_A1)

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

```
git clone https://github.com/jpcc/smartwrt.git
cd smartwrt
./scripts/feeds update -a
./scripts/feeds install -a
cp configs/dir-3040.config .config
make -j$(nproc) defconfig download clean world
```

The resulting firmware files will be located in "~/smartwrt/bin/targets/ramips/mt7621/"

### SmartWrt features and package additions

* **Adblock Fast** — Adds system-wide ad and tracker blocking with LuCI integration.
* **Argon Theme** —  Adds the Argon LuCI theme as an alternative web interface.
* **Argon Config** — Adds LuCI configuration support for the Argon theme.
* **Bandix** — Adds bandwidth monitoring and visualization capabilities with LuCI integration.
* **BCP38** — Adds network filtering to help prevent IP address spoofing from the local network.
* **Binutils 2.45.1** — Uses GNU Binutils 2.45.1 as part of the SmartWrt toolchain.
* **Build and runtime optimizations** — Adds architecture-specific build and runtime optimizations.
* **Compiler Optimizations** — Adds architecture-specific compiler optimizations.
* **File Manager** — Adds a LuCI-based file manager for managing files directly from the web interface.
* **Footstrap** — Adds the Footstrap LuCI theme as an alternative web interface.
* **GCC 15.2.0** — Uses GCC 15.2.0 as the compiler toolchain for building SmartWrt.
* **Hardening** — Adds additional compiler, linker, and runtime hardening measures to improve system security and resilience.
* **Hardware-Accelerated Cryptography** — Adds hardware-accelerated cryptographic operations through the AF_ALG sockets engine.
* **Hardware Flow Offloading** — Enables hardware-based flow offloading to accelerate packet forwarding and reduce CPU overhead for supported network traffic.
* **HD Idle** — Adds configurable hard-drive spindown/standby support for connected storage devices.
* **HTTPS DNS Proxy** — Adds DNS-over-HTTPS forwarding support.
* **IRQBalance** — Adds automatic distribution of hardware interrupts across available CPU cores.
* **Ksmbd** — Adds a kernel-based SMB/CIFS file server for network file sharing.
* **MiniDLNA** — Adds DLNA/UPnP media-server functionality for sharing multimedia content over the network.
* **OpenSSL** — Uses OpenSSL as the primary cryptographic and TLS library instead of mbedTLS.
* **TCP BBR** — Uses TCP BBR as the default congestion-control algorithm, providing improved throughput, latency, and network utilization.
* **SmartDNS** — Adds advanced DNS resolution, including support for configurable DNS servers and optimized domain resolution.
* **Travelmate** — Adds support for managing and sharing upstream Wi-Fi connections.
* **uSteer** — Adds Wi-Fi client steering and access-point load balancing capabilities.
* **Watchcat** — Adds automatic network connectivity monitoring and recovery mechanisms.
* **WiFi Schedule** — Adds scheduled Wi-Fi enable/disable functionality.
* **Wpad-openssl** — Uses the full IEEE 802.1X authentication and supplicant implementation with OpenSSL, enabling advanced Wi-Fi roaming and authentication features including 802.11r Fast BSS Transition and 802.11k Radio Resource Management.
* **WireGuard** — Adds WireGuard VPN support, including LuCI configuration and management.
* **WOL** — Adds Wake-on-LAN management through LuCI.
* **WSDD2** — Adds Web Services Dynamic Discovery support for improved Windows network discovery.
* **ZRAM** — Adds compressed RAM-based block devices to improve memory utilization and reduce memory pressure on resource-constrained systems.
* **ZSTD** — Adds Zstd as the default compression algorithm.

## Licensing

SmartWrt is based on OpenWrt and includes third-party components
distributed under their respective licenses.

The OpenWrt build system is licensed under GPL-2.0-only. Individual
packages and components included in SmartWrt may be distributed under
different open-source licenses.

Each component retains its original copyright notices and license
requirements. Refer to the respective package source and license files
for the applicable license.
