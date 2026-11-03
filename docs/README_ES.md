<div align="center">

<img src="../assets/banner.svg" alt="MacPulse HUD Banner" width="100%" />

<br/>

# ⚡ MacPulse HUD

**Monitor de Rendimiento Flotante y Transparente para macOS en Swift 6 Nativo**  
*100% Clics Traversantes · Mantén `⌥ Option` para Arrastrar · Telemetría Apple Silicon CPU/GPU/Temp/Ventilador/Potencia sin `sudo`*

[**🇨🇳 简体中文**](../README.md) | [**🇭🇰 繁體中文**](README_ZH-HANT.md) | [**🇺🇸 English**](../README_EN.md) | [**🇯🇵 日本語**](README_JA.md) | [**🇰🇷 한국어**](README_KO.md) | **🇪🇸 Español** | [**🇫🇷 Français**](README_FR.md) | [**🇩🇪 Deutsch**](README_DE.md)

</div>

---

## ✨ Características Principales

1. **🎯 100% Clics Traversantes + Arrastrar con `⌥ Option`**: Los clics del ratón pasan directamente a las ventanas inferiores (`ignoresMouseEvents = true`). Mantén pulsada la tecla `⌥ Option` para arrastrar el HUD a cualquier lugar de la pantalla.
2. **⚡ Telemetría Apple Silicon sin `sudo`**: Desglose de núcleos de rendimiento (P-Core) y eficiencia (E-Core), uso de GPU y VRAM mediante `IOAccelerator`, presión de RAM y Swap, además de temperatura de CPU/GPU/SSD (°C), velocidad de ventiladores (RPM) y consumo eléctrico del sistema (`⚡ W`) mediante `AppleSMC` e `IOHIDEventSystem`.
3. **🌐 Soporte Multilingüe en Tiempo Real (8 Idiomas)**: Cambia al instante desde la barra de menú entre Español, English, 简体中文, 繁體中文, 日本語, 한국어, Français y Deutsch.
4. **🌓 Dos Modos Visuales y Opacidad Ajustable**: Alterna entre Panel Completo (Dashboard) y Cápsula Compacta (Compact Pill), con opacidad de `0%` a `88%`.

---

## 🚀 Inicio Rápido

```bash
git clone https://github.com/wuliu21/MacPulse.git
cd MacPulse
./build_app.sh
open MacPulse.app
```
