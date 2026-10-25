# XPlayer 原生解码库

这里保留 media_kit 原生库适配器的最小本地分支。原始 Java、Swift、C++ 插件和 MIT 许可来自 media-kit/media-kit；改动集中在下载、校验和完整解码构建的选择，不修改 Flutter 渲染器或自行实现解码器。

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

`tool/generate_playback_fixtures.py` 生成包含 TrueHD 5.1、MLP、HEVC Main10、DTS、AC-3、E-AC-3、FLAC、ALAC、VP9、AV1、MPEG-2、WMV/WMA 等组合的样本。

`tool/check_decoder_compatibility.py` 校验实际音频解码参数、视频解码参数和至少一秒的时钟推进，进程超时单独标记失败。`.github/workflows/playback-compatibility.yml` 在 macOS、Windows、Linux 运行此矩阵，并在 Windows 构建应用以检查 CMake / ANGLE 集成；不能用这份配置代替尚未执行的 CI 结果。

`tool/playback_device_probe.dart` 额外验证 Flutter 渲染首帧、自动与强制软解两种模式。Android 测试使用单独应用 ID `.playbackprobe`，不覆盖用户播放器；测试静音，结果保存在应用支持目录的 `codec_probe.json`。iOS 模拟器的上游 libmpv 构建不含可用的音频输出驱动，解码/渲染检查需显式使用 `PLAYBACK_PROBE_NULL_AUDIO=true`，此结果不能代表扬声器或真实设备音频输出验证。生产默认始终使用系统音频输出。

原生库版本升级时，更新清单、各平台适配器中的固定值并重新运行矩阵。Windows 解压目录使用 SHA-256 标记，避免复用旧的裁剪 DLL；所有平台不应切回 `default` 构建来缩小包体。
