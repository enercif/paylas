<div align="center">
  <h1>paylas</h1>
  <p>[pajˈlaʃ] <b>verb, turk.</b></p>
  <p>to share - just the part of your screen that matters.</p>
</div>

---

## What is paylas?

**paylas** is a tiny macOS menu bar app for sharing a section of your screen instead of the whole thing. Drag out a rectangle, and paylas mirrors it live into a regular window, which you can then pick in Discord, Teams, Zoom or any other screen share dialog. Perfect for ultrawide monitors, where sharing the full display leaves everyone squinting.

- Select any region like with `⌘⇧4` and get a live 60 fps mirror of it
- Stream window is a normal window, so every screen share picker can find it
- Dashed border marks the shared region on your screen (color configurable)
- One-click or hotkey blur to hide the stream when something private pops up
- Hide specific apps from the stream entirely (e.g. your password manager or messenger)
- Global keyboard shortcuts, customizable in the settings
- Lives in the menu bar, no Dock icon

## Getting Started

### Prerequisites

- macOS 27 or later
- Xcode 27 (to build)

### Building

There are no prebuilt releases yet, so build it yourself:

1. Clone the repository

    ```bash
    git clone https://github.com/enercif/paylas.git
    cd paylas
    ```

2. Open `paylas.xcodeproj` in Xcode, let it resolve the Swift packages, and hit **Run** (`⌘R`).

3. On the first stream, macOS asks for **Screen Recording** permission. Grant it under
   _System Settings → Privacy & Security → Screen & System Audio Recording_ and restart paylas.

### Usage

1. Click the paylas icon in the menu bar and choose **Bereich auswählen**, or press `⌃⌥⇧2`.
2. Drag out the region you want to share. `Esc` cancels.
3. A window mirroring that region appears. Move it wherever you like (another monitor, behind other windows - it keeps streaming).
4. In your call app, share **that window** instead of your screen.

Hover the stream window to reveal its close and blur buttons, or toggle the blur with `⌃⌥⇧B`. Selecting a new region replaces the current stream and reuses the same window.

### Settings

| Pane                     | What you can change                                          |
| ------------------------ | ------------------------------------------------------------ |
| **Allgemein**            | Show the mouse cursor in the stream, border on/off and color |
| **Im Stream ausblenden** | Apps whose windows never appear in the stream                |
| **Tastenkürzel**         | Shortcuts for region selection and blur                      |

## Version 1.0 Roadmap

The following features are planned before the `v1.0` release:

- [ ] **Prebuilt releases**: signed and notarized builds on GitHub Releases, maybe a Homebrew cask
- [ ] **i18n**: English UI next to the current German one

## Acknowledgements

- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) by Sindre Sorhus for the global hotkeys

## Support

If you find paylas useful, consider buying me a coffee ☕

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/enercif)

## License

This project is licensed under [MIT](LICENSE).
