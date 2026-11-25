# iPhone、iPad 与历史视觉证据

## 2026-11-25 iOS 原生回归

iPhone 17 Pro 和 iPad Pro 11 M5 均使用 iOS 26.5 模拟器。截图来自合成 M3U、XMLTV 和视频信号，共 24 张原始 PNG。iPad 另执行 HTTP 404 失败态验收。

- [iPhone 步骤动图](ios/iphone-acceptance.gif)，由 10 张验收截图逐帧串联，约 18 秒。
- [iPad 步骤动图](ios/ipad-acceptance.gif)，由 12 张验收截图逐帧串联，包含播放失败和打开来源面板，约 21 秒。

| 场景 | iPhone | iPad |
| --- | --- | --- |
| 空库与导入入口 | [截图](ios/screenshots/phone-empty.png) | [截图](ios/screenshots/ipad-empty.png) |
| 提交播放列表后返回首页 | [截图](ios/screenshots/phone-submitted-dialog.png) | [截图](ios/screenshots/ipad-submitted-dialog.png) |
| 有节目单的首页 | [截图](ios/screenshots/phone-home.png) | [截图](ios/screenshots/ipad-home.png) |
| 搜索筛选频道 | [截图](ios/screenshots/phone-channels.png) | [截图](ios/screenshots/ipad-channels.png) |
| 收藏频道 | [截图](ios/screenshots/phone-favorites.png) | [截图](ios/screenshots/ipad-favorites.png) |
| 节目单和缺少节目单的提示 | [截图](ios/screenshots/phone-guide.png) | [截图](ios/screenshots/ipad-guide.png) |
| 节目单 HTTP 503 后保留现有缓存 | [截图](ios/screenshots/phone-epg-error-cache.png) | [截图](ios/screenshots/ipad-epg-error-cache.png) |
| 节目单过期提示 | [截图](ios/screenshots/phone-epg-stale.png) | [截图](ios/screenshots/ipad-epg-stale.png) |
| 原生播放合成视频 | [截图](ios/screenshots/phone-player.png) | [截图](ios/screenshots/ipad-player.png) |
| 返回频道后小窗续播 | [截图](ios/screenshots/phone-mini.png) | [截图](ios/screenshots/ipad-mini.png) |
| 设置和语言入口 | [截图](ios/screenshots/phone-settings.png) | [截图](ios/screenshots/ipad-settings.png) |
| 视频 HTTP 404 失败页 | — | [截图](ios/screenshots/ipad-player-failed.png) |
| 从失败页打开来源面板时的画面 | — | [截图](ios/screenshots/ipad-player-sources.png) |

提交播放列表后，弹窗关闭并直接显示首页。两个设备分别保留了提交和首页两个检查点的原始文件。

[原生集成用例](../../../../integration_test/v3_app_test.dart) · [播放器失败态用例](../../../../integration_test/player_failure_test.dart)

## 2026-10-25 原生截图

| 设备 | 截图 |
| --- | --- |
| iPhone | [首页](../screenshots/phone-home.png) · [节目单更新失败后保留缓存](../screenshots/phone-epg-error-cache.png) · [小窗](../screenshots/phone-mini.png) |
| iPad | [节目单](../screenshots/ipad-guide.png) · [缺图时的频道卡片](../screenshots/channel-fallbacks-ipad.png) · [连接状态](../screenshots/player-loading-ipad.png) · [播放失败](../screenshots/player-failed-ipad.png) · [来源面板](../screenshots/player-sources-ipad.png) |
| Android TV | [正常应用首页](../screenshots/tv-normal-home.png) · [频道页](../screenshots/tv-channels.png) · [立即观看焦点](../screenshots/tv-featured-play.png) · [节目详情焦点](../screenshots/tv-featured-details.png) · [搜索浏览](../screenshots/tv-search-navigation.png) · [搜索退出到侧栏](../screenshots/tv-search-sidebar.png) · [播放失败](../screenshots/player-failed-tv.png) · [来源面板](../screenshots/player-sources-tv.png) |

[原生验收记录](../README.md) · [播放器反馈](../PLAYER-FEEDBACK.md) · [TV 焦点](../TV-FOCUS.md)

## 组件目录截图

- [手机组件总览](../../../components/screenshots/phone-overview.jpg)
- [桌面组件总览](../../../components/screenshots/desktop-overview.jpg)
- [TV 节目单组件](../../../components/screenshots/tv-epg.jpg)
