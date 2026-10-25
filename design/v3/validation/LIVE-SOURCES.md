# 平台直播与 FLV 原生验证

2026-10-25，在独立工作区的 v3 分支验证。应用代码基于 `2d31a26`，本轮新增验收工具，没有修改播放引擎。结果见 [脱敏 JSON](live-playback.json)。

验收使用真实主应用 `PlayerScreen`、原有自动后端策略和实际网络。标准是已输出视频首帧、有效尺寸、音频解码/输出信息以及持续播放信号，不以 HTTP 200 或文件扩展名判断成功。

| 输入 | iOS 手机模拟器 | Android TV 模拟器 |
| --- | --- | --- |
| 合成 H.264 / AAC FLV | 640×360，MediaKit，通过 | 640×360，MediaKit，通过 |
| 合成 H.264 / MP3 FLV | 640×360，MediaKit，通过 | 640×360，MediaKit，通过 |
| 虎牙 660000 / AL FLV | 1280×720，MediaKit，通过 | 1280×720，MediaKit，通过 |
| 虎牙 660000 / TX FLV | 1280×720，MediaKit，通过 | 1280×720，MediaKit，通过 |
| B站 6 / FLV | 854×480，MediaKit，通过 | 854×480，MediaKit，通过 |
| B站 6 / HLS 对照 | 1280×720，MediaKit，通过 | 1280×720，原生后端，通过 |

FLV 样本均验证了位置推进；HLS 的原生滑动窗口坐标会跳动，因此也按两秒内渲染帧持续增加判断视频推进，不将直播位置不单调误报为无画面。MediaKit 路径同时读取实际音频采样格式及 audiounit / opensles 输出驱动；原生路径读取音频解码器。

虎牙和 B站地址由 Streamlink 8.6.2 对公开直播间即时解析，保留原始签名查询与所需请求头。测试配置、短效地址、完整日志和原生直播截图保存在 `.dart_tool/v3-live-audit/` 与 `.dart_tool/v3-qa/`，不提交签名 URL 或真实直播帧。这些临时目录在本轮交接清理中删除，脱敏结果继续保留。

另外抽测 YanG 的第三方网关：虎牙同房间可解码到 1080p，B站同房间本次请求超时；而直接解析 B站 FLV 可播。旧 Kimentanm 虎牙、B站、斗鱼订阅均已返回 404。这些是来源/链路检查结果，不能据此认定所有 FLV 不受支持，也没有将本次成功扩大为所有直播间和所有设备都通过。

## 复现入口

1. 生成 `h264-aac.flv`、`h264-mp3.flv` 合成片段。真实直播案例 JSON 是对象数组，每项含 `name`、`url`、`headers`；即时解析后在本地保存，不放入源码。
2. 启动本机验收服务：

```sh
python3 tool/live_source_fixture_server.py --root /path/to/private-fixtures \
  --cases /path/to/private-cases.json --port-file .dart_tool/live-server.json
```

3. 读取临时端口，使用专用模拟器执行：

```sh
flutter drive --no-pub --keep-app-running -d '<专用模拟器 ID>' \
  --driver=test_driver/v3_driver.dart --target=integration_test/live_sources_test.dart \
  --dart-define=QA_DEVICE=phone \
  --dart-define=QA_STREAM_CONFIG=http://127.0.0.1:PORT/config.json
```

Android 模拟器使用 `QA_DEVICE=tv` 和 `http://10.0.2.2:PORT/config.json`。服务只监听本机，只提供配置和两份合成 FLV。测试会调整专用设备的启动刷新偏好、启动实际播放并停止；结束后重建正常 `lib/main.dart` 入口再安装。本轮已恢复正常入口。

本轮没有实测物理电视、浏览器的 FLV 解码、账号专属画质或平台受限房间。新增订阅及临时测试 M3U 按用户要求作为本地配置交付，不内置到应用。

参考：[Streamlink 平台支持](https://streamlink.github.io/plugins.html)、[JSON 输出选项](https://streamlink.github.io/cli.html)、[YanG 平台订阅](https://github.com/YanG-1989/m3u)。
