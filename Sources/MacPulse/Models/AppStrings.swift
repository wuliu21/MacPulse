import Foundation

public enum AppLanguage: String, CaseIterable, Sendable {
    case system = "system"
    case zhHans = "zh-Hans"
    case zhHant = "zh-Hant"
    case en = "en"
    case ja = "ja"
    case ko = "ko"
    case es = "es"
    case fr = "fr"
    case de = "de"

    public var displayName: String {
        switch self {
        case .system: return "🌐 跟随系统 (System)"
        case .zhHans: return "🇨🇳 简体中文"
        case .zhHant: return "🇭🇰 繁體中文"
        case .en:     return "🇺🇸 English"
        case .ja:     return "🇯🇵 日本語"
        case .ko:     return "🇰🇷 한국어"
        case .es:     return "🇪🇸 Español"
        case .fr:     return "🇫🇷 Français"
        case .de:     return "🇩🇪 Deutsch"
        }
    }

    public var resolved: AppLanguage {
        if self != .system { return self }
        let preferred = (Locale.preferredLanguages.first ?? "en").lowercased()
        if preferred.hasPrefix("zh-hant") || preferred.hasPrefix("zh-tw") || preferred.hasPrefix("zh-hk") {
            return .zhHant
        } else if preferred.hasPrefix("zh") {
            return .zhHans
        } else if preferred.hasPrefix("ja") {
            return .ja
        } else if preferred.hasPrefix("ko") {
            return .ko
        } else if preferred.hasPrefix("es") {
            return .es
        } else if preferred.hasPrefix("fr") {
            return .fr
        } else if preferred.hasPrefix("de") {
            return .de
        } else {
            return .en
        }
    }
}

public struct L10n: Sendable {
    // HUD Header
    public let lockClickThroughBadge: String
    public let unlockedDraggableBadge: String

    // CPU & GPU
    public let pCoreShort: String
    public let eCoreShort: String
    public let vramPrefix: String
    public let renderShort: String
    public let tilerShort: String

    // Memory
    public let memoryTitle: String
    public let pressurePrefix: String
    public let pressureNormal: String
    public let pressureWarning: String
    public let pressureCritical: String
    public let wiredPrefix: String
    public let compressedPrefix: String

    // Thermal & Fan
    public let fanPassive: String
    public let fanSilentZeroFormat: String // e.g. "Fan(%d): 0 RPM (Silent)"
    public let fanActivePrefix: String

    // Network & Disk
    public let networkTitle: String
    public let diskFreeFormat: String // e.g. "Disk (%.0fG Free)"

    // Top Processes
    public let topProcessesTitle: String
    public let samplingPlaceholder: String

    // Menu Bar
    public let menuAppTitle: String
    public let menuShowHUD: String
    public let menuHideHUD: String
    public let menuLockClickThrough: String
    public let menuResetPosition: String

    public let menuSectionViewMode: String
    public let modeDashboard: String
    public let modeCompact: String

    public let menuSectionWindowLayer: String
    public let layerFloatingTop: String
    public let layerDesktopWallpaper: String

    public let menuOpacityTitleFormat: String
    public let opacityPreset0: String
    public let opacityPreset22: String
    public let opacityPreset42: String
    public let opacityPreset65: String
    public let opacityPreset88: String

    public let menuModulesTitle: String
    public let modulePerCoreBars: String
    public let moduleThermalFan: String
    public let moduleNetworkDisk: String
    public let moduleTopProcesses: String
    public let moduleMenuBarText: String

    public let menuRefreshTitleFormat: String
    public let refresh05s: String
    public let refresh10s: String
    public let refresh20s: String

    public let menuLanguageTitle: String
    public let menuQuit: String

    public func pressureText(_ state: MemoryPressureState) -> String {
        switch state {
        case .normal: return pressureNormal
        case .warning: return pressureWarning
        case .critical: return pressureCritical
        }
    }

    public static func forLanguage(_ lang: AppLanguage) -> L10n {
        switch lang.resolved {
        case .zhHans:
            return L10n(
                lockClickThroughBadge: "🔒穿透 · ⌥拖拽",
                unlockedDraggableBadge: "🔓可拖拽移动",
                pCoreShort: "P核",
                eCoreShort: "E核",
                vramPrefix: "显存",
                renderShort: "渲染",
                tilerShort: "Tiler",
                memoryTitle: "内存",
                pressurePrefix: "压力:",
                pressureNormal: "正常",
                pressureWarning: "偏高",
                pressureCritical: "吃紧",
                wiredPrefix: "联动:",
                compressedPrefix: "压缩:",
                fanPassive: "风扇: 无风扇/被动散热",
                fanSilentZeroFormat: "风扇(%d): 0 RPM (静音停转)",
                fanActivePrefix: "风扇",
                networkTitle: "网络",
                diskFreeFormat: "磁盘 (余%.0fG)",
                topProcessesTitle: "TOP 进程 (3s)",
                samplingPlaceholder: "采样计算中...",
                menuAppTitle: "MacPulse 桌面性能监控",
                menuShowHUD: "显示桌面悬浮窗",
                menuHideHUD: "隐藏桌面悬浮窗",
                menuLockClickThrough: "锁定鼠标穿透 (按住 ⌥ 可临时拖拽)",
                menuResetPosition: "重置悬浮窗到右上角默认位置",
                menuSectionViewMode: "视图模式",
                modeDashboard: "完整极客仪表盘 (Dashboard)",
                modeCompact: "极简胶囊状态条 (Compact Pill)",
                menuSectionWindowLayer: "桌面层级",
                layerFloatingTop: "全局置顶悬浮 (Always on Top)",
                layerDesktopWallpaper: "嵌入桌面壁纸层 (Desktop Layer)",
                menuOpacityTitleFormat: "背景透明度 (当前 %.0f%%)",
                opacityPreset0: "0% · 纯全透明 (仅发光文字)",
                opacityPreset22: "22% · 极高通透玻璃",
                opacityPreset42: "42% · 标准极客熏黑 (推荐)",
                opacityPreset65: "65% · 深邃磨砂卡片",
                opacityPreset88: "88% · 高对比不透明",
                menuModulesTitle: "显示指标模块开关",
                modulePerCoreBars: "CPU 单核负载柱状条",
                moduleThermalFan: "风扇转速与 SSD 温度模块",
                moduleNetworkDisk: "实时网速与磁盘读写模块",
                moduleTopProcesses: "Top 3 高占用进程模块",
                moduleMenuBarText: "顶部菜单栏显示 CPU/GPU 百分比",
                menuRefreshTitleFormat: "采样频率 (%.1f 秒)",
                refresh05s: "0.5 秒 (极速刷新)",
                refresh10s: "1.0 秒 (标准平衡 · 推荐)",
                refresh20s: "2.0 秒 (省电低功耗)",
                menuLanguageTitle: "语言 / Language",
                menuQuit: "退出 MacPulse"
            )

        case .zhHant:
            return L10n(
                lockClickThroughBadge: "🔒穿透 · ⌥拖曳",
                unlockedDraggableBadge: "🔓可拖曳移動",
                pCoreShort: "P核",
                eCoreShort: "E核",
                vramPrefix: "顯存",
                renderShort: "渲染",
                tilerShort: "Tiler",
                memoryTitle: "記憶體",
                pressurePrefix: "壓力:",
                pressureNormal: "正常",
                pressureWarning: "偏高",
                pressureCritical: "吃緊",
                wiredPrefix: "聯動:",
                compressedPrefix: "壓縮:",
                fanPassive: "風扇: 無風扇/被動散熱",
                fanSilentZeroFormat: "風扇(%d): 0 RPM (靜音停轉)",
                fanActivePrefix: "風扇",
                networkTitle: "網路",
                diskFreeFormat: "磁碟 (餘%.0fG)",
                topProcessesTitle: "TOP 程序 (3s)",
                samplingPlaceholder: "採樣計算中...",
                menuAppTitle: "MacPulse 桌面效能監控",
                menuShowHUD: "顯示桌面懸浮窗",
                menuHideHUD: "隱藏桌面懸浮窗",
                menuLockClickThrough: "鎖定滑鼠穿透 (按住 ⌥ 可臨時拖曳)",
                menuResetPosition: "重置懸浮窗到右上角預設位置",
                menuSectionViewMode: "檢視模式",
                modeDashboard: "完整極客儀表板 (Dashboard)",
                modeCompact: "極簡膠囊狀態列 (Compact Pill)",
                menuSectionWindowLayer: "桌面層級",
                layerFloatingTop: "全域置頂懸浮 (Always on Top)",
                layerDesktopWallpaper: "嵌入桌面桌布層 (Desktop Layer)",
                menuOpacityTitleFormat: "背景透明度 (目前 %.0f%%)",
                opacityPreset0: "0% · 純全透明 (僅發光文字)",
                opacityPreset22: "22% · 極高通透玻璃",
                opacityPreset42: "42% · 標準極客燻黑 (推薦)",
                opacityPreset65: "65% · 深邃磨砂卡片",
                opacityPreset88: "88% · 高對比不透明",
                menuModulesTitle: "顯示指標模組開關",
                modulePerCoreBars: "CPU 單核負載柱狀條",
                moduleThermalFan: "風扇轉速與 SSD 溫度模組",
                moduleNetworkDisk: "即時網速與磁碟讀寫模組",
                moduleTopProcesses: "Top 3 高佔用程序模組",
                moduleMenuBarText: "頂部選單列顯示 CPU/GPU 百分比",
                menuRefreshTitleFormat: "採樣頻率 (%.1f 秒)",
                refresh05s: "0.5 秒 (極速重新整理)",
                refresh10s: "1.0 秒 (標準平衡 · 推薦)",
                refresh20s: "2.0 秒 (省電低功耗)",
                menuLanguageTitle: "語言 / Language",
                menuQuit: "結束 MacPulse"
            )

        case .ja:
            return L10n(
                lockClickThroughBadge: "🔒透過 · ⌥移動",
                unlockedDraggableBadge: "🔓ドラッグ移動中",
                pCoreShort: "Pコア",
                eCoreShort: "Eコア",
                vramPrefix: "VRAM",
                renderShort: "Render",
                tilerShort: "Tiler",
                memoryTitle: "メモリ",
                pressurePrefix: "負荷:",
                pressureNormal: "正常",
                pressureWarning: "注意",
                pressureCritical: "逼迫",
                wiredPrefix: "固定:",
                compressedPrefix: "圧縮:",
                fanPassive: "ファン: ファンレス",
                fanSilentZeroFormat: "ファン(%d): 0 RPM (静音停止)",
                fanActivePrefix: "ファン",
                networkTitle: "通信",
                diskFreeFormat: "SSD (残%.0fG)",
                topProcessesTitle: "TOP プロセス (3s)",
                samplingPlaceholder: "計測中...",
                menuAppTitle: "MacPulse パフォーマンス監視",
                menuShowHUD: "フローティングHUDを表示",
                menuHideHUD: "フローティングHUDを隠す",
                menuLockClickThrough: "マウス透過をロック (⌥ キーで移動)",
                menuResetPosition: "右上隅の初期位置にリセット",
                menuSectionViewMode: "表示モード",
                modeDashboard: "ダッシュボード (Dashboard)",
                modeCompact: "コンパクトピル (Compact Pill)",
                menuSectionWindowLayer: "ウィンドウ階層",
                layerFloatingTop: "常に最前面に表示 (Always on Top)",
                layerDesktopWallpaper: "デスクトップ背景層 (Desktop Layer)",
                menuOpacityTitleFormat: "背景の不透明度 (現在 %.0f%%)",
                opacityPreset0: "0% · 完全透明 (発光テキストのみ)",
                opacityPreset22: "22% · クリアガラス",
                opacityPreset42: "42% · スモークガラス (推奨)",
                opacityPreset65: "65% · ダークフロスト",
                opacityPreset88: "88% · 高コントラスト",
                menuModulesTitle: "表示モジュールの切り替え",
                modulePerCoreBars: "CPU コア別負荷バー",
                moduleThermalFan: "ファン回転数とSSD温度",
                moduleNetworkDisk: "ネットワーク速度とディスクI/O",
                moduleTopProcesses: "上位3プロセス (CPU負荷)",
                moduleMenuBarText: "メニューバーにCPU/GPU%を表示",
                menuRefreshTitleFormat: "更新間隔 (%.1f 秒)",
                refresh05s: "0.5 秒 (高速)",
                refresh10s: "1.0 秒 (標準 · 推奨)",
                refresh20s: "2.0 秒 (省電力)",
                menuLanguageTitle: "言語 / Language",
                menuQuit: "MacPulse を終了"
            )

        case .ko:
            return L10n(
                lockClickThroughBadge: "🔒투과 · ⌥드래그",
                unlockedDraggableBadge: "🔓드래그 이동 가능",
                pCoreShort: "P코어",
                eCoreShort: "E코어",
                vramPrefix: "VRAM",
                renderShort: "렌더",
                tilerShort: "Tiler",
                memoryTitle: "메모리",
                pressurePrefix: "압력:",
                pressureNormal: "정상",
                pressureWarning: "주의",
                pressureCritical: "위험",
                wiredPrefix: "고정:",
                compressedPrefix: "압축:",
                fanPassive: "팬: 팬리스 (수동 냉각)",
                fanSilentZeroFormat: "팬(%d): 0 RPM (무소음 정지)",
                fanActivePrefix: "팬",
                networkTitle: "네트워크",
                diskFreeFormat: "디스크 (여유 %.0fG)",
                topProcessesTitle: "상위 프로세스 (3s)",
                samplingPlaceholder: "측정 중...",
                menuAppTitle: "MacPulse 시스템 모니터",
                menuShowHUD: "플로팅 HUD 표시",
                menuHideHUD: "플로팅 HUD 숨기기",
                menuLockClickThrough: "마우스 투과 잠금 (⌥ 키로 드래그)",
                menuResetPosition: "우측 상단 기본 위치로 초기화",
                menuSectionViewMode: "화면 모드",
                modeDashboard: "전체 대시보드 (Dashboard)",
                modeCompact: "컴팩트 캡슐 바 (Compact Pill)",
                menuSectionWindowLayer: "윈도우 레이어",
                layerFloatingTop: "항상 위에 표시 (Always on Top)",
                layerDesktopWallpaper: "바탕화면 배경 레이어 (Desktop Layer)",
                menuOpacityTitleFormat: "배경 불투명도 (현재 %.0f%%)",
                opacityPreset0: "0% · 완전 투명 (텍스트만 표시)",
                opacityPreset22: "22% · 라이트 글래스",
                opacityPreset42: "42% · 스모크 글래스 (권장)",
                opacityPreset65: "65% · 다크 프로스트",
                opacityPreset88: "88% · 고대비 불투명",
                menuModulesTitle: "모듈 표시 설정",
                modulePerCoreBars: "CPU 코어별 사용량 바",
                moduleThermalFan: "팬 속도 및 SSD 온도",
                moduleNetworkDisk: "네트워크 및 디스크 I/O",
                moduleTopProcesses: "상위 3개 프로세스",
                moduleMenuBarText: "메뉴 막대에 CPU/GPU % 표시",
                menuRefreshTitleFormat: "갱신 주기 (%.1f초)",
                refresh05s: "0.5초 (고속)",
                refresh10s: "1.0초 (표준 · 권장)",
                refresh20s: "2.0초 (절전)",
                menuLanguageTitle: "언어 / Language",
                menuQuit: "MacPulse 종료"
            )

        case .es:
            return L10n(
                lockClickThroughBadge: "🔒Pasar · ⌥Mover",
                unlockedDraggableBadge: "🔓Arrastrable",
                pCoreShort: "Núc-P",
                eCoreShort: "Núc-E",
                vramPrefix: "VRAM",
                renderShort: "Render",
                tilerShort: "Tiler",
                memoryTitle: "RAM",
                pressurePrefix: "Presión:",
                pressureNormal: "Normal",
                pressureWarning: "Alta",
                pressureCritical: "Crítica",
                wiredPrefix: "Fija:",
                compressedPrefix: "Comp:",
                fanPassive: "Ventilador: Pasivo",
                fanSilentZeroFormat: "Vent.(%d): 0 RPM (Silencio)",
                fanActivePrefix: "Vent.",
                networkTitle: "Red",
                diskFreeFormat: "Disco (%.0fG Lib)",
                topProcessesTitle: "TOP PROCESOS (3s)",
                samplingPlaceholder: "Calculando...",
                menuAppTitle: "MacPulse Monitor de Sistema",
                menuShowHUD: "Mostrar HUD Flotante",
                menuHideHUD: "Ocultar HUD Flotante",
                menuLockClickThrough: "Bloquear Clics (Mantén ⌥ para mover)",
                menuResetPosition: "Restablecer posición arriba a la derecha",
                menuSectionViewMode: "Modo de Vista",
                modeDashboard: "Panel Completo (Dashboard)",
                modeCompact: "Cápsula Compacta (Compact Pill)",
                menuSectionWindowLayer: "Capa de Ventana",
                layerFloatingTop: "Siempre Visible (Always on Top)",
                layerDesktopWallpaper: "Fondo de Escritorio (Desktop Layer)",
                menuOpacityTitleFormat: "Opacidad de Fondo (%.0f%%)",
                opacityPreset0: "0% · Transparente Total",
                opacityPreset22: "22% · Cristal Ligero",
                opacityPreset42: "42% · Cristal Ahumado (Rec.)",
                opacityPreset65: "65% · Esmerilado Oscuro",
                opacityPreset88: "88% · Alto Contraste",
                menuModulesTitle: "Módulos Visibles",
                modulePerCoreBars: "Barras por Núcleo de CPU",
                moduleThermalFan: "Ventiladores y Temp. SSD",
                moduleNetworkDisk: "Red y Lectura/Escritura de Disco",
                moduleTopProcesses: "Top 3 Procesos de CPU",
                moduleMenuBarText: "Mostrar % CPU/GPU en Barra de Menú",
                menuRefreshTitleFormat: "Frecuencia de Muestreo (%.1f s)",
                refresh05s: "0.5 s (Ultra rápido)",
                refresh10s: "1.0 s (Estándar · Rec.)",
                refresh20s: "2.0 s (Ahorro de energía)",
                menuLanguageTitle: "Idioma / Language",
                menuQuit: "Salir de MacPulse"
            )

        case .fr:
            return L10n(
                lockClickThroughBadge: "🔒Traverser · ⌥Dépl.",
                unlockedDraggableBadge: "🔓Déplaçable",
                pCoreShort: "CœurP",
                eCoreShort: "CœurE",
                vramPrefix: "VRAM",
                renderShort: "Rendu",
                tilerShort: "Tiler",
                memoryTitle: "RAM",
                pressurePrefix: "Pression:",
                pressureNormal: "Normale",
                pressureWarning: "Élevée",
                pressureCritical: "Critique",
                wiredPrefix: "Résid:",
                compressedPrefix: "Comp:",
                fanPassive: "Ventilateur : Passif",
                fanSilentZeroFormat: "Vent.(%d) : 0 RPM (Silencieux)",
                fanActivePrefix: "Vent.",
                networkTitle: "Réseau",
                diskFreeFormat: "Disque (%.0fG Lib)",
                topProcessesTitle: "TOP PROCESSUS (3s)",
                samplingPlaceholder: "Mesure en cours...",
                menuAppTitle: "MacPulse Moniteur Système",
                menuShowHUD: "Afficher le HUD flottant",
                menuHideHUD: "Masquer le HUD flottant",
                menuLockClickThrough: "Clics traversants (Maintenir ⌥ pour déplacer)",
                menuResetPosition: "Réinitialiser la position en haut à droite",
                menuSectionViewMode: "Mode d'affichage",
                modeDashboard: "Tableau de bord (Dashboard)",
                modeCompact: "Capsule compacte (Compact Pill)",
                menuSectionWindowLayer: "Niveau de fenêtre",
                layerFloatingTop: "Toujours au premier plan",
                layerDesktopWallpaper: "Niveau du fond d'écran",
                menuOpacityTitleFormat: "Opacité du fond (%.0f%%)",
                opacityPreset0: "0% · Totalement transparent",
                opacityPreset22: "22% · Verre clair",
                opacityPreset42: "42% · Verre fumé (Recommandé)",
                opacityPreset65: "65% · Dépoli sombre",
                opacityPreset88: "88% · Contraste élevé",
                menuModulesTitle: "Modules affichés",
                modulePerCoreBars: "Barres CPU par cœur",
                moduleThermalFan: "Ventilateurs et température SSD",
                moduleNetworkDisk: "Vitesse réseau et E/S disque",
                moduleTopProcesses: "Top 3 des processus CPU",
                moduleMenuBarText: "Afficher % CPU/GPU dans la barre des menus",
                menuRefreshTitleFormat: "Fréquence d'actualisation (%.1f s)",
                refresh05s: "0.5 s (Rapide)",
                refresh10s: "1.0 s (Standard · Recommandé)",
                refresh20s: "2.0 s (Éco)",
                menuLanguageTitle: "Langue / Language",
                menuQuit: "Quitter MacPulse"
            )

        case .de:
            return L10n(
                lockClickThroughBadge: "🔒Klick-Durch · ⌥Ziehen",
                unlockedDraggableBadge: "🔓Verschiebbar",
                pCoreShort: "P-Kern",
                eCoreShort: "E-Kern",
                vramPrefix: "VRAM",
                renderShort: "Render",
                tilerShort: "Tiler",
                memoryTitle: "RAM",
                pressurePrefix: "Druck:",
                pressureNormal: "Normal",
                pressureWarning: "Erhöht",
                pressureCritical: "Kritisch",
                wiredPrefix: "Reserviert:",
                compressedPrefix: "Komp:",
                fanPassive: "Lüfter: Passiv / Lüfterlos",
                fanSilentZeroFormat: "Lüfter(%d): 0 RPM (Lautlos)",
                fanActivePrefix: "Lüfter",
                networkTitle: "Netz",
                diskFreeFormat: "SSD (%.0fG frei)",
                topProcessesTitle: "TOP-PROZESSE (3s)",
                samplingPlaceholder: "Berechne...",
                menuAppTitle: "MacPulse Systemmonitor",
                menuShowHUD: "Schwebendes HUD einblenden",
                menuHideHUD: "Schwebendes HUD ausblenden",
                menuLockClickThrough: "Klick-Durchlass sperren (⌥ halten zum Ziehen)",
                menuResetPosition: "Position oben rechts zurücksetzen",
                menuSectionViewMode: "Ansichtsmodus",
                modeDashboard: "Vollständiges Dashboard",
                modeCompact: "Kompakte Statuspille",
                menuSectionWindowLayer: "Fensterebene",
                layerFloatingTop: "Immer im Vordergrund (Always on Top)",
                layerDesktopWallpaper: "Schreibtisch-Hintergrundebene",
                menuOpacityTitleFormat: "Hintergrund-Deckkraft (%.0f%%)",
                opacityPreset0: "0% · Vollständig transparent",
                opacityPreset22: "22% · Klares Glas",
                opacityPreset42: "42% · Rauchglas (Empfohlen)",
                opacityPreset65: "65% · Dunkles Milchglas",
                opacityPreset88: "88% · Hoher Kontrast",
                menuModulesTitle: "Angezeigte Module",
                modulePerCoreBars: "CPU-Einzelkern-Balken",
                moduleThermalFan: "Lüfterdrehzahl & SSD-Temperatur",
                moduleNetworkDisk: "Netzwerk & Festplatten-I/O",
                moduleTopProcesses: "Top 3 CPU-Prozesse",
                moduleMenuBarText: "CPU/GPU % in Menüleiste anzeigen",
                menuRefreshTitleFormat: "Abtastrate (%.1f Sek.)",
                refresh05s: "0.5 Sek. (Schnell)",
                refresh10s: "1.0 Sek. (Standard · Empfohlen)",
                refresh20s: "2.0 Sek. (Energiesparend)",
                menuLanguageTitle: "Sprache / Language",
                menuQuit: "MacPulse beenden"
            )

        default: // .en
            return L10n(
                lockClickThroughBadge: "🔒Pass · ⌥Drag",
                unlockedDraggableBadge: "🔓Draggable",
                pCoreShort: "P-Core",
                eCoreShort: "E-Core",
                vramPrefix: "VRAM",
                renderShort: "Render",
                tilerShort: "Tiler",
                memoryTitle: "MEM",
                pressurePrefix: "Press:",
                pressureNormal: "Normal",
                pressureWarning: "Warn",
                pressureCritical: "Crit",
                wiredPrefix: "Wired:",
                compressedPrefix: "Comp:",
                fanPassive: "Fan: Fanless / Passive",
                fanSilentZeroFormat: "Fan(%d): 0 RPM (Silent)",
                fanActivePrefix: "Fan",
                networkTitle: "NET",
                diskFreeFormat: "Disk (%.0fG Free)",
                topProcessesTitle: "TOP PROCESSES (3s)",
                samplingPlaceholder: "Sampling...",
                menuAppTitle: "MacPulse Performance Monitor",
                menuShowHUD: "Show Floating HUD",
                menuHideHUD: "Hide Floating HUD",
                menuLockClickThrough: "Lock Click-Through (Hold ⌥ to Drag)",
                menuResetPosition: "Reset Position to Top-Right",
                menuSectionViewMode: "Display Mode",
                modeDashboard: "Full Geek Dashboard",
                modeCompact: "Compact Status Pill",
                menuSectionWindowLayer: "Window Layer",
                layerFloatingTop: "Always on Top (Floating HUD)",
                layerDesktopWallpaper: "Desktop Wallpaper Layer",
                menuOpacityTitleFormat: "Background Opacity (%.0f%%)",
                opacityPreset0: "0% · Pure Transparent (Glow Text)",
                opacityPreset22: "22% · Light Clear Glass",
                opacityPreset42: "42% · Smoked HUD Glass (Recommended)",
                opacityPreset65: "65% · Deep Frosted Card",
                opacityPreset88: "88% · High-Contrast Opaque",
                menuModulesTitle: "Visible Modules",
                modulePerCoreBars: "Per-Core CPU Load Bars",
                moduleThermalFan: "Fan Speeds & SSD Temperature",
                moduleNetworkDisk: "Network & Disk Read/Write IO",
                moduleTopProcesses: "Top 3 CPU Processes",
                moduleMenuBarText: "Show Live CPU/GPU % in Menu Bar",
                menuRefreshTitleFormat: "Refresh Interval (%.1fs)",
                refresh05s: "0.5s (High Refresh)",
                refresh10s: "1.0s (Balanced · Recommended)",
                refresh20s: "2.0s (Eco Mode)",
                menuLanguageTitle: "Language / 语言",
                menuQuit: "Quit MacPulse"
            )
        }
    }
}
