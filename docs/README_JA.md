<div align="center">

<img src="../assets/banner.svg" alt="MacPulse HUD Banner" width="100%" />

<br/>

# ⚡ MacPulse HUD

**ネイティブ Swift 6 製の macOS デスクトップ透過フローティング性能モニター**  
*100% マウス透過 · `⌥ Option` キーで自在に移動 · `sudo` 不要で Apple Silicon の CPU/GPU/温度/ファン/電力を直接取得*

[**🇨🇳 简体中文**](../README.md) | [**🇭🇰 繁體中文**](README_ZH-HANT.md) | [**🇺🇸 English**](../README_EN.md) | **🇯🇵 日本語** | [**🇰🇷 한국어**](README_KO.md) | [**🇪🇸 Español**](README_ES.md) | [**🇫🇷 Français**](README_FR.md) | [**🇩🇪 Deutsch**](README_DE.md)

</div>

---

## ✨ 主な特徴

1. **🎯 100% マウス透過 + `⌥ Option` キーでドラッグ移動**：通常時はマウスクリックが完全に背後のウィンドウへ透過（`ignoresMouseEvents = true`）。位置を変えたい時は `⌥ Option` キーを押しながらドラッグするだけで移動でき、離すと自動保存されます。
2. **⚡ `sudo` 不要の Apple Silicon テレメトリ**：Pコア（高性能）/ Eコア（高効率）の個別負荷、`IOAccelerator` による GPU 負荷・VRAM、メモリ圧力・スワップに加え、`AppleSMC` と `IOHIDEventSystem` から CPU/GPU/SSD 温度、デュアルファン回転数 (RPM)、システム全体の消費電力 (`⚡ W`) を管理者パスワードなしで取得します。
3. **🌐 8言語のリアルタイム切り替え**：メニューバーから再起動なしで表示言語を切り替え可能（日本語 / 简体中文 / 繁體中文 / English / 한국어 / Español / Français / Deutsch）。
4. **🌓 ダーク・ライト背景対応の透過コントラスト**：`0%`（完全透明＋発光ドロップシャドウ）から `88%`（スモークガラス）まで調整可能。等幅フォント `SF Mono` により数値変動時のガタつきを防止。
5. **🛡️ メモリリークゼロ & スリープ時ゼロ電力**：Mach `vm_deallocate` を厳密に実行し、上位プロセスはネイティブ `<libproc.h>` で3秒間隔で軽量取得。画面スリープ時はタイマーを完全停止します。

---

## 🚀 クイックスタート

```bash
git clone https://github.com/wuliu21/MacPulse.git
cd MacPulse
./build_app.sh
open MacPulse.app
```
