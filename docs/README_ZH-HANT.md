<div align="center">

<img src="../assets/banner.svg" alt="MacPulse HUD Banner" width="100%" />

<br/>

# ⚡ MacPulse HUD

**原生 Swift 6 打造的 macOS 極客桌面透明懸浮效能監控工具**  
*100% 滑鼠穿透 · 按住 `⌥ Option` 隨手拖曳 · 免 `sudo` 直讀 Apple Silicon CPU/GPU/溫度/風扇/功耗*

[**🇨🇳 简体中文**](../README.md) | **🇭🇰 繁體中文** | [**🇺🇸 English**](../README_EN.md) | [**🇯🇵 日本語**](README_JA.md) | [**🇰🇷 한국어**](README_KO.md) | [**🇪🇸 Español**](README_ES.md) | [**🇫🇷 Français**](README_FR.md) | [**🇩🇪 Deutsch**](README_DE.md)

</div>

---

## ✨ 核心亮點

1. **🎯 100% 滑鼠穿透 + `⌥ Option` 鍵即時拖曳**：預設開啟滑鼠穿透（`ignoresMouseEvents = true`），完全不遮擋底層視窗點擊；按住 `⌥ Option` 鍵即可隨時拖曳移動位置，放開自動儲存座標。
2. **⚡ 免 `sudo` 密碼的 Apple Silicon 硬體級採集**：自動識別 P-Core（效能核）與 E-Core（節能核）、`IOAccelerator` GPU 負載與顯存、記憶體壓力與 Swap，並透過 80 位元組對齊的 `AppleSMC` 與 `IOHIDEventSystem` 讀取 CPU/GPU/SSD 溫度、雙風扇轉速與整機即時功耗 (`⚡ W`)。
3. **🌐 內建 8 種常用語言即時切換**：支援跟隨系統或從選單列即時切換（简体中文 / 繁體中文 / English / 日本語 / 한국어 / Español / Français / Deutsch）。
4. **🌓 全透明與磨砂自適應對比度**：支援 `0%` 全透明（帶發光文字陰影）至 `88%` 燻黑毛玻璃自由調節，全量採用 `SF Mono` 等寬數字防止跳動。
5. **🛡️ 零記憶體洩漏與休眠零功耗**：嚴格執行 Mach `vm_deallocate`，Top 程序採用原生 `<libproc.h>` 每 3 秒低頻採樣，螢幕休眠時 100% 自動停表。

---

## 🚀 快速開始

```bash
git clone https://github.com/wuliu21/MacPulse.git
cd MacPulse
./build_app.sh
open MacPulse.app
```
