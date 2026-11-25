# Android TV 原生复拍

2026-11-25。使用专用 Android TV API 36 ARM64 模拟器，分辨率 1920×1080，密度 320 dpi。复用续作验收时构建的 `lib/main.dart` 正常 Debug APK，应用版本为 `3.0.0+1`。频道、节目单和 H.264/AAC 视频来自本机合成源。APK SHA-256 为 `573f5cda469e0ef684e43f397b98588b4823151af703c718eb45809df3986919`。

方向键操作经 ADB 发给模拟器，逐步通过 UIAutomator 焦点树和 Android 输入法状态核对。PNG 来自模拟器原始截屏，GIF 由 `adb shell screenrecord` 录制的画面转换。

## 操作录像

| GIF | 实测流程 |
| --- | --- |
| [首页焦点与节目详情](tv-featured-focus.gif) | 从切换列表向下进入收藏，再向下到立即观看，向右到节目详情，按确认打开节目面板 |
| [搜索浏览、输入与退出](tv-search-navigation.gif) | 确认进入编辑，输入 `qa`，返回收起软键盘，向下退出至体育分类。重新进入后关键词仍为 `qa`，退出后可向左回到侧栏 |

## 原始截图

| 场景 | 截图 |
| --- | --- |
| 初次导入 | [空首页](screenshots/tv-empty.png) · [合成源地址](screenshots/tv-import-fixture.png) |
| 首页与焦点 | [节目单加载后的首页](screenshots/tv-home.png) · [收藏焦点](screenshots/tv-featured-favourite.png) · [立即观看焦点](screenshots/tv-featured-play.png) · [节目详情焦点](screenshots/tv-featured-details.png) · [打开节目详情面板](screenshots/tv-featured-details-panel.png) |
| 频道与节目单 | [频道页](screenshots/tv-channels.png) · [节目单部分缺失](screenshots/tv-epg-partial.png) |
| 搜索 | [浏览时键盘隐藏](screenshots/tv-search-browse.png) · [确认进入编辑](screenshots/tv-search-edit.png) · [输入关键词](screenshots/tv-search-query.png) · [向下退出到分类](screenshots/tv-search-exit.png) · [重新打开仍保留关键词](screenshots/tv-search-query-preserved.png) · [向左回到侧栏](screenshots/tv-search-sidebar.png) |
| 播放器 | [首次操作说明](screenshots/tv-player-entry.png) · [合成视频](screenshots/tv-player.png) · [1.2 秒后的画面](screenshots/tv-player-progress.png) · [播放器菜单](screenshots/tv-player-controls.png) |
| HTTP 404 | [失败页面及重试焦点](screenshots/tv-player-failed.png) |

两次合成视频截屏的画面区域发生变化。随后切换合成视频端点返回 HTTP 404，失败页自动聚焦「重试播放」，确认后服务端收到了新请求。此前的原生集成回归还覆盖实际视频尺寸、后端播放进度和同一后端小窗续播。 [TV 首页操作与搜索焦点](../../TV-FOCUS.md) · [原生集成测试](../../../../../integration_test/v3_app_test.dart) · [播放失败用例](../../../../../integration_test/player_failure_test.dart) · [合成源复现步骤](../../../README.md)
