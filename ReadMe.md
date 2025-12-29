# KiwiNotch

A personal fork of [Atoll](https://github.com/Ebullioscopic/Atoll) — the macOS app that transforms your MacBook notch into a powerful command surface for media, system insight, and quick utilities.

## About This Fork

KiwiNotch is my personal take on the Atoll notch experience. I'm building features I want to use day-to-day without waiting for upstream PRs to be merged. While I continue contributing back to the original Atoll project, this fork lets me ship and use new ideas immediately.

This project may eventually be shared with friends, family, or even publicly if it grows into something others would find valuable.

## Features

All the great features from Atoll, including:

- **Media Controls** — Apple Music, Spotify, and more with artwork, transport controls, and adaptive lighting
- **System Stats** — Lightweight CPU/GPU/memory/network/disk graphs with detailed popovers
- **Productivity** — Clipboard history, colour picker, timers, calendar integration
- **Lock Screen Widgets** — Weather, media, charging, and Bluetooth battery widgets
- **UI Modes** — Minimalistic (compact 420px) or Standard (full-width) layouts
- **Live Activities** — Media playback, Focus Mode, screen recording, privacy indicators, download progress, battery status

## Requirements

- macOS 14.0 or later (optimised for macOS 15+)
- MacBook with a notch (14/16‑inch MacBook Pro with Apple Silicon)
- Xcode 15+ to build from source
- Permissions as needed: Accessibility, Camera, Calendar, Screen Recording, Music

## Installation

```bash
git clone https://github.com/santiagoquihui/KiwiNotch.git
cd KiwiNotch
open DynamicIsland.xcodeproj
```

Select your Mac as the run destination, then build and run (⌘R). Grant the prompted permissions and the menu bar icon will appear.

## Quick Start

- Hover near the notch to expand; click to enter controls
- Use tabs for Media, Stats, Timers, Clipboard, and more
- Toggle Minimalistic Mode from Settings for a smaller layout
- Two-finger swipe down to open the notch (when hover-to-open is disabled)

## License

KiwiNotch is released under the **GPL v3 License**, the same license as the original Atoll project. See [LICENSE](LICENSE) for full terms.

## Credits & Acknowledgments

This project is a fork of and builds entirely upon:

### [Atoll](https://github.com/Ebullioscopic/Atoll)

KiwiNotch would not exist without the excellent work of the Atoll team. The entire codebase, architecture, and feature set originate from Atoll. Huge thanks to [@Ebullioscopic](https://github.com/Ebullioscopic) and all Atoll contributors.

If you're looking for the original, actively maintained project with community support, please visit and consider supporting [Atoll](https://github.com/Ebullioscopic/Atoll).

### Upstream Acknowledgments (via Atoll)

- [**Boring.Notch**](https://github.com/TheBoredTeam/boring.notch) — Foundational codebase for media player integration, AirDrop surface, file dock, and calendar display
- [**Alcove**](https://tryalcove.com) — Inspiration for Minimalistic Mode and lock screen widget concepts
- [**Stats**](https://github.com/exelban/stats) — CPU temperature, frequency sampling, and per-core utilisation tracking via SMC/IOReport
- [**Open Meteo**](https://open-meteo.com) — Weather APIs for lock screen widgets
- [**SkyLightWindow**](https://github.com/Lakr233/SkyLightWindow) — Window rendering for lock screen widgets

---

<p align="center">
  <sub>A personal fork of <a href="https://github.com/Ebullioscopic/Atoll">Atoll</a> • GPL v3</sub>
</p>
