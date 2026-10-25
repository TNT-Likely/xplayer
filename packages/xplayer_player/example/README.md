# 独立接入示例

示例只依赖 `xplayer_player` 与 Flutter，不引用主应用的数据库、Provider、频道模型或 `lib/services/player`。它直接使用完整 libmpv 后端，支持输入地址、播放/暂停、重试和软解切换。

在仓库根目录运行 `flutter pub get`，再进入本目录：

```sh
flutter run -d macos
# 或选择 flutter devices 中的 Android / iOS / Windows / Linux 设备。
```

可以用 `--dart-define=EXAMPLE_SOURCE=https://example.test/live.m3u8` 预填地址；仍由点击加载开始播放。URL 可带核心包支持的请求头后缀，不要将个人签名或直播鉴权提交到源码。

示例为普通 Flutter 应用。Android 启用 INTERNET 与明文 HTTP 以验证常见 IPTV 地址；macOS 沙盒启用网络客户端。Linux 需安装 `libmpv-dev` 等桌面构建依赖。Apple 真实设备的签名与系统权限由使用者配置。

核心包只提供通用后端和策略接口。主应用专有的 Android ExoPlayer SurfaceView、电视 UI 与小窗设置仍在宿主内；本示例不依赖这些 Activity 通道。

格式矩阵用 `../tool/run_device_validation.py` 驱动此工程，临时生成 `tool/playback_probe.g.dart`，退出时恢复或移除；Android 探针使用单独 `.probe` 应用 ID。示例本身没有内置个人局域网播放列表。

[分发、验证与发布顺序](../doc/DISTRIBUTION.md) · [测试说明](../doc/TESTING.md)。
