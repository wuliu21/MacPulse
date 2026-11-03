<div align="center">

<img src="../assets/banner.svg" alt="MacPulse HUD Banner" width="100%" />

<br/>

# ⚡ MacPulse HUD

**Nativer Swift 6 macOS-Desktop-Systemmonitor mit transparentem Floating-HUD**  
*100% Klick-Durchlass · `⌥ Option` halten zum Verschieben · Rootless Apple Silicon CPU/GPU/Temp/Lüfter/Leistung ohne `sudo`*

[**🇨🇳 简体中文**](../README.md) | [**🇭🇰 繁體中文**](README_ZH-HANT.md) | [**🇺🇸 English**](../README_EN.md) | [**🇯🇵 日本語**](README_JA.md) | [**🇰🇷 한국어**](README_KO.md) | [**🇪🇸 Español**](README_ES.md) | [**🇫🇷 Français**](README_FR.md) | **🇩🇪 Deutsch**

</div>

---

## ✨ Hauptmerkmale

1. **🎯 100% Klick-Durchlass + Verschieben mit `⌥ Option`**: Mausklicks gehen vollständig durch das HUD hindurch (`ignoresMouseEvents = true`). Halten Sie einfach die `⌥ Option`-Taste gedrückt, um das Fenster an eine beliebige Stelle zu ziehen.
2. **⚡ Apple Silicon Hardware-Telemetrie ohne `sudo`**: Separate Auslastung für Performance-Kerne (P-Core) und Effizienz-Kerne (E-Core), GPU-Auslastung und VRAM über `IOAccelerator`, Speicherdruck und Swap sowie CPU/GPU/SSD-Temperaturen (°C), Lüfterdrehzahlen (RPM) und Systemleistung (`⚡ W`) über `AppleSMC` und `IOHIDEventSystem`.
3. **🌐 8 Integrierte Sprachen mit Live-Umschaltung**: Sofortiger Sprachwechsel über die Menüleiste ohne Neustart (Deutsch, English, 简体中文, 繁體中文, 日本語, 한국어, Español, Français).
4. **🌓 Zwei Ansichtsmodi & Einstellbare Deckkraft**: Vollständiges Dashboard oder kompakte Statuspille, mit einstellbarer Deckkraft von `0%` bis `88%`.

---

## 🚀 Schnellstart

```bash
git clone https://github.com/wuliu21/MacPulse.git
cd MacPulse
./build_app.sh
open MacPulse.app
```
