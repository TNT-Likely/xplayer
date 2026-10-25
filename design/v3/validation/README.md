# v3 原生验收记录

[补充：平台直播、HTTP FLV 与两端原生解码](LIVE-SOURCES.md)

[专用测试应用的局域网与 FLV 播放列表](QA-PLAYLISTS.md)

[iPad 声音路由排查与简化缓冲交互](PLAYER-FEEDBACK.md)

[UI 状态巡检与 TV 窗口验收](UI-STATE-AUDIT.md)

验收日期：2026-10-25。Flutter 3.41.9 / Dart 3.11.5。执行于独立工作区的 `v3` 分支。下列结果为本机实际执行记录。

| 检查 | 结果 |
| --- | --- |
| 主应用与组件测试 | 218 项通过，新增缺图/坏图回退和无 EPG 自然高度回归，含来源切换竞态、删除当前源、EPG 缓存、过期与时区、真实回环 WebSocket、小窗 Overlay、TV 与双倍字体 |
| 独立组件目录 | 手机 / 平板 / 桌面 / TV 四个视口，七类组件均渲染通过 |
| 包边界与静态分析 | 架构检查通过；组件包与新增页面、适配器、验收代码无分析问题；旧文件仍有既存 lint |
| iOS 手机 | iPhone 17 Pro / iOS 26.5；真实数据库、M3U/XMLTV、状态页、收藏、播放、同后端小窗通过 |
| iPad | iPad Pro 11 M5 / iOS 26.5；同上流程通过 |
| Android TV | API 36 / arm64；物理 1920×1080、逻辑 960×540；同上流程通过，使用 NativePlayerBackend |
| 用户局域网播放列表 | 三端都导入 538 个合并后频道；CCTV-13 实际解码 1920×1080、播放位置推进，返回小窗后后端实例相同 |
| macOS | arm64 Debug 未签名构建成功；常规本机签名因缺少匹配开发证书失败；未运行桌面应用 |

局域网 XMLTV 实际覆盖截止于 `2026-09-26T15:59:59Z`（本地 9 月 26 日 23:59:59），2557 条相关有效节目均属于过期缓存。因此真实源显示“节目单已过期”，不会伪造当前节目。验证范围为 CCTV-13 成功播放；不表示列表内所有源都可用。

原生合成测试额外验证了 EPG HTTP 503 后保留有效缓存、过期缓存提示、缺少节目单频道、非法 URL 保留输入与首次播放帮助关闭。播放器需要产生有效视频尺寸且播放位置推进，单纯打开页面不算播放通过。

自动输入通过 Flutter 测试输入通道完成，未覆盖操作系统输入法。真实设备的局域网权限弹窗、跨设备 Bonjour、DLNA、系统 PIP、物理电视和桌面运行时尚未在本轮逐一实测。Windows/Linux 仅有共用逻辑与视口测试，不宣称本机原生构建通过。

以下截图均来自主应用的原生合成源验收，不含用户局域网地址、原始列表或真实直播画面：

- [手机首页](screenshots/phone-home.png)
- [手机 EPG 失败保留缓存](screenshots/phone-epg-error-cache.png)
- [手机小窗](screenshots/phone-mini.png)
- [iPad 节目单](screenshots/ipad-guide.png)
- [TV 频道](screenshots/tv-channels.png)

截图记录对应验收时点；最终代码还包含窄导航栏标签与矮 TV 精选卡留白调整。正常 `lib/main.dart` 入口的 iOS / Android Debug 应用亦已重新构建、安装并启动，TV 使用系统原生 DPAD_DOWN / DPAD_CENTER 验证了导航切换。

## 缺图与无节目单修订

按用户反馈沿用 A 设计稿的五张背景图，修正固定网格/横排高度导致的节目单空白。新版已在 iPad 横屏重新执行真实局域网导入、频道、节目单、播放与小窗流程并通过；手机和 TV 视口及双倍字体回归通过。正常 iOS/Android 入口重新构建安装。

[实际频道页截图](screenshots/channel-fallbacks-ipad.png)（节目图缺失且节目单过期）。截图之后另为 LIVE 标记补了深色底，确保浅色背景上可读。
