# XPlayer 3.0 静夜验收证据

本页汇总 [PR #54](https://github.com/TNT-Likely/xplayer/pull/54) 的原生应用、组件目录和自动化验收。2026-11-25 同步 `main` 后的验证以 `372ba31` 为代码基线，首轮记录来自 2026-10-25 至 10-26。

| 内容 | 证据 |
| --- | --- |
| iPhone、iPad 与首轮截图 | [截图与动图清单](visual-index.md) |
| macOS 原生应用 | [桌面截图与验收步骤](macos/README.md) |
| Android TV 原生应用 | [方向键录屏与截图](tv/README.md) |
| 用例源码、执行范围与结果 | [测试用例与运行记录](test-cases.md) · [结果附件](results/) |
| Windows 构建、音视频解码、HTTP／HLS | [Windows CI](https://github.com/TNT-Likely/xplayer/actions/runs/45626571575) |
| Flutter UI 回归 | [PR CI](https://github.com/TNT-Likely/xplayer/actions/runs/45626502290) · [分支 CI](https://github.com/TNT-Likely/xplayer/actions/runs/45626493965) |
| 静夜设计与组件目录 | [设计归档](../../../xplayer-v1/README.md) · [原型验收记录](../../../xplayer-v1/QA.md) · [设计截图目录](../../../xplayer-v1/screenshots/) · [组件验收](../../../components/README.md) |

本轮新归档的原生媒体使用合成节目单与视频。iPhone、iPad 和 macOS 的 GIF 由各验收步骤的实际截屏串联。Android TV 的 GIF 来自专用模拟器录屏。首轮局域网和平台直播的结论保存在脱敏记录中。[首轮原生记录](../README.md) · [直播样本记录](../LIVE-SOURCES.md)

实体 TV、Linux 原生运行和真机跨设备联动仍待验收。[交接与恢复](../../HANDOFF.md)
