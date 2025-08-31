[English | 中文](README_EN.md)

# XPlayer

## 功能介绍 / Features

- IPTV 播放器，支持本地/网络播放列表，EPG 节目单，收藏与分组
- 多平台支持：Android、iOS、macOS、Windows、Android TV
- TV 端支持局域网遥控输入（手机自动发现 TV，远程输入文字，实时同步 TV 输入框内容）
- 远程输入支持“删除”按键
- 多语言界面（中/英）

**预览 / Preview**

![WX20250217-170655](https://github.com/user-attachments/assets/fe341b2a-66f7-42b6-b3d0-6ece3dd47203)
![WX20250217-170720](https://github.com/user-attachments/assets/8632dff6-dc7a-4717-99ca-a39e9efddd04)
![WX20250217-171053](https://github.com/user-attachments/assets/a14b1e50-65b9-45a1-b495-ada3983b01e9)
![remotecontrol](assets/remote-control.jpg)

---

## 如何使用 / How to Use

1. TV 端（如 Android TV、机顶盒、Windows/macOS）安装并打开 XPlayer，导入 IPTV 播放列表
2. 手机端进入“远程输入”，自动发现 TV，选择后可远程输入文字（首次发送后自动实时同步）
3. 支持 Android/iOS/macOS/Windows/Android TV

---

## 开发指南 / Development

1. 安装依赖 / Install dependencies

```sh
flutter pub get
```

2. 运行 / Run

```sh
# Android
dart run flutter run -d <android_device_id>
# iOS
dart run flutter run -d <ios_device_id>
# macOS
dart run flutter run -d macos
# Windows
dart run flutter run -d windows
# Android TV 设备同 Android
```

3. 构建发布包 / Build release

```sh
flutter build apk   # Android
flutter build ios   # iOS
flutter build macos # macOS
flutter build windows # Windows
```

---

## 常见问题 / FAQ

### macOS 如何打开未签名的包？

1. 第一次打开时如遇“无法验证开发者”，请右键 XPlayer.app > 打开，或在“系统设置 > 安全性与隐私”中允许。
2. 终端可用：

```sh
sudo xattr -rd com.apple.quarantine XPlayer.app
```

### 远程输入无法发现 TV？

- 请确保手机和 TV 在同一局域网
- 局域网路由器需支持 mDNS/Bonjour
- 可尝试重启 App

---

## 捐赠 / Donate

如果你喜欢本项目，欢迎支持开发者！

- 加密货币 / Crypto： ![Binance](assets/binance.jpg)
