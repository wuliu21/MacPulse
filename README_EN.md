<div align="center">

<img src="assets/banner.svg" alt="MacPulse HUD Banner" width="100%" />

<br/>

# ⚡ MacPulse HUD

**Native Swift 6 macOS Desktop Floating Transparent Performance Monitor**  
*100% Click-Through · Hold `⌥ Option` to Drag Anytime · Rootless Apple Silicon CPU/GPU/Temp/Fan/Power Telemetry*

[**🇨🇳 简体中文**](README.md) | **🇺🇸 English**

[![Swift 6](https://img.shields.io/badge/Swift-6.0+-F05138?style=flat-square&logo=swift&logoColor=white)](https://swift.org)
[![macOS 13+](https://img.shields.io/badge/Platform-macOS%2013.0+-000000?style=flat-square&logo=apple&logoColor=white)](https://www.apple.com/macos)
[![Apple Silicon](https://img.shields.io/badge/Architecture-Apple%20Silicon%20%26%20Intel-3debbf?style=flat-square)](https://developer.apple.com)
[![i18n](https://img.shields.io/badge/i18n-8%20Languages-a78bfa?style=flat-square)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-fbbf24?style=flat-square)](LICENSE)

</div>

---

## ✨ Why MacPulse HUD?

Most macOS performance monitors either cram tiny numbers into the menu bar or wrap an Electron webview that consumes 300 MB of RAM. Meanwhile, traditional floating desktop windows block mouse clicks or become illegible over bright white web pages.

Built with **100% Native Swift + AppKit (`NSPanel`) + SwiftUI (`Canvas`) + Mach/IOKit/SMC**, **MacPulse HUD** solves every pain point of a 24/7 desktop HUD:

1. **🎯 100% Click-Through + Hold `⌥ Option` to Drag**
   - Enabled by default (`ignoresMouseEvents = true`), your clicks pass straight through to underlying IDEs, browsers, or full-screen apps.
   - Want to move it? Simply **hold the `⌥ Option` key** and drag anywhere on the HUD. Release `⌥ Option` to auto-save coordinates and re-lock click-through.
2. **⚡ Rootless (No `sudo`) Apple Silicon Hardware Telemetry**
   - Dynamically inspects `IODeviceTree:/cpus` to split **Performance Cores (P-Core)** and **Efficiency Cores (E-Core)**.
   - Queries `IOAccelerator` (`AGXAccelerator`) for **GPU Device, Renderer, Tiler utilization, and Unified VRAM usage**.
   - Reads **CPU/GPU/SSD Temperatures (°C)**, **Dual Fan Speeds (RPM)**, and **Real-Time System Power (`⚡ W`)** via 80-byte aligned `AppleSMC` and `IOHIDEventSystem` — without ever asking for an admin password.
3. **🌐 Built-in Multi-Language Support (8 Common Languages)**
   - Automatically matches your macOS system locale or switches live from the Menu Bar without restarting:
   - **简体中文** · **繁體中文** · **English** · **日本語** · **한국어** · **Español** · **Français** · **Deutsch**.
4. **🌓 Adaptive Contrast & Zero Jitter**
   - Adjust background opacity from `0% Pure Transparent (with glowing text drop-shadow)` up to `88% Smoked Frosted Glass`.
   - Uses `SF Mono` (`.monospacedDigit()`) across all metrics so numbers never jitter horizontally.
5. **🛡️ Zero Memory Leak & Zero Sleep Drain**
   - Strictly calls `vm_deallocate` after every Mach `host_processor_info` call.
   - Uses native `<libproc.h>` on a 3s low-frequency cadence for Top Processes (never spawns `/bin/ps`).
   - Automatically pauses timers when the screen sleeps (`screensDidSleep`).

---

## 🚀 Quick Start (Build & Run)

```bash
# 1. Clone repository
git clone https://github.com/wuliu21/MacPulse.git
cd MacPulse

# 2. Build Release binary & package signed MacPulse.app
./build_app.sh

# 3. Launch
open MacPulse.app

# (Optional) Install to /Applications
cp -R MacPulse.app /Applications/
```

---

## ⌨️ Controls & Shortcuts

| Action | Description |
| :--- | :--- |
| **Hold `⌥ Option` + Left Drag** | Temporarily unlock click-through and drag the HUD anywhere on screen |
| **Click Menu Bar Icon** | Open control menu (switch Dashboard / Compact Pill, Opacity, Window Layer, Modules, **Language**) |
| **`⌘H` (in Menu)** | Show / Hide Floating HUD |
| **`⌘L` (in Menu)** | Toggle Click-Through Lock |
| **`⌘R` (in Menu)** | Reset HUD position to top-right corner |
| **`⌘Q` (in Menu)** | Quit MacPulse |

---

## 📄 License

Released under the [MIT License](LICENSE).
