# media3-decoder-ffmpeg-1.9.2.aar

AndroidX Media3 FFmpeg 音频软解扩展(预编译)。

- 版本：与项目 AndroidX Media3 1.9.2 对齐
- 来源：https://github.com/Davidona/StreamVault-IPTV （player/libs/，其 docs/FFMPEG.md 记录编译配置）
- 启用解码器：ac3, eac3, dca(DTS), mp2, mp3, truehd
- 用途：原生引擎(NativeVideoEngine)对设备无硬件解码器的音频(AC-3/E-AC-3/DTS/MP2 等)回退软解
- 许可：FFmpeg 为 LGPL-2.1（动态链接 .so）。app 内开源许可页含声明，见 lib/main.dart 的 LicenseRegistry 注册。
