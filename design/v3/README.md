# v3 主应用接入

2026-10-25。基于 main 的 `b215395`，在独立设计工作区的 `v3` 分支接入 A / Nocturne，应用版本为 `3.0.0+1`。原主工作区没有 UI 实现改动；B/C 与 v1 设计快照保留。

## 分层与复用

| 层级 | 位置 | 职责 |
| --- | --- | --- |
| 基础组件 | `packages/xplayer_ui/lib/foundation.dart` | 语义色、尺寸、按钮、输入、反馈、焦点、导航 |
| 播放器业务展示组件 | `packages/xplayer_ui/lib/media.dart` | 频道、节目单、播放器控件、小窗、播放列表、遥控器、同步差异展示；仅接收数据与回调 |
| 应用适配 | `lib/presentation/adapters/` | 真实 Channel/Programme 到展示数据的转换、源状态、播放及收藏操作 |
| 页面编排 | `lib/presentation/screens/` | 首页、频道、EPG、收藏、设置、播放列表、遥控器与同步预览 |
| 既有服务 | `lib/providers/`、`lib/services/`、`lib/data/` | SQLite、M3U/XMLTV、播放引擎、重试与回退、收藏/最近、测速、同步、投屏、偏好 |

组件包保持独立，基础层不依赖业务展示层，不导入主应用、Provider、数据库或网络仓库。使用 `dart run tool/check_architecture.dart` 检查边界。现有 Flutter Web 验收目录继续作为组件浏览入口；这次接入验证使用真实原生主应用。

## 多端规则

共享语义色、组件、数据模型和动作；布局按窗口重排，输入方式单独判断。

| 场景 | 导航与布局 | 交互 |
| --- | --- | --- |
| 手机，宽度 <600 | 底部五项导航、单列内容、详情底部面板、EPG 默认列表 | 触摸 |
| 平板 / 中等窗口，600–1199 | 88 宽导航栏、自适应频道列数、EPG 默认时间轴 | 依宿主保留触摸或鼠标 |
| 桌面 / 大窗口，≥1200 | 224 宽侧栏、频道网格；内容区域足够宽时显示详情侧面板 | 鼠标、键盘 |
| TV，设备明确报告为电视 | 大字体、56 高控件、方向键焦点；宽屏 240 侧栏，960×540 等逻辑尺寸使用窄导航栏；矮窗口减少精选卡留白 | 方向键、确认、返回；焦点可滚动到屏幕外内容 |

宽窗口不会自动被识别为 TV，窄桌面窗口也保留鼠标输入方式。用户保存的强调色、网格大小、播放引擎、渲染模式、小窗和自动刷新偏好继续生效。

## 边界状态与旧逻辑

- 播放列表：初次无源、空列表、导入地址错误、文件导入、重复名称、加载、刷新失败、编辑、删除当前列表后切换。提交失败保留输入；频道加载按来源与请求代次隔离，旧请求不会覆盖新选择。
- EPG：未配置、加载、成功但为空、部分频道缺失、获取失败、失败但有缓存、缓存过期分别展示。单个频道没有节目单仍保留播放入口，不使用其他频道的节目冒充当前节目。
- 新增按 EPG 地址独立的磁盘缓存，写入使用临时文件替换。某源失败保留已有缓存，成功的空响应替换旧缓存，损坏缓存只影响该源。来源已删除的缓存不再参与匹配。
- 过期 EPG 只作历史参考，不显示为当前播出，不提供没有实现的回看。XMLTV 按实际时区展示，时间轴先转本地时间再对齐小时。
- 原播放器的请求头、源偏好、重试、有限回退、卡顿检测、音频、投屏、PIP 和诊断逻辑继续使用。仅替换状态页与控件外观。
- 返回小窗复用同一个播放后端。小窗位于 Navigator Overlay 内，弹窗期间隐藏；TV 与大字体的头部尺寸和原生视频区域同步调整。
- 遥控连接等待真实 WebSocket 握手；发现失败、权限、断开和重连分别反馈。局域网手动地址连接可独立于 mDNS 使用。同步预览只在确认后导入选中字段。
- 本轮新 A 页面文案以中文为基线。原语言偏好和已有本地化保留，新文案的完整英文翻译尚未补齐。

## 验收与复现

见 [验收记录](validation/README.md) 和 [原生结果 JSON](validation/native-results.json)。自动化入口：

```sh
flutter pub get
flutter test --no-pub test packages/xplayer_ui/test
cd packages/xplayer_ui
dart run tool/check_architecture.dart
flutter analyze --no-pub
cd example
flutter test --no-pub
```

`.github/workflows/ui.yml` 在 main / 大版本分支与相关 PR 上执行应用、组件和四视口目录回归，不访问私人局域网。

原生集成测试在专用模拟器中导入真实数据库与服务。先用 FFmpeg 生成本地 H.264/AAC 合成视频，再启动验收源：

```sh
mkdir -p .dart_tool/v3-qa/media
ffmpeg -f lavfi -i testsrc2=size=640x360:rate=25 \
  -f lavfi -i sine=frequency=440:sample_rate=48000 -t 90 \
  -c:v libx264 -pix_fmt yuv420p -c:a aac -movflags +faststart \
  .dart_tool/v3-qa/media/sample.mp4
python3 tool/v3_fixture_server.py --media .dart_tool/v3-qa/media/sample.mp4 \
  --port-file .dart_tool/v3-qa/server.json
```

从 `server.json` 获取临时端口，用另一终端运行：

```sh
flutter drive --no-pub -d '<专用模拟器 ID>' \
  --driver=test_driver/v3_driver.dart --target=integration_test/v3_app_test.dart \
  --dart-define=QA_DEVICE=phone --dart-define=QA_BASE_URL=http://127.0.0.1:PORT
```

Android 模拟器的地址改用 `http://10.0.2.2:PORT`，设备标识改为 `tv`；iPad 使用 `ipad`。合成流程会切换服务器 EPG 模式，三端应依次执行。该测试会清理专用设备中的测试数据，不要指定日常使用的设备。

真实播放列表测试使用 `integration_test/v3_lan_test.dart`，通过 `QA_PLAYLIST_URL` 和 `QA_CHANNEL_NAME` 传入用户授权的列表及频道；不在仓库写入个人来源。日志与完整原始截图位于忽略目录 `.dart_tool/v3-qa/`。测试结束后重新构建 `lib/main.dart` 并安装，避免把测试入口应用当成正常体验版本。
