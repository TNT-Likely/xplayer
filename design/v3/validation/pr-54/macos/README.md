# macOS 原生验收截图

2026-11-25 在 macOS arm64 隔离沙盒上，用 `372ba31` 的应用重跑原生合成源测试。实际应用视口为 800 × 600。视频由 `MediaKitBackend` 解码到 640 × 360，测试确认播放位置推进，返回频道后使用同一后端续播小窗。[原生结果](native-rerun.json) · [集成测试](../../../../../integration_test/v3_app_test.dart)

[首页、节目单、播放和小窗 GIF](macos-native-workflow.gif) 由十张原生实测截屏按步骤串联。全尺寸 PNG 如下。

| 验收画面 | 截图 |
| --- | --- |
| 空数据库与添加来源 | [空首页](screenshots/macos-empty.png) |
| 提交合成 M3U 后返回 | [提交后首页](screenshots/macos-submitted-dialog.png) |
| 首页节目与精选频道 | [首页](screenshots/macos-home.png) |
| 频道搜索与结果 | [频道](screenshots/macos-channels.png) |
| 收藏记录 | [收藏](screenshots/macos-favorites.png) |
| 由 M3U 文件头读取 XMLTV | [节目单](screenshots/macos-guide.png) |
| HTTP 503 后保留有效缓存 | [更新失败](screenshots/macos-epg-error-cache.png) |
| 过期节目的提示与时间轴 | [过期节目单](screenshots/macos-epg-stale.png) |
| 播放合成测试视频 | [播放器](screenshots/macos-player.png) |
| 返回频道后续播 | [小窗](screenshots/macos-mini.png) |
| 设置布局 | [设置](screenshots/macos-settings.png) |
