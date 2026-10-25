# 架构与接入约定

## 包的边界

`xplayer_player` 是可独立分析、测试和分发的 Flutter package，当前候选版本 `0.1.0-beta.1`。它通过版本依赖接入自包含原生插件 `libmpv_xplayer`；包内代码、原生构建和诊断工具不依赖原来的 `packages/native/` 相邻目录。当前尚未上传 pub.dev，分发验证与发布顺序见 [DISTRIBUTION](DISTRIBUTION.md)。

核心包拥有：

- `PlaybackSource`：地址、格式提示、请求头与 M3U 预处理。
- `PlaybackPlan`：给定平台、源类型和原生引擎设置后，生成有界的内核尝试顺序。
- `PlaybackConfiguration`：网络、初始化和 HLS 元数据的时间预算，以及多码率选择开关。
- `MediaKitBackend`：完整 libmpv/FFmpeg、Flutter 视频纹理、音轨选择、诊断和 Apple 音频会话。
- `XPlayerBackend` / `XPlayerValue` / `AudioTrack`：宿主适配器共同遵守的接口。
- `BufferProfile` / `StallDetector`：可单测的缓冲配置和停滞判定。

应用拥有 Android 原生 ExoPlayer SurfaceView 通道、`video_player` 适配器、后台/小窗交接、用户设置、重连计数、频道与源选择、错误界面。核心包不引用 `package:xplayer`，不能因为修改重试规则就依赖页面或 Provider。

`playback.dart` 导出源、策略、配置和 HLS 准备逻辑，可用于 Dart 命令行诊断；`xplayer_player.dart` 还导出 Flutter 后端、状态和音频会话协调器。

## 宿主接入

本仓库应用通过以下依赖接入：

```yaml
dependencies:
  xplayer_player: ^0.1.0-beta.1
```

仓库内由 Dart workspace 解析本地包；发布后的其他宿主只需正常版本依赖，无需保留源码相对布局。仓库外候选验证会将两个包放入不同目录，检查该约定。Android 最低系统、Apple Deployment Target 和 Windows 架构由宿主工程及 Flutter SDK 决定；原生库包含某个架构不等于已经实机验收。

在 Flutter 已运行的 widget 生命周期内创建并初始化后端，挂载 `buildView()`。`VideoController` 的原生输出依赖帧调度，不要在 `runApp()` 前等待视频准备完成。

```dart
final backend = MediaKitBackend(
  configuration: const PlaybackConfiguration(
    networkTimeout: Duration(seconds: 15),
    initializationTimeout: Duration(seconds: 20),
    hlsProbeTimeout: Duration(seconds: 3),
    resolveHlsVariants: true,
    lowerBandwidthOnSoftwareFallback: true,
  ),
);

// 在 build 中返回 backend.buildView()，在异步任务中执行：
await backend.initialize(
  source.url,
  headers: source.headers,
);
await backend.play();
// listen to backend.notifier and backend.diagnostics;
// await backend.dispose() when this playback session ends.
```

`source` 是 `PlaybackSource.parse(...)` 的结果。调用方必须处理初始化异常和初始化后的 `notifier.value.hasError`。每个后端实例只初始化一次；切台和更换解码方式时创建新实例，串行等待旧实例释放。取消加载时允许初始化任务稍后结束，任务完成后仍要核对当前频道/加载代号，不能重新播放旧频道。

宿主先检查 `PlaybackPlan.current`，用自己的工厂将 `native`、`videoPlayer` 映射到平台适配器，将 `mediaKit`、`mediaKitSoftware` 映射到 `MediaKitBackend(softwareDecoding: ...)`。失败后调用 `advance()`；返回 false 后不能继续当作存在下一个内核。网络重连是否允许、最多几次、何时恢复预算由宿主管理。

应用当前对初始化额外施加 22 秒超时。修改包内初始化预算时，宿主的外层预算也必须调整，避免外层提前取消。包的 20 秒预算包含视频输出、HLS 准备与原生媒体打开；iOS 音频会话配置在此之前进行，仍受宿主外层保护。

## 请求上下文

请求头按频道属性、URL 的 `|Header=value`、显式 `headers` 依次覆盖，字段名不区分大小写，拒绝换行注入。HTTP(S) 默认 `User-Agent: Mozilla/5.0`，因为部分重定向端点拒绝 Lavf/ExoPlayer/Dart 标识；调用方指定的标识始终优先。Huya 的默认 Referer 只应用于实际 Huya/msstatic 域名。

签名查询保留原始字节，不排序、不重编码、不尝试修补未知签名。`#.m3u8` 等片段只用作格式提示，不发给服务器。画质切换使用 `withUrl()` 保留原请求头。VLC、Kodi、EXTHTTP 指令在 M3U 交给上层解析器前合并，避免注释行被解析为视频地址。

## HLS 首播与恢复

libavformat 直接打开某些 master 时会先请求多条变体并探测各自轨道，慢或坏的变体会拖延正在使用的变体。兼容后端先在 **3 秒总预算、256 KiB 上限**内读取 master；单一媒体清单继续交给原生内核。

只对可安全拆出的复用音视频变体选择直接媒体 URL：正常路径选最高带宽，软解恢复路径可选最低带宽。相同 1080P 分辨率下仍可能有不同带宽，因此使用 BANDWIDTH，而非只比较分辨率。Android ExoPlayer / 系统播放器继续保留自身 ABR。

master 包含 `EXT-X-MEDIA`、音轨/字幕/视频组、SESSION-KEY 或 DEFINE 时保留完整 master，防止丢音轨、字幕、加密上下文或变量。清单异常、超时或不支持的 URI 也保留原 URL，允许原生内核继续尝试。可将 `resolveHlsVariants: false` 用于对照排查。

HLS 原生探测时长设为 1 秒；网络超时默认为 15 秒，替代 media_kit 的 5 秒默认值。缓存留在受限内存缓冲中，关闭磁盘缓存，避免沙盒内没有原生 cache 目录导致的文件缓存失败。时间预算不会创造带宽；码率长期高于实际吞吐时需要低码率变体或修复服务端。

## 状态与资源

`initialize()` 完成表示媒体打开并出现解码参数，不代表用户已经看见首帧或听到声音。`diagnostics.firstFrameRendered` 来自上游视频通知，Android 可能在尺寸确定时提前触发；设备探针还要求 `videoOutputConfigured: yes` 和非空 `videoOutputParams`，并检查持续时钟与致命错误。实际画面仍应通过设备截图或帧检查确认。纯音频没有视频首帧，调用方不可一律等待它。

Android 在打开媒体前向本地原生适配器请求一次 EGL 能力检查，Dart 等待上限为 1 秒，Dart 端合并并发请求并缓存成功或超时降级结果，原生端也缓存成功的探测结果，避免卡死的驱动引发重复探测线程。正常上下文使用原路径；只有明确检测到零 `EGL_CONTEXT_FLAGS_KHR` 返回 `EGL_BAD_ATTRIBUTE`、无标志与 DEBUG 上下文都成功，才设置 mpv 的 `gpu-debug=yes`。这避开固定版本 mpv 的 EGL 参数兼容问题，保留完整解码器和原硬解/软解选择。探测不创建屏幕表面，不调用共享 display 的 `eglTerminate`；旧宿主缺少通道、原生错误或超时均使用原路径。详细结果保留在 `androidEglCapabilities`，后续升级 mpv 时应重跑矩阵并评估移除此兼容参数。

宿主对 libmpv 在所有系统上使用播放时钟推进检测；AVPlayer 直播位置可能长期不变，因此保留对该系统内核的豁免。不要只按“是否 Android”决定所有内核的停滞语义，否则桌面和 Apple 兼容内核的无错误冻结会漏检。

`initializationStage` 分为 videoOutput、manifest、open、decoder、ready。`httpStatus` 保留原生 HTTP 错误状态，403/423 不能笼统归为“设备不支持编码”。`videoMime` / `audioMime`、硬解像素格式、音频采样率和声道数用于定位；没有值时不要补写推测结果。诊断字段可增加，调用方应容忍缺失字段。

可选 `onLog` 回调开启脱敏的详细原生日志，正式播放默认只收集警告/错误。核心额外转发 media_kit 默认遗漏的 cplayer fatal 错误，并保留首个根因，避免纹理输出失败被随后“不支持 seek”的消息掩盖。详细日志本身不能替代时钟或画面验证；部分 Android 首帧通知会随视频参数产生，实际 GPU/屏幕仍应由设备验收确认。

iOS 使用 playback/moviePlayback 音频会话，采用共享串行租约；最后一个使用者释放后才停用，避免播放器交接时切断另一个会话。系统中断、扬声器/蓝牙/HDMI 路由与前后台行为仍应在宿主的真实设备上验收。`audioOutputDriver: 'null'` 只用于明确的解码测试，不能用它处理生产环境无声问题。

## 后续扩展

新增格式先加入可复现样本，再判断故障属于传输、解复用、解码、渲染还是音频输出。优先修复共用请求上下文和已固定的原生构建。只有现有内核缺少能力且能够给出设备回归证据时才新增内核，避免每个平台分别堆叠地址特判。更新原生库必须同时更新清单、适配器和实际 decoder 矩阵；更换 Flutter/媒体库时保留 Android TV SurfaceView 路径的回归。
