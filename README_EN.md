[中文 | Chinese](README.md)

# XPlayer

## Features

- IPTV player: supports local/online playlists, EPG, favorites, and grouping
- Multi-platform: Android, iOS, macOS, Windows, Android TV
- TV-side LAN remote input: mobile auto-discovers TV, remote text input, real-time sync to TV input field
- Remote input supports "delete" key
- Multi-language UI (EN/中文)

**Preview**

![WX20250217-170655](https://github.com/user-attachments/assets/fe341b2a-66f7-42b6-b3d0-6ece3dd47203)
![WX20250217-170720](https://github.com/user-attachments/assets/8632dff6-dc7a-4717-99ca-a39e9efddd04)
![WX20250217-171053](https://github.com/user-attachments/assets/a14b1e50-65b9-45a1-b495-ada3983b01e9)
![remotecontrol](assets/remote-control.jpg)

---

## How to Use

1. Install and open XPlayer on your TV device (Android TV, set-top box, Windows, macOS), import your IPTV playlist
2. On your phone, open "Remote Input", auto-discover TV, select and input text remotely (real-time sync after first send)
3. Supports Android/iOS/macOS/Windows/Android TV

---

## Development

1. Install dependencies

```sh
flutter pub get
```

2. Run

```sh
# Android
dart run flutter run -d <android_device_id>
# iOS
dart run flutter run -d <ios_device_id>
# macOS
dart run flutter run -d macos
# Windows
dart run flutter run -d windows
# Android TV is the same as Android
```

3. Build release

```sh
flutter build apk   # Android
flutter build ios   # iOS
flutter build macos # macOS
flutter build windows # Windows
```

---

## FAQ

### How to open unsigned app on macOS?

1. If you see "cannot verify developer" on first launch, right-click XPlayer.app > Open, or allow in System Settings > Security & Privacy.
2. Or run in terminal:

```sh
sudo xattr -rd com.apple.quarantine XPlayer.app
```

### Remote input cannot find TV?

- Make sure your phone and TV are on the same LAN
- Your router must support mDNS/Bonjour
- Try restarting the app

---

## Donate

If you like this project, please consider supporting the developer!

- Crypto: ![Binance](assets/binance.jpg)
