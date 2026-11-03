<div align="center">

<img src="../assets/banner.svg" alt="MacPulse HUD Banner" width="100%" />

<br/>

# ⚡ MacPulse HUD

**Moniteur de Performance Flottant et Transparent pour macOS en Swift 6 Natif**  
*100% Clics Traversants · Maintenir `⌥ Option` pour Déplacer · Télémétrie Apple Silicon CPU/GPU/Temp/Ventilateur/Puissance sans `sudo`*

[**🇨🇳 简体中文**](../README.md) | [**🇭🇰 繁體中文**](README_ZH-HANT.md) | [**🇺🇸 English**](../README_EN.md) | [**🇯🇵 日本語**](README_JA.md) | [**🇰🇷 한국어**](README_KO.md) | [**🇪🇸 Español**](README_ES.md) | **🇫🇷 Français** | [**🇩🇪 Deutsch**](README_DE.md)

</div>

---

## ✨ Fonctionnalités Clés

1. **🎯 100% Clics Traversants + Déplacement via `⌥ Option`** : Vos clics traversent le HUD sans jamais gêner votre travail (`ignoresMouseEvents = true`). Maintenez la touche `⌥ Option` enfoncée pour faire glisser le panneau où vous voulez.
2. **⚡ Télémétrie Apple Silicon sans `sudo`** : Répartition des cœurs de performance (P-Core) et d'efficacité (E-Core), charge GPU et VRAM unifiée via `IOAccelerator`, pression mémoire et Swap, ainsi que température CPU/GPU/SSD (°C), vitesse des ventilateurs (RPM) et consommation électrique (`⚡ W`) via `AppleSMC` et `IOHIDEventSystem`.
3. **🌐 8 Langues Intégrées en Temps Réel** : Basculez instantanément depuis la barre des menus (Français, English, 简体中文, 繁體中文, 日本語, 한국어, Español, Deutsch).
4. **🌓 Double Mode Visuel & Opacité Réglable** : Tableau de bord complet (Dashboard) ou capsule compacte (Compact Pill), avec opacité réglable de `0%` à `88%`.

---

## 🚀 Démarrage Rapide

```bash
git clone https://github.com/wuliu21/MacPulse.git
cd MacPulse
./build_app.sh
open MacPulse.app
```
