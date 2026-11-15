# iGet Design System

The iGet design system defines the visual language, typography, color palettes, sizing geometry, and accessibility standards for iGet on macOS 14 and later. It is implemented in `Packages/iGetDesign` and applied across all desktop widgets, WidgetKit extensions, and the application shell.

```
Packages/iGetDesign/
├── Sources/iGetDesign/
│   ├── ThemeTokens.swift          # Core palettes, token contracts, and color initializers
│   └── PersonalizationDesign.swift  # Dynamic palette resolution for light/dark modes
```

---

## 1. Design Philosophy

iGet is built around four core design principles:

1. **Quiet by Design:** Desktop widgets should enhance the workspace without demanding constant attention. Decorative 3D elements, intense neon glows, and aggressive animations are intentionally excluded.
2. **Small but Coherent:** Every widget shares identical structural geometry, padding scales, and typographic hierarchy, regardless of its underlying tool logic.
3. **Matte & Tactile:** Color palettes utilize soft, matte pastel tones with subtle 1 pt borders and natural paper-like surfaces.
4. **Demand-Driven Feedback:** Visual indicators (spinners, graphs, bars) reflect actual demand-driven state with clear distinction between ready, empty, and stale data.

---

## 2. Color Palettes

iGet provides eight curated matte palettes. Each palette defines an intentional harmony between background, surface, text contrast, and active accent tones.

### Curated Palette Matrix

| Palette ID | Name | Background | Surface | Primary Text | Secondary Text | Accent | Recommended Tools |
|---|---|---|---|---|---|---|---|
| `sage` | **Sage** | `#E4F6ED` | `#EFF4EF` | `#1C271E` | `#526755` | `#2F7B60` | Clock, Habits, Contributions |
| `paper` | **Paper** | `#FFF3DF` | `#FAF6F0` | `#2E251E` | `#6E5E53` | `#7C5F47` | Focus timer, Calendar, Notes |
| `lilac` | **Lilac** | `#EDE6FF` | `#F3EEF7` | `#251B2D` | `#5E506B` | `#6D5582` | Tasks, Notes, Music |
| `slate` | **Slate** | `#E8EEF8` | `#EBF0F3` | `#1B2329` | `#4E5C67` | `#3E5367` | System monitor, Launcher, Battery |
| `aurora` | **Aurora** | `#ECE6FF` | `#F8F5FF` | `#302347` | `#74618F` | `#7856D8` | Custom canvas, Brand highlights |
| `peach` | **Peach** | `#FFEBDD` | `#FFF7F0` | `#57382C` | `#926957` | `#C86C47` | Pocket pet, Dice, Tic-tac-toe |
| `sky` | **Sky** | `#E2F2FF` | `#F1FAFF` | `#223E57` | `#527A99` | `#388AC3` | Weather, Water tracker, Breathing |
| `rose` | **Rose** | `#FFE6EF` | `#FFF4F8` | `#542B40` | `#95637C` | `#C65891` | Photo frames, Personal quotes |

### Application Shell & Brand Colors

The application shell uses dark slate and soft lilac neutrals derived from the iGet app icon:

- **Brand Accent:** `#7755D8` (`BrandTheme.accent`)
- **Light Window Background:** `#F8F6FD`
- **Light Sidebar Background:** `#EEE9FA`
- **Light Surface Card:** `#FFFFFF`
- **Dark Window Background:** `#151420`
- **Dark Sidebar Background:** `#201D31`
- **Dark Surface Card:** `#252135`

---

## 3. Geometry & Sizing Standards

All desktop widgets adhere to strict standard dimensions to ensure modular grid alignment on macOS desktops.

### Widget Sizing Scale

| Size Tier | Width | Height | Aspect Ratio | Primary Use Case |
|---|---|---|---|---|
| **Small** | `180 pt` | `180 pt` | 1:1 | Glanceable stats (Clock, Battery, Weather, Habits, Mini Focus) |
| **Medium** | `340 pt` | `180 pt` | ~1.89:1 | Horizontal lists & dual cards (Tasks, Notes, System sparkline) |
| **Large** | `340 pt` | `340 pt` | 1:1 | Deep interaction & layouts (Tic-tac-toe, Canvas, Photo gallery) |

### Corner Radius System

- **Desktop Widget Tiles:** `18 pt` (`DesktopTile.cornerRadius`)
- **Surface Cards & Panels:** `14 pt` (`ThemePalette.cornerRadius`)
- **Inner Preview Cards:** `10 pt`
- **Interactive Controls & Buttons:** `6 pt` to `8 pt`
- **Pill Badges & Swatches:** `Capsule` or `Circle`

### Borders & Elevation

- **Tile Outline:** `1 pt` stroke using `Color.primary.opacity(0.08)`
- **Active Selection Border:** `2 pt` stroke using `Color.accentColor.opacity(0.6)`
- **Shadows:** Low-opacity, diffused elevation (`color: .black.opacity(0.06)`, `radius: 8`, `y: 3`). Heavy drop shadows and multi-layered glow effects are strictly prohibited.

---

## 4. Typography Hierarchy

iGet uses Apple's native San Francisco system font, pairing standard proportional text with rounded monospaced digits for high numerical legibility.

| Level | Size | Weight | Tracking | Design | Semantics |
|---|---|---|---|---|---|
| **Eyebrow** | `10 pt` | Semibold | `+1.4` to `+1.8` | Default | Section tags, uppercase categories |
| **Page Title** | `30 pt` | Semibold | `-0.9` | Default | Main page headings |
| **Card Title** | `15–17 pt` | Medium / Semibold | Normal | Default | Widget and space titles |
| **Large Metric** | `24–42 pt` | Medium / Bold | Normal | Rounded | Clock hours, focus timer, battery percent |
| **Body Text** | `12–13 pt` | Regular | Normal | Default | Descriptions, list items, note bodies |
| **Subtext / Meta** | `10–11 pt` | Regular | Normal | Default | Timestamps, widget dimensions, counts |
| **Micro Caption** | `5–7 pt` | Regular / Semibold | `+0.4` | Default | Mini simulated desktop preview cards |

> [!NOTE]
> All digital readouts (clocks, countdowns, battery, CPU gauges) must specify `.monospacedDigit()` to prevent horizontal jitter during live numerical updates.

---

## 5. Surface Backdrops

Desktop tiles support three backdrop transparency modes in **Widget Studio**:

1. **Solid (`.solid`):** Fully opaque tinted card matching the active palette surface color. Recommended for desktop environments with complex wallpapers.
2. **Glass / Material (`.material`):** Semi-transparent frosted backdrop leveraging native AppKit vibrancy (`NSVisualEffectView`). Adapts dynamically between light and dark appearances.
3. **Transparent (`.transparent`):** Zero-background floating HUD mode. Borders and surface fills are removed; only text, symbols, and progress indicators float directly on the screen.

---

## 6. Curated Spaces Architecture (FIG 05–07)

iGet organizes widgets into three primary workspace profiles tailored for distinct macOS workflows:

### 1. Study Space (FIG 05)
- **Symbol:** `book`
- **Mood / Dominant Palettes:** Sage (`#E4F6ED`) & Paper (`#FFF3DF`)
- **Included Tools:**
  - Clock (Glanceable local time & timezone)
  - Focus session (Pomodoro timer with rest intervals)
  - Tasks (Local checklist with completion toggles)
  - Countdown (Days remaining until exam or milestone)
- **Subtitle:** *"Ders, odak, görev ve sınav geri sayımı."* / *"Study, focus, tasks and exam countdown."*

### 2. Developer Space (FIG 06)
- **Symbol:** `terminal`
- **Mood / Dominant Palettes:** Slate (`#E8EEF8`) & Lilac (`#EDE6FF`)
- **Included Tools:**
  - System monitor (CPU & Memory load sparklines)
  - Quick note (Scratchpad for sprint notes and commands)
  - Launcher / Shortcuts (One-click launch for developer tools)
- **Subtitle:** *"Sistem, katkılar, hızlı açılış ve notlar."* / *"System, contributions, quick launch and notes."*

### 3. Daily Space (FIG 07)
- **Symbol:** `sun.max`
- **Mood / Dominant Palettes:** Sky (`#E2F2FF`), Peach (`#FFEBDD`) & Paper (`#FFF3DF`)
- **Included Tools:**
  - Monthly calendar (Date grid with current day highlight)
  - Weather (Current temperature, city, condition glyph)
  - Battery (Charge percentage & power adapter state)
  - Habits (Daily streak and progress dots)
- **Subtitle:** *"Takvim, hava durumu, pil ve alışkanlıklar."* / *"Calendar, weather, battery and habits."*

---

## 7. Accessibility & Motion

Every component in `iGetDesign` must fulfill the following accessibility requirements:

1. **Contrast Ratio:** All foreground and secondary text tokens must achieve a minimum contrast ratio of **4.5:1** (WCAG AA) against their corresponding background and surface tokens in both light and dark modes.
2. **Dynamic Localization:** Text containers must use flexible layouts (`fixedSize(horizontal: false, vertical: true)` or adaptive grids) to accommodate text expansion in Turkish and German without truncation.
3. **VoiceOver Semantics:**
   - Decorative glyphs and mini layout previews must be hidden from accessibility with `.accessibilityHidden(true)`.
   - Actionable tiles must provide descriptive `.accessibilityLabel(_:)` and `.accessibilityValue(_:)` modifiers.
4. **Reduce Motion:** When the user enables *Reduce Motion* in macOS Accessibility settings, transitions between palettes or space layouts must immediately snap rather than interpolate.
