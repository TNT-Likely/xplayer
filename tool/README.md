# 播放检查入口

核心格式/传输工具由 `packages/xplayer_player/tool/` 维护，根目录的 Python 和设备入口保留转发，完整用法见[独立包测试说明](../packages/xplayer_player/docs/TESTING.md)。`probe_playlist.dart` 只检查网络和容器，不验证完整播放。

应用接入增加实际内核工厂的设备检查。它会按平台策略依次尝试原生 SurfaceView、系统播放器和兼容内核；检查原生渲染计数或可用的视频输出状态、音轨和至少两秒媒体时钟推进，记录每个尝试和最终结果：

生产页面和该工具共用 `lib/services/player/player_backend_factory.dart`。Android 缓冲参数由包的 `BufferProfile` 经通道传递，原生校验范围并保留旧调用方默认值，避免维护两套不一致的配置。

```sh
flutter build apk --debug -t tool/playback_device_probe.dart \
  --dart-define=PLAYBACK_PROBE_APPLICATION=true \
  --dart-define=PLAYBACK_PROBE_CONFIG=http://fixture-server/config.json
```

Android 应用 ID 为 `com.tntlikely.xplayer.playbackprobe`，与生产应用分开。`PLAYBACK_PROBE_FILTER` 可按名称选择频道。配置格式与包内设备工具相同；不把有效期签名或局域网源写入源码。

结果输出 `XPLAYER_APPLICATION_PROBE`，并保存为应用支持目录的 `application_probe.json`，Android 可使用 `adb shell run-as com.tntlikely.xplayer.playbackprobe cat files/application_probe.json` 提取。此工具测试启动/回退顺序，不能代替长时间重连、小窗或真实音频路由验收。完成后释放后端，避免留后台直播连接。

包的自动/软解分开测试使用不带 `PLAYBACK_PROBE_APPLICATION` 的原入口；不要将单内核结果和应用自动回退后的结果混为一谈。对 HTTP 403 或服务端提示短片，应在报告中保留上游问题，不能把换内核成功当成恢复了频道授权或直播内容。
