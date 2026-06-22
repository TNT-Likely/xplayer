**English** | [中文](README.md)

<h1 align="center">XPlayer</h1>

<p align="center">A cross-platform IPTV / M3U player · Android · iOS · macOS · Windows · Linux · Android TV</p>

<p align="center">Works out of the box with built-in <a href="https://github.com/iptv-org/iptv">iptv-org</a> public playlists, with <b>channel grouping &amp; search</b>, EPG, favorites, and <b>phone-to-TV remote text input</b>.</p>

---

## ✨ Features

- 📺 **Built-in channels, zero setup** — ships with [iptv-org](https://github.com/iptv-org/iptv) public playlists; auto-loads the *China* list on first launch and lets you add *Sports / News / All* presets in one tap. You can also import any M3U/M3U8 (local file or URL).
- 🔎 **Grouping + Search** — too many channels to find the good ones? Filter instantly by name from the search bar, and one-tap group chips (News / Sports / Movies…). Great for finding the match during the World Cup.
- 🗓️ **EPG** — XMLTV programme guide support.
- ⭐ **Favorites** — one tap to favorite the channels you watch most.
- 🖥️ **Every platform** — Android, iOS, macOS, Windows, Linux, Android TV from one codebase.
- 📱 **Phone → TV remote input** — typing on a TV is painful; your phone auto-discovers the TV on the LAN and types remotely with real-time sync (delete key included).
- 🌐 **Localized** — English / 中文.

## 📸 Preview

![preview-1](https://github.com/user-attachments/assets/fe341b2a-66f7-42b6-b3d0-6ece3dd47203)
![preview-2](https://github.com/user-attachments/assets/8632dff6-dc7a-4717-99ca-a39e9efddd04)
![preview-3](https://github.com/user-attachments/assets/a14b1e50-65b9-45a1-b495-ada3983b01e9)
![remotecontrol](assets/preview/remote-control.jpg)

## 🚀 Install

Grab a build from [Releases](https://github.com/TNT-Likely/xplayer/releases):

- **Android / Android TV** (split per ABI for smaller size):
  - `xplayer-<version>-arm64-v8a.apk` — most phones / TV boxes (**recommended**)
  - `xplayer-<version>-armeabi-v7a.apk` — older 32-bit devices
  - `xplayer-<version>-x86_64.apk` — emulators / x86 devices
  - `xplayer-<version>-universal.apk` — fallback if you're unsure
- **Windows**: `xplayer-windows-x64.zip`
- **macOS**: `xplayer-macos.dmg` (see FAQ for first launch)
- **Linux**: `xplayer-linux-x64.tar.gz`

## 🕹️ Usage

1. Open the app — it auto-loads the built-in iptv-org China playlist on first run.
2. Use the search bar / group chips to find channels fast, and ⭐ favorite the ones you watch; the drawer's **Recommended Sources** adds more presets or imports your own M3U.
3. On a TV, open **Remote Input** on your phone to discover the TV and type remotely.

## 🛠️ Development

```sh
flutter pub get

# Run
flutter run -d <device_id>

# Build
flutter build apk --release -PabiSplit   # Android: split APKs per ABI
flutter build appbundle --release        # Android: AAB for Play (no split)
flutter build ios --release              # iOS
flutter build macos --release            # macOS
flutter build windows --release          # Windows
flutter build linux --release            # Linux
```

> Release signing: copy `android/key.properties.sample` to `android/key.properties` and fill in your keystore; CI injects it via GitHub Secrets — see `.github/workflows/release.yml`.

## ⚖️ Disclaimer

XPlayer is a **player**. It does not host or provide any stream. The built-in presets come from the open-source [iptv-org/iptv](https://github.com/iptv-org/iptv) project — publicly aggregated, publicly accessible stream URLs that the app fetches from upstream at runtime (no bundled copy). Please use it for personal, lawful purposes only; report any infringing link upstream to iptv-org for removal.

## ❓ FAQ

### How to open the unsigned app on macOS?

1. On first launch, if you see "cannot verify developer", right-click XPlayer.app > Open, or allow it in System Settings > Privacy & Security.
2. Or run in a terminal:

```sh
sudo xattr -rd com.apple.quarantine XPlayer.app
```

### Remote input can't find the TV?

- Make sure the phone and TV are on the same LAN;
- Your router must support mDNS/Bonjour;
- Try restarting the app.

## ❤️ Donate

If you like this project, please consider supporting the developer!

- Crypto: ![Binance](assets/binance.jpg)
