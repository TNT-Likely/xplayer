# 兼容范围与设备验收

最新结果见[常用格式 HTML 补测报告](https://github.com/TNT-Likely/xplayer/blob/6dda5af460371c9113c4769ce36973f38f04b7b5/packages/xplayer_player/validation/2026-10-25-common-formats.html)：Android MLP 渲染失败已修复，36 组样本在 Android 手机、Android TV、iPhone、iPad 模拟器与 macOS 均通过。直播源与声音原验收见[此前报告](https://github.com/TNT-Likely/xplayer/blob/6dda5af460371c9113c4769ce36973f38f04b7b5/packages/xplayer_player/validation/2026-10-25-audio-acceptance.html)。

## 先区分五层

| 层 | 需要验证的内容 | 典型失败 |
| --- | --- | --- |
| 传输 | HTTP 状态、重定向、请求头、签名、分片/密钥、吞吐 | 403/423、404、超时、HTML 代替视频 |
| 解复用 | HLS/FLV/TS/MP4/MKV/DASH 等容器与时间戳 | 清单有数据但轨道不出现、错误时间轴 |
| 解码 | 编码、profile、位深、声道、实际编译的 decoder | TrueHD 被裁掉、HEVC Main10 不支持 |
| 渲染 | Flutter texture、SurfaceView、GPU/硬解输出、首帧 | 解码有参数但黑屏、纹理初始化卡住 |
| 音频输出 | PCM、设备声卡、系统会话、声道映射和路由 | 有音频参数但扬声器无声 |

HTTP 200 仅说明传输层收到响应；甚至可能是一个编码正常的错误提示视频。通过合成样本也只能证明该样本组合，不能代表同编码所有 profile、4K/8K 或高帧率内容。

## 内核顺序

| 平台/源 | 顺序 |
| --- | --- |
| Android / TV，HLS、常见 MP4 | 原生 ExoPlayer SurfaceView → video_player → libmpv 自动 → libmpv 软解；尊重原生引擎开关 |
| Android / TV，FLV、DASH、TS、MKV、无后缀接口 | libmpv 自动 → libmpv 软解 → 可用的平台内核 |
| iOS / iPadOS / macOS | 完整 libmpv 自动 → 完整 libmpv 软解 → AVPlayer |
| Windows x64 | 完整 libmpv 自动 → 完整 libmpv 软解 → video_player_win |
| Linux | 系统 libmpv 自动 → 系统 libmpv 软解 |

Apple 使用完整解码路径优先，避免 AVPlayer 只显示视频而忽略不支持的音轨。Linux 不回退到未注册的 video_player。

## 具体构建

固定版本、SHA-256 与四个适配器见 [native 构建说明](https://github.com/TNT-Likely/xplayer/tree/main/packages/libmpv_xplayer) 和 [机器清单](https://github.com/TNT-Likely/xplayer/blob/main/packages/libmpv_xplayer/native_builds.json)。Android 包含四种 ABI；Windows 使用普通 x86_64 LGPL 完整构建，避免要求 x86_64-v3。Linux 使用发行版 libmpv/FFmpeg，因此实际能力要在目标发行版运行矩阵，不能只按包名判断。

当前宿主采用 Flutter 3.41.9 / Dart 3.11，Android debug 构建最低 API 24，iOS 13，macOS 10.15。它们是本宿主工程的系统下限，不是已逐版本实测的承诺。Windows 与 Linux 的桌面环境、GPU/驱动及动态库要求另受 Flutter 与发行版影响。

## 样本与证据

当前矩阵为 36 组，新增 HE-AAC/v2（纯音频与 TS）、AAC LATM、MP3/FLV、VP8/Vorbis、HLS fMP4、9 组纯音频、编码尺寸 1080p 的 H.264 High 和 720p 的 HEVC Main。样本生成器与同一组 HE-AAC 固定音调已接入现有原生 CI；Windows/Linux 本轮运行结果仍待验证。矩阵验证具体样本的解码与输出，不承诺同格式全部档位、高码率或所有系统版本。

| 组合 | 样本用途 |
| --- | --- |
| H.264 + AAC / FLV | HTTP-FLV、重定向和常规直播 |
| H.264 + AC-3 / TS；HEVC + E-AC-3 / MKV | 非 AAC 音频与硬解失败回退 |
| HEVC Main10 + E-AC-3 | 10 bit 视频 |
| H.264 + TrueHD、TrueHD 5.1、MLP | 原默认构建缺失的音频解码器、六声道参数 |
| H.264 + DTS、MP2、FLAC、ALAC | 其他常见音频格式与容器组合 |
| VP9 + Opus / WebM；AV1 + AAC / MP4 | 替代视频编码 |
| MPEG-2 + MP2 / TS；MPEG-4 + PCM / AVI；WMV2 + WMA2 / ASF | 较老的节目/录像编码 |
| HLS、DASH | 清单、分片与解码时钟 |

TrueHD 解码输出 PCM；尚未实现/验收 Dolby Atmos 对象渲染或 HDMI bitstream 透传。DTS 样本也不能代表所有 DTS-HD 扩展模式。没有 DRM、密钥或有效鉴权信息时，添加 decoder 无法恢复内容。

[2026-10-25 验证记录](https://github.com/TNT-Likely/xplayer/blob/6dda5af460371c9113c4769ce36973f38f04b7b5/packages/xplayer_player/validation/2026-10-25.json) 保留了首次矩阵与复测：macOS 18/18 无界面软解；Android TV ARM64 模拟器 40/40，包括 17 组合成媒体 × 两种模式与 3 条真实流 × 两种模式；iPad 模拟器 18 组媒体 × 两种模式通过，LAN 全量中曾有一次超时，后续专项 6/6。合成样本为 160×96，验证 decoder 存在及基本执行，不用于证明高分辨率硬件性能。

iOS 模拟器上游构建没有启用音频输出驱动；本地适配器现已重编模拟器 mpv 切片并启用 AudioUnit，见 [原生构建说明](https://github.com/TNT-Likely/xplayer/tree/main/packages/libmpv_xplayer)。上述早期 null audio 结果仅保留为历史解码证据，不能标记为声音通过。新的输出检查需记录 `audioOutputDriver`、输出 PCM 参数和音量，以及暂停恢复结果。真实扬声器、蓝牙和电话中断仍不能由模拟器替代；Windows/Linux 已有 CI 配置，本地 macOS 环境没有替代执行这两个平台的运行验收。

## 设备验收表

每一行应记录机型、系统版本、CPU/GPU、应用/原生库版本、源的有效时间、测试模式、分辨率、首帧时间和结果，不能只填“Android 支持”。

| 设备类 | 必查项目 |
| --- | --- |
| Android 手机/平板 | 硬解与软解、扬声器/蓝牙、横竖屏、前后台、切源、16 KiB 页面设备 |
| Android TV/盒子 | 遥控、SurfaceView/VPP、旧 GPU、32 位 ABI、六声道下混、长时间直播 |
| iPhone/iPad | AudioUnit、静音开关下的播放会话、耳机/蓝牙切换、系统中断、小窗交接 |
| Windows | x64 CPU 基线、ANGLE/GPU 驱动、音频设备、DPI 和窗口调整 |
| Linux | 实际发行版 libmpv/FFmpeg、动态库安装、GPU 与音频服务 |
| 所有设备 | 有效 HLS/FLV/TS/DASH、无后缀 URL、断网恢复、快速切台、暂停、结束、资源释放 |

长稳验收应单独覆盖 30 分钟、2 小时和更长直播；模拟带宽波动、断网/恢复、404/403、清单更新、时间戳跳变和音轨变化，记录内存趋势与最终恢复结果。上述长稳项目目前是待执行清单，不能用四秒样本冒充已完成。
