# XPlayer 原生解码库

这里保留 media_kit 原生库适配器的最小本地分支。原始 Java、Swift、C++ 插件和 MIT 许可来自 media-kit/media-kit；改动集中在下载、校验、完整解码构建的选择，以及 Android EGL 能力探测，不修改 Flutter 渲染器或自行实现解码器。

`native_builds.json` 记录来源、固定版本、构建类型和 SHA-256。原生二进制通过构建下载，不提交到 Git；缓存和解压目录被 `.gitignore` 排除。

| 平台 | 原生构建 | 接入方式 |
| --- | --- | --- |
| Android / TV | media-kit/libmpv-android-video-build v1.1.11，full，arm64-v8a / armeabi-v7a / x86_64 / x86 | Gradle 下载并校验 JAR，声明生成任务依赖，避免与应用 desugar/JNI 合并竞争 |
| iOS / iPadOS | media-kit/libmpv-darwin-build v0.6.0，video-full | CocoaPods / Make，保持现有原生库的最低系统基线 |
| macOS | media-kit/libmpv-darwin-build v0.6.0，video-full | CocoaPods / Make，保留 Universal Intel / Apple Silicon 构建 |
| Windows x64 | zhongfly/mpv-winbuild 2026-10-25-baa3e11d42，LGPL，普通 x86_64 构建 | CMake 固定 SHA-256；保留 media_kit_video 需要的目录与导入库，替换旧的裁剪构建 |
| Linux | 系统发行版 libmpv / FFmpeg | Ubuntu/Debian 安装 `libmpv-dev`；通过同一解码矩阵检查实际能力 |

完整构建补齐旧默认构建未包含的 TrueHD / MLP 等解码器。`hwdec=no` 只切换解码执行路径，不能补上未编译的解码器。音频默认解码为 PCM；这里不把基础 TrueHD 解码等同于 Atmos 对象渲染或 HDMI 原码透传。

Darwin 原生库适配器基于上游 1.1.4，Android 基于 1.3.8，Windows 基于 1.0.11，保留各自 `LICENSE`。适配代码的 MIT 许可与下载的 libmpv、FFmpeg 及其他原生组件许可分别适用；对应源代码与构建脚本见上述仓库及固定发布版本。

## 验证

`tool/generate_playback_fixtures.py` 生成 36 组样本，覆盖 TrueHD 5.1、MLP、HEVC Main10、DTS、AC-3、E-AC-3、AAC/HE-AAC/v2、FLAC、ALAC、VP8/VP9、AV1、MPEG-2、WMV/WMA、纯音频、HLS TS/fMP4 与 DASH。HE-AAC 采用包内自行生成的音调，固定 SHA-256，见[样本说明](../xplayer_player/test/fixtures/README.md)。

`tool/check_decoder_compatibility.py` 校验实际音频解码参数、视频解码参数和至少一秒的时钟推进，进程超时单独标记失败。`.github/workflows/playback-compatibility.yml` 在 macOS、Windows、Linux 运行此矩阵，并在 Windows 构建应用以检查 CMake / ANGLE 集成；不能用这份配置代替尚未执行的 CI 结果。

`tool/playback_device_probe.dart` 额外验证 Flutter 渲染首帧、自动与强制软解两种模式。Android 测试使用单独应用 ID `.playbackprobe`，结果保存在应用支持目录的 `codec_probe.json`。无界面解码测试仍可显式使用 `PLAYBACK_PROBE_NULL_AUDIO=true`，但该结果不代表系统音频输出验证。

### iPhone / iPad 模拟器音频

上游 v0.6.0 的模拟器切片没有启用 AudioUnit，视频可能正常而无声，随后还会触发无效的软解重试。本地 `ios/build_simulator_audio.py` 重新编译同版本 mpv 0.36.0 的模拟器切片，启用 AudioUnit、保留 libass / uchardet / OpenGL，并应用上游的 Objective-C 构建与共享音频会话补丁。FFmpeg 完整解码库和 iOS 真机切片保持固定版本；不使用 null audio 掩盖输出问题。

首次 iOS 构建额外需要 Python 3.10+、`pkg-config` 和 Xcode。脚本校验所有下载源码/头文件/补丁的 SHA-256，在插件 `.cache/` 下创建固定版本的 Meson/Ninja 环境，生成 arm64 与 x86_64 模拟器库后才替换目标切片。CocoaPods 执行 Make 时自动完成；后续使用缓存。修改构建脚本或重新解压框架后会重新构建。生成物不提交 Git。

`tool/application_playback_probe.dart` 使用应用的实际后端工厂和回退顺序，默认开启声音。libmpv 必须有实际输出驱动、输出 PCM 参数和非零音量；Android 原生后端必须收到音频播放位置推进回调。配置 `testPauseResume: true` 可验证直播暂停恢复。短样本不应启用该选项，以免将正常播放结束误判为恢复失败。

原生库版本升级时，更新清单、各平台适配器中的固定值并重新运行矩阵。Windows 解压目录使用 SHA-256 标记，避免复用旧的裁剪 DLL；所有平台不应切回 `default` 构建来缩小包体。

### Android EGL 上下文兼容

部分 Android EGL 驱动拒绝固定版本 mpv 提交的零 `EGL_CONTEXT_FLAGS_KHR` 属性，即使基础 GLES 和 DEBUG 上下文均可创建，也会出现 `EGL_BAD_ATTRIBUTE` 和视频输出初始化失败。原生适配器在独立线程探测这三种请求，将结果通过 `com.tntlikely.xplayer/decoder_capabilities` 返回核心包，只有命中此驱动行为才启用 `gpu-debug=yes`。普通驱动保留原设置；DEBUG 上下文可能增加驱动检查开销，仅用于已证实失败的路径。

不修改模拟器全局 GPU 设置，也不强制所有设备使用软解。探测创建的 context 均立即销毁，工作线程释放 EGL 线程状态，但不终止 Flutter 正在使用的共享 display。原生端缓存结果，核心等待有超时，旧宿主缺少通道不会阻止播放。

上游实现参考：[固定版本 EGL 上下文创建](https://github.com/mpv-player/mpv/blob/v0.36.0/video/out/opengl/egl_helpers.c)、[mpv EGL 后续兼容处理](https://github.com/mpv-player/mpv/blob/master/video/out/opengl/egl_helpers.c)。
