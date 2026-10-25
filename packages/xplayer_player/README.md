# xplayer_player

XPlayer 的本地 Flutter 播放兼容包，集中管理源地址、请求头、内核策略、状态接口和 libmpv/FFmpeg 后端。使用现有成熟解码内核，不自行实现音视频解码器。Android SurfaceView 与系统 video_player 适配器留在应用层，避免把 Activity 通道和界面设置耦合进通用包。

详细文档：[架构、API 与配置](docs/ARCHITECTURE.md) · [格式与设备兼容边界](docs/COMPATIBILITY.md) · [独立测试、原生回归与排障](docs/TESTING.md)。包目前为仓库内路径依赖，尚未发布到 pub.dev。

包可独立检查：在 `packages/xplayer_player` 下执行 `flutter pub get`、`flutter analyze`、`flutter test`。原生解码样本生成器、HTTP/HLS 回归服务与设备测试入口均由包维护，根目录工具保留转发入口。

| 平台 / 输入 | 首选内核 | 失败后 |
| --- | --- | --- |
| Android / Android TV，HLS / MP4 | 原生 ExoPlayer SurfaceView（遵循设置） | video_player → libmpv 自动解码 → libmpv 软解 |
| iOS / iPadOS / macOS | 完整解码 libmpv 自动解码 | libmpv 软解 → 系统 AVPlayer |
| 各平台 FLV、DASH、TS、MKV、无后缀接口 | libmpv 自动解码 | libmpv 软解 → 平台可用的系统内核 |
| Windows | libmpv 自动解码 | libmpv 软解 → video_player_win |
| Linux | libmpv 自动解码 | libmpv 软解，无未注册的 video_player 回退 |

初始化等待媒体就绪或错误，20 秒超时；应用初始化另有 22 秒兜底。初始化和运行时错误均切换下一内核，各内核尝试一遍后最多重连 3 次。切台、换源或手动重试重建策略。不会因为一次初始化成功就清空重连预算，稳定播放 12 秒后才恢复预算。

优先保留硬解的性能和功耗优势；解码失败后才关闭硬件加速重新尝试。持续卡死或长时间缓冲第二次恢复时也推进内核策略，避免始终重建同一个异常解码器。传输库允许 HTTP(S)、RTMP(S)、RTSP、UDP/RTP，实际协议与音视频解码能力受打包原生库和设备影响。

`PlaybackSource` 拆分 `URL|User-Agent=...&Referer=...`，支持频道属性和 VLC/Kodi/EXTHTTP 请求头，保留签名查询参数原始字节，切换 HLS 画质时保留请求头。`prepareM3uForPlayback` 在现有 M3U 解析前折叠请求头指令，避免注释被识别成 URL。HLS、FLV、TS 和无后缀频道使用直播缓冲策略。Apple 的 AVPlayer 直播位置不会触发位置停滞重连。苹果端优先使用完整解码路径，避免系统内核只出画面而忽略不支持的音轨。

HTTP(S) 使用浏览器兼容的默认 User-Agent，显式请求头优先；libmpv 网络超时默认为 15 秒，缓存保留在内存中。对没有外置音轨/字幕或共享状态的复用 HLS master，先在有界预算内选择一条变体，避免逐一探测全部码率；软解恢复可选择低带宽变体。`PlaybackConfiguration` 可调整时间预算、关闭变体预选或保留恢复时的原画质。

iOS 在准备媒体前配置并激活系统音频会话。共享会话通过串行引用计数管理，只有最后一个播放器释放后才停用，避免并发加载或小窗交接时关闭其他播放器的会话。生产播放默认使用系统音频输出；显式的 `audioOutputDriver: 'null'` 仅用于无音频输出的解码验证。

频道测速使用同一套请求头上下文，能够识别无后缀 HLS 并沿重定向后的路径继续探测分片，拒绝 HTTP 200 的 HTML 错误页面。源属性以 JSON 对象保存，兼容读取旧字符串格式，避免请求头中的逗号、冒号在缓存或同步后丢失。

```dart
import 'package:xplayer_player/xplayer_player.dart';

final backend = MediaKitBackend();
// 在已经挂载的 widget 中先展示 backend.buildView()，再异步准备媒体。
await backend.initialize('https://example.test/live.flv|Referer=https%3A%2F%2Fexample.test%2F');
await backend.play();
// Listen to backend.notifier; dispose on exit.
```

Linux 编译和运行需安装发行版提供的 libmpv；Ubuntu/Debian：`sudo apt install libmpv-dev mpv`。Android、iOS、macOS 和 Windows 使用 [本地原生库适配器](../native/README.md) 打包完整解码构建，固定版本与 SHA-256；不再使用缺少 TrueHD/MLP 等解码器的默认裁剪构建。完整解码会增加安装包体积，格式、硬解能力仍以实际构建和设备验证为准；DRM、过期签名、404、地区限制、缺失的服务端转发不能由解码器修复。

在仓库根目录执行 `fvm flutter test test/player test/mini` 验证策略、请求头、M3U 解析和小窗接口。网络排查使用：

```sh
fvm dart run tool/probe_playlist.dart 'http://192.168.3.2:8872/' --limit=8
fvm dart run tool/probe_playlist.dart 'https://cdn.jsdelivr.net/gh/Kimentanm/aptv@master/m3u/ya.m3u' --limit=8
```

诊断输出 HTTP 状态、响应容器标记和耗时，隐藏签名查询参数。网络检查与设备解码检查应分别记录，HTTP 200 不代表能出画面。2026-10-25 检查上述虎牙列表：5011 条地址全部指向 `107.173.156.246:81`，分散抽样 11 条均返回 HTTP 404 / HTML，未取得可供判断容器的视频数据。

`packages/xplayer_player/tool/probe_decoder.dart` 可以指定 `--libmpv=/path/to/library` 并传入多个媒体 URL / 文件，用无窗口、无音频输出的 FFmpeg 软解验证轨道、分辨率和播放时钟推进；它不验证实际音频输出或 GPU 呈现。

2026-10-25 完整解码构建在 macOS 通过 18 组解码样本，包括 TrueHD 5.1、MLP、HEVC Main10、DTS、AC-3/E-AC-3、FLAC、ALAC、VP9、AV1、MPEG-2、WMV/WMA。Android TV 模拟器通过 40 项自动/强制软解播放检查（17 组样本和 3 条局域网列表中的真实流），检查音频参数、渲染首帧和时钟推进。真实流包含 HTTP-FLV/AAC、HLS/MP2 和 MP4/AAC。iPad 模拟器通过全部 18 组样本的两种模式（36/36）；完整矩阵最后一条 LAN FLV 软解曾初始化超时，增加初始化阶段诊断并显式等待视频输出就绪后，三条真实流专项复测通过 6/6。原始失败与复测结果均保留在[验证记录](validation/2026-10-25.json)。Windows/Linux 的同一解码矩阵已配置进 CI，尚未在当前环境执行对应平台验收。

局域网列表共有 1087 条地址；对 65 条不同来源和高分辨率条目做网络抽样，42 条取得数据，另 23 条返回认证/访问错误、404、超时或连接错误。选取 10 条继续做 macOS 完整音视频解码检查，6 条通过、4 条未通过就绪/推进检查；HTTP 200 清单或分片存在不代表完整播放成功。源码仓库不保存这些带鉴权信息的源 URL。

这四条的[后续排查记录](validation/2026-10-25-source-investigation.json)：CCTV-4 海外源可解码但网络延迟波动；TVBS 使用单变体与低码率恢复后播通；CCTV-6 的浏览器 UA 修复了重定向后 423，但实际返回的是源站超负载提示短片；CCTV-4 官方源后续对不同客户端均返回 403，需上游提供可用授权地址。后两者不能据此宣称已恢复真实频道直播。

iPad 模拟器的上游 libmpv 二进制没有可用的音频输出驱动；可显式使用 `PLAYBACK_PROBE_NULL_AUDIO=true` 验证解码与渲染，但不把此结果当作扬声器输出验收。iOS 真机构建包含 AudioUnit 输出驱动，仍需在实际设备上确认声音、路由和中断恢复。

真机验收应覆盖 Android 手机、Android TV、iPhone、iPad、Windows 和 Linux，使用有效的 HLS（含无后缀重定向）、HTTP-FLV、TS、DASH、H.264/HEVC 与 AAC/AC-3 等样本，检查首帧、声音、长时间播放、断网恢复、切台、小窗和前后台切换。只有对应设备实际通过后才标记兼容。

参考：[media_kit 安装与平台说明](https://github.com/media-kit/media-kit)、[Media3 格式支持](https://developer.android.com/media/media3/exoplayer/supported-formats)。
