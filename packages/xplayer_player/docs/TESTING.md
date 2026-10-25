# 测试、排障与版本升级

查看结果请先读[中文验收报告](../validation/2026-10-25-audio-acceptance.md)；本文面向需要运行测试或排查错误的开发者。

## 1. 包独立检查

在仓库根目录执行：

```sh
cd packages/xplayer_player
flutter pub get
flutter analyze
flutter test
```

使用 Flutter 3.41.9 或满足 Dart >=3.11 的宿主 SDK。包的 `dev_dependencies` 自包含，不需要应用数据库、Provider 或频道模型。测试只创建本机 HTTP 服务，不依赖局域网地址、外部直播可用性或已安装 libmpv。根目录 `test/player` 中的兼容入口引用同一批核心用例，保留既有应用测试命令；应用特有的 MethodChannel、M3U 模型、测速和 HLS 画质 UI 测试仍留在根目录。

| 用例 | 防止的回归 |
| --- | --- |
| playback_source | 默认/显式 UA、大小写覆盖、请求头换行、域名边界、签名原字节、VLC/Kodi/EXTHTTP |
| hls_startup | 重定向后相对路径、签名变体、只选择一条复用变体、低码率恢复、外置音轨/字幕/KEY/变量保留 |
| hls_startup 边界 | 403、HTML、无带宽/缺少 URI、不支持协议、256 KiB 上限、总超时、非 HLS 零探测 |
| playback_configuration | 时间预算有效性、给原生初始化保留预算、单位换算 |
| player_backend_selector | 五平台策略、Android TV SurfaceView 优先、Linux 不调用缺失插件、有界推进 |
| buffer_profile / stall_detector | 直播缓冲、位置倒跳不冒充前进、暂停不误报、恢复与 reset |
| audio_session_coordinator | 并发租约、异步停用期间再申请、失败后队列恢复、重复释放 |
| native_library_pins | 生产适配器与 CI 的实际原生资产一致 |
| x_player_value / audio_track | 状态复制、画面尺寸/比例和音轨显示契约 |

## 2. 真实 decoder 矩阵

以下命令仍在包目录执行：

```sh
python -m pip install imageio-ffmpeg==0.6.0
FFMPEG_BIN=$(python -c 'import imageio_ffmpeg; print(imageio_ffmpeg.get_ffmpeg_exe())')
python tool/generate_playback_fixtures.py --output /tmp/xplayer-fixtures --ffmpeg "$FFMPEG_BIN"
python tool/check_decoder_compatibility.py --fixtures /tmp/xplayer-fixtures --report /tmp/xplayer-decoders.json
python tool/check_stream_transport.py --fixtures /tmp/xplayer-fixtures --report /tmp/xplayer-transport.json
```

macOS/Linux 命令使用 shell；Windows CI 使用 Git Bash，或在 PowerShell 中用等价变量语法与临时目录。`check_decoder_compatibility.py` 在 macOS/Windows 下载并验证和生产一致的原生资产，macOS 只签名测试副本；Linux 使用本机 libmpv。首次运行需要网络下载原生资产，后续使用校验后的缓存。Windows 需要 CMake 解压 7z；Linux 先安装 `libmpv-dev`。

必须使用真正的 Dart SDK 可执行文件；macOS Flutter shell 包装器可能移除 `DYLD_FRAMEWORK_PATH`。工具会从 PATH 的 Flutter 推导 Dart；多 SDK 环境可以传入 `--dart /absolute/flutter/bin/cache/dart-sdk/bin/dart`。不修改 pub cache 和 Flutter SDK。

成功条件包含：视频轨道与解码参数、音频轨道与样本格式、至少两个向前位置样本、至少一秒墙钟时间与一秒媒体时钟推进、没有致命播放错误。每个进程有 45 秒上限，超时也计入失败；退出码非零可直接阻止 CI。

传输回归通过本机服务与同一真实 decoder 检查五种场景：浏览器 UA + FLV 重定向、HLS master 重定向与签名、坏高码率下的低码率恢复、首字节等待超过旧的 5 秒默认值、HTTP 403 状态识别。测试同时核对未访问坏的变体与签名查询未改写，避免只凭“函数返回某个 URL”宣称恢复成功。

这两类原生检查使用 `vo=null`、`ao=null` 和软解，不能证明 Flutter texture、GPU、扬声器或硬解正常。Windows 应用构建也不能替代 Windows decoder/渲染运行验收。

## 3. Flutter/设备播放

包内 `tool/playback_device_probe.dart` 是显式测试入口，需用 Flutter 应用工程承载。当前仓库提供 `tool/playback_device_probe.dart` 转发入口：

```sh
# 仓库根目录。配置由测试机自己托管，不写入源码。
flutter build apk --debug -t tool/playback_device_probe.dart \
  --dart-define=PLAYBACK_PROBE_CONFIG=http://127.0.0.1:PORT/config.json
```

Android 宿主 Gradle 针对此入口使用 `.playbackprobe` 应用 ID。测试安装仍遵守设备安装限制。配置格式：

```json
{"sources":[{"name":"h264-aac","url":"http://fixture-server/live.flv","expectAudio":true,"expectVideo":true}]}
```

每个源分别测试自动与强制软解；断言解码参数、渲染首帧和时钟推进，结果输出 `XPLAYER_PROBE`，并写入应用支持目录 `codec_probe.json`。`PLAYBACK_PROBE_FILTER` 按样本名称过滤，`PLAYBACK_PROBE_MODE=auto` 或 `software` 限定模式。该入口默认静音，`PLAYBACK_PROBE_NULL_AUDIO=true` 仅用于显式的无声解码检查，报告会标明测试模式。本地适配器已补齐 iOS 模拟器的 AudioUnit；完整声音检查使用下文的应用探针和系统混音验收流程，物理设备的音质与路由单独记录。

`PLAYBACK_PROBE_DEBUG=true` 开启 `XPLAYER_NATIVE` 脱敏日志。失败报告包含初始化阶段、HTTP 状态、音频参数、视频尺寸、位置与缓冲状态。Android 上游首帧通知可能在视频尺寸变化时完成，验收时还应检查没有输出错误并查看实际画面；不能只凭该布尔值宣布 GPU 正常。

## 4. 单源排障

```sh
# 仓库根目录，只检查 HTTP/容器，隐藏签名查询。
dart run tool/probe_playlist.dart 'http://your-server/playlist.m3u' --limit=8

# 包目录，真实 decoder 无窗口检查。
dart --packages=.dart_tool/package_config.json tool/probe_decoder.dart \
  --libmpv=/path/to/libmpv --require-audio --require-video \
  --diagnose-errors --native-log 'https://origin.test/live.m3u8'
```

`--native-log` 输出经过脱敏的原生日志与耗时；`--original-source` 关闭 HLS 准备和本包网络选项，用于对照；`--lower-bandwidth` 验证恢复分支；`--mpv-option=name=value` 临时覆盖原生设置。原始 URL 含凭据时不要放在提交、工单或公开 CI 参数中。生产源结果只保留频道标签、状态、编解码参数与耗时。

排查顺序：确认清单 HTTP 状态 → 重定向最终主机 → 媒体分片/密钥 → 轨道 → 解码参数 → 首帧 → 时钟 → 真实声音。若取到的是源站提示视频，应把内容问题与播放器解码成功分别记录；若所有标准客户端都返回 403，不修改/猜测未知签名，而是更新上游提供的有效源。

## 5. 发布门槛

修改协议、默认请求头、HLS 选择、超时或库版本，运行包测试、传输原生回归、18 组 decoder 矩阵；修改渲染/会话还运行 Android TV 与 iPad 测试，并做可用真机验证。最终接入应用时再运行根目录测试与平台构建。没有对应系统的实际执行环境时，标记为“CI 配置/待验证”，不填“通过”。

新增格式应明确容器、视频编码/profile/位深、音频编码/声道，生成或保存可公开再现的最小样本，加入矩阵，记录预期成功或受限原因。避免只加扩展名正则而没有 decoder 证据。

media_kit、media_kit_video、audio_session 与 Linux 插件使用精确版本，避免包独立解析依赖时静默切换关键实现。升级这些依赖需显式修改 pubspec 并重跑矩阵。

## 系统声音输出验收

解码器给出 `audioSampleFormat` 不等于扬声器输出已启动。应用探针 `tool/application_playback_probe.dart` 使用宿主的真实后端工厂，检查 libmpv 的 `audioOutputDriver`、`audioOutputParams`、非静音状态与非零音量；Android 原生后端检查 `onAudioPositionAdvancing` 回调。每个用例落盘检查点，整个批次结束后标记 `complete: true`，避免测试中断时丢失已完成结果。

配置示例：

```json
{"sources":[{"name":"受测直播","url":"http://example.test/live.m3u8","expectAudio":true,"expectVideo":true,"testPauseResume":true,"minPlaybackSeconds":8}]}
```

`minPlaybackSeconds` 默认为 2，可设置 2～10 秒；短文件不要启用 `testPauseResume`，避免将正常播完误判为恢复失败。直播时间戳可能倒跳，探针累计连续的向前增量，忽略倒跳和异常大跳；Android 暂停恢复还检查实际渲染帧数，而非仅依赖时间轴数值。

```sh
flutter run -d DEVICE -t tool/playback_device_probe.dart \
  --dart-define=PLAYBACK_PROBE_APPLICATION=true \
  --dart-define=PLAYBACK_PROBE_CONFIG=http://HOST:PORT/config.json
```

这条命令在宿主仓库根目录执行。Android 测试 APK 使用 `.playbackprobe`；Apple 建议创建专用模拟器、macOS 使用独立 bundle ID，保留用户数据。桌面渲染验收应让窗口可见；被遮挡或隐藏的窗口可能暂停帧调度，不应冒充播放器解码失败。

macOS 可进一步检查系统混音后的 PCM 能量，无需保存音频或截图：

```sh
swiftc -parse-as-library packages/xplayer_player/tool/system_audio_meter.swift \
  -o /tmp/xplayer-audio-meter
/tmp/xplayer-audio-meter
```

需要 macOS 13+ 以及已授予的“屏幕与系统音频录制”权限；工具会先检查权限，不会主动弹出授权请求。先停止所有测试播放器测静音基线，再逐端单独播放同一个已知有声源。每次采样 12 秒，记录采样数、峰值、RMS 与 dBFS。全局混音模式下应关闭其他有声应用；不能将别的应用或提示音当作受测播放器通过。可提供 PID 限定 macOS 应用，但应核对系统的音频进程归属。

该检查证明系统输出中存在非静音 PCM，不替代物理扬声器音质、蓝牙/HDMI 路由、多声道或口型同步验证。2026-10-25 的音频补测结果见[中文验收报告](../validation/2026-10-25-audio-acceptance.md)，逐项技术数据保留在[原始 JSON](../validation/2026-10-25-audio-acceptance.json)。

更新 `native_builds.json` 后同步 Darwin Makefile、Windows CMake；Android直接读取清单。核对来源与许可证，运行 pin 测试、完整矩阵和应用构建。不要通过换回裁剪构建缩小包体，否则 TrueHD 等会再次缺失。库升级与行为修改尽量分开提交，保留旧版本报告作为对照；必要时回滚到上一组完整且已验证的固定资产。
