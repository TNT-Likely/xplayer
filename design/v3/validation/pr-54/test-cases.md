# PR #54 测试用例与运行证据

2026-11-25 的续作记录对应 `v3` 同步主线后的这一轮实现。两个 UI CI 与 Windows 定向运行均关联代码提交 `372ba31`。本机测试日志和原生 JSON 来自同一轮验收，原生报告记录了机型、后端和通过的步骤。 [验收代码](https://github.com/TNT-Likely/xplayer/commit/372ba310eec9fa83525ce6737e3f811b56655f4c) · [交接记录](../../HANDOFF.md)

## 本机与 UI CI

| 检查 | 结果 | 证据 |
| --- | --- | --- |
| 主应用回归 | 212 项通过，覆盖播放源、EPG、首页、遥控、英文本地化、小窗及播放后端 | [完整运行输出](results/application-expanded.txt) · [主应用用例目录](../../../../test/) |
| 组件包 | 23 项通过，组件依赖边界与静态分析通过 | [组件用例目录](../../../../packages/xplayer_ui/test/) · [架构检查](../../../../packages/xplayer_ui/tool/check_architecture.dart) |
| 独立组件目录 | 390×844、1194×834、1440×960、1920×1080，四个视口各覆盖七类组件 | [视口用例](../../../../packages/xplayer_ui/example/test/gallery_test.dart) · [组件目录记录](../../../components/README.md) |
| GitHub Actions UI | PR 和分支推送两个运行均通过主应用、包边界和四视口检查 | [PR 运行](https://github.com/TNT-Likely/xplayer/actions/runs/45626502290) · [推送运行](https://github.com/TNT-Likely/xplayer/actions/runs/45626493965) · [工作流](../../../../.github/workflows/ui.yml) |

[CI 元数据](results/ci-runs.json)记录代码 SHA、运行地址、各 job 与步骤状态。主应用日志保留 Flutter 并发运行的原始进度和终值。

## 原生验收

| 环境 | 用例与结果 | 记录 |
| --- | --- | --- |
| iPhone 17 Pro / iOS 26.5 模拟器 | 合成 M3U/XMLTV 导入、EPG 缓存、搜索收藏、播放位置推进、同后端小窗通过。MediaKit 输出 640×360 | [iPhone](results/native/phone.json) |
| iPad Pro 11 M5 / iOS 26.5 模拟器 | 合成源主流程通过。MediaKit 输出 640×360。HTTP 404 后可重试、选择来源或频道，退出失败页不会进入小窗 | [iPad](results/native/ipad.json) · [404](results/native/ipad-failure.json) |
| macOS arm64 隔离沙盒 | 合成源主流程通过。MediaKit 输出 640×360，同一后端切到小窗 | [macOS](results/native/macos.json) |
| Android TV API 36 模拟器 | 合成源主流程与 HTTP 404 通过。NativePlayerBackend 输出 640×360，方向键重试发出新请求 | [TV](results/native/tv.json) · [404](results/native/tv-failure.json) |
| Android TV 正常应用入口 | ADB 方向键与 UIAutomator 核验首页焦点、节目详情、搜索确认、键盘收起、退出编辑保留关键词和返回侧栏 | [D-pad](results/native/tv-dpad.json) |

合成源流程还验证了非法播放列表地址保留输入、EPG 503 后保留有效缓存、过期节目失去正在播出标记，以及首次播放帮助可关闭。原生用例和合成数据入口见 [主流程](../../../../integration_test/v3_app_test.dart) · [404 失败页](../../../../integration_test/player_failure_test.dart) · [合成源服务](../../../../tool/v3_fixture_server.py) · [复现步骤](../../README.md)。

## Windows 定向 CI

| 检查 | 结果 | 证据 |
| --- | --- | --- |
| Windows 主应用 | 宿主测试和 Windows Debug 原生构建通过 | [主应用 job](https://github.com/TNT-Likely/xplayer/actions/runs/45626571575/job/139248261164) |
| 音视频解码 | 36/36 通过，包含 FLV、MP4、TS、MKV、纯音频、HLS、DASH 与 HLS fMP4 | [逐样本解码结果](results/windows/decoder-report.json) |
| HTTP／HLS | 7/7 通过，含请求头与重定向、HLS 签名和低码率恢复、慢首包、HTTP 403 归类、fMP4 与 DASH。403 是该用例的预期结果 | [逐样本传输结果](results/windows/transport-report.json) · [解码与传输 job](https://github.com/TNT-Likely/xplayer/actions/runs/45626571575/job/139248261112) |
| 独立包与新建宿主 | 11/11 项通过，含包外依赖解析、两个包的发布 dry-run、静态分析和测试、独立示例测试及 Windows 构建 | [逐步结果](results/windows/packaging-report.json) · [11 份步骤日志](results/windows/package-logs/) · [独立包 job](https://github.com/TNT-Likely/xplayer/actions/runs/45626571575/job/139248260596) |

本次工作流使用 `suite=windows`。最低依赖、Android 原生矩阵和 Apple 独立包影音输出步骤在这次定向运行中跳过。 [运行](https://github.com/TNT-Likely/xplayer/actions/runs/45626571575) · [原始解码附件](https://github.com/TNT-Likely/xplayer/actions/runs/45626571575/artifacts/15029306156) · [原始独立包附件](https://github.com/TNT-Likely/xplayer/actions/runs/45626571575/artifacts/15029381015) · [工作流](../../../../.github/workflows/playback-compatibility.yml)

## 用例源码索引

| 范围 | 用例入口 |
| --- | --- |
| 真实页面、布局、焦点与语言 | [窗口与输入模式、TV 搜索、英文清空最近播放、大字体](../../../../test/v3/adaptive_home_test.dart) · [Windows 清单复制粘贴与 Android 文件按钮焦点](../../../../test/playlist_dialog_test.dart) |
| EPG 与媒体数据 | [分源缓存和非法节目](../../../../test/v3/epg_repository_test.dart) · [空、失败、缺失、过期、时间与 XMLTV 地址](../../../../test/v3/media_presentation_test.dart) · [切换请求竞态和清除选择](../../../../test/v3/media_loading_test.dart) |
| 播放与遥控 | [小窗 Overlay](../../../../test/v3/mini_overlay_test.dart) · [选择面板与稳定源编号](../../../../test/v3/player_options_test.dart) · [回环 WebSocket 握手与断线](../../../../test/v3/remote_connection_test.dart) · [Windows 原生视图释放](../../../../test/player/video_player_backend_test.dart) · [宿主播放器用例目录](../../../../test/player/) |
| 组件契约 | [封面回退](../../../../packages/xplayer_ui/test/artwork_fallback_test.dart) · [EPG、可访问性、同步和遥控契约](../../../../packages/xplayer_ui/test/component_contract_test.dart) · [加载与失败状态](../../../../packages/xplayer_ui/test/player_status_test.dart) · [TV 焦点与搜索编辑](../../../../packages/xplayer_ui/test/tv_navigation_test.dart) |
| 原生依赖与独立包 | [播放器包用例目录](../../../../packages/xplayer_player/test/) · [原生包用例目录](../../../../packages/libmpv_xplayer/test/) · [固定资产与 SHA-256](../../../../packages/libmpv_xplayer/test/native_library_pins_test.dart) · [下载完整性和重试](../../../../tool/test_native_download.py) · [可复现打包](../../../../tool/test_package_player.py) |
| Windows 可重复输入 | [样本生成](../../../../packages/xplayer_player/tool/generate_playback_fixtures.py) · [解码验证](../../../../packages/xplayer_player/tool/check_decoder_compatibility.py) · [HTTP 与 HLS 回归](../../../../packages/xplayer_player/tool/check_stream_transport.py) · [独立包验证](../../../../tool/package_player.py) |
| 初次原生专项 | [局域网真实列表](../../../../integration_test/v3_lan_test.dart) · [保存验收列表](../../../../integration_test/qa_playlists_test.dart) · [FLV 与平台直播](../../../../integration_test/live_sources_test.dart) |

## 2026-10-25 初次验收

- 全量主应用 208 项、组件 23 项、四视口通过。后续定向主页 11 项、TV 导航 2 项通过。 [原生报告](../native-results.json) · [交接检查](../handoff-checks.json)
- 原有局域网列表、FLV 与平台直播分别留有实际测试结果、来源性质和复现入口。 [原生验收](../README.md) · [平台直播记录](../LIVE-SOURCES.md) · [直播样本结果](../live-playback.json) · [测试列表](../QA-PLAYLISTS.md) · [列表结果](../qa-playlists.json)
- iPad 声音、缓冲与播放器失败态，以及 TV 正常入口的方向键焦点和搜索退回均已归档。 [播放器反馈](../PLAYER-FEEDBACK.md) · [UI 状态巡检](../UI-STATE-AUDIT.md) · [状态结果](../ui-state-audit.json) · [TV 焦点](../TV-FOCUS.md) · [焦点结果](../tv-focus.json)
- 初次验收后的测试终端、模拟器与录制临时目录处理见 [交付](../DELIVERY.md) · [清理记录](../cleanup.json)。

实体 TV 与物理遥控器、Linux 原生运行、真实设备间的 Bonjour、DLNA、权限和系统画中画仍待验收。11 月 25 日续作使用合成源复测，平台直播与用户局域网结果以上面列出的 10 月 25 日记录为准。

归档内的原生 JSON 保留原始结果。应用日志移除了本机工作区前缀，Windows 报告与步骤日志将 CI 临时目录、测试地址及邮箱转换为相对路径或占位符。归档保留结果和日志，原生构建包仍可通过原始 CI 附件下载。
