# 第三方组件与分发来源

本包中的 XPlayer 适配代码使用 `LICENSE` 中的 MIT 许可。由 media-kit 改编的插件、Android helper 和框架整理脚本保留原始版权头，上游 MIT 许可全文见 `UPSTREAM_LICENSE`。下载的原生组件使用各自许可，不由本包 MIT 许可替代。

源码包包含下载/校验/编译配方与 `native_builds.json`，不包含预编译 libmpv、FFmpeg、ANGLE 或构建缓存。

| 组件 / 平台 | 固定来源与构建信息 |
| --- | --- |
| media-kit 适配器 | [media-kit/media-kit](https://github.com/media-kit/media-kit)，原始适配版本 Android 1.3.8、Darwin 1.1.4、Windows 1.0.11；MIT 许可保留在本包 |
| Darwin 视频纹理桥接 | `media_kit_video 2.0.1` 的 iOS/macOS Swift 实现，保留源文件版权头及上游 MIT 许可；注册类名调整为 `LibmpvXplayerVideoPlugin`，由本插件负责视频通道 |
| libmpv 头文件 | [mpv 0.36.0](https://github.com/mpv-player/mpv/tree/v0.36.0/libmpv)，构建时从固定源生成，源码各文件版权与许可按原文适用 |
| Android libmpv / FFmpeg | [v1.1.11 发布](https://github.com/media-kit/libmpv-android-video-build/releases/tag/v1.1.11)，四种 ABI 的 full JAR；[mpv 配方](https://github.com/media-kit/libmpv-android-video-build/blob/1ecf5100ec0f75e1d0630f48851b85769c92eed2/buildscripts/scripts/mpv.sh)禁用 GPL，[FFmpeg full 配方](https://github.com/media-kit/libmpv-android-video-build/blob/1ecf5100ec0f75e1d0630f48851b85769c92eed2/buildscripts/flavors/full.sh)禁用 GPL/nonfree、启用 version3 |
| Darwin libmpv / FFmpeg 等 | [v0.6.0 发布与组件说明](https://github.com/media-kit/libmpv-darwin-build/tree/v0.6.0)，使用 video-full；上游说明列出 mpv/FFmpeg、libass、字体/文本库、TLS 与 XML 等组件及各自许可 |
| iOS 模拟器 mpv | 同一 mpv 0.36.0 源码重编 AudioUnit 切片；精确源码、依赖与补丁散列由 `ios/build_simulator_audio.py` 固定，FFmpeg 和真机切片沿用上述 Darwin 构建 |
| Windows libmpv | [zhongfly/mpv-winbuild 固定发布](https://github.com/zhongfly/mpv-winbuild/releases/tag/2026-10-25-baa3e11d42)，使用 LGPL 普通 x86_64 构建，精确资产和散列见清单 |
| Windows ANGLE | [固定 ANGLE 发布](https://github.com/alexmercerind/flutter-windows-ANGLE-OpenGL-ES/releases/tag/v1.0.1)，ANGLE 及随附组件使用各自许可 |
| Linux libmpv / FFmpeg | 系统发行版提供，版本、编译选项和许可取决于发行版，本包不分发系统 `.so` |

构建清单中的 SHA-256 用于固定所下载的字节；构建来源和许可说明用于追溯，不代表所有平台二进制具有完全相同的依赖或许可。分发最终应用时，应随所选择的原生产物保留组件通知与适用的源码、构建和许可资料。
