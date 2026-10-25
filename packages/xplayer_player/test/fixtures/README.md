# HE-AAC 合成样本

这两个文件由项目自行生成，仅包含 4 秒、1 kHz、48 kHz 双声道正弦波，无第三方节目内容，按本包 MIT 许可证提供。用于固定 HE-AAC（SBR）和 HE-AAC v2（SBR + 参数立体声）的回归输入。

生成命令（macOS 自带 AudioToolbox 编码器）：

```sh
ffmpeg -f lavfi -i 'sine=frequency=1000:sample_rate=48000' -t 4 -ac 2 tone.wav
afconvert tone.wav aac-he-v1.m4a -f m4af -d aach -b 64000
afconvert tone.wav aac-he-v2.m4a -f m4af -d aacp -b 32000
```

`-b` 为编码器目标码率；简单音调的实际码率可能更低。FFmpeg 检查分别识别为 `HE-AAC`、`HE-AACv2`，输出采样率 48 kHz、双声道。文件中编码时间元数据使重新生成的字节可能不同，更新文件时应同步生成器中的 SHA-256。

生成器会校验这两个文件，再复制纯音频样本并封装为 H.264 + HE-AAC / TS。在 Windows、Linux 与 macOS 的 CI 中使用相同输入，无需安装额外 HE-AAC 编码器。
