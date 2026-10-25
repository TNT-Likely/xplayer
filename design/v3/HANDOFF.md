# v3 交接与恢复入口

交接日期：2026-10-26（验收主要完成于 10 月 25 日）。用户要求先开 PR、暂不合并，后续再恢复；本轮结束时清理专用测试资源。保留独立工作区和 `v3` 分支。

## 当前状态

- 工作区：`/Users/sunxiao/.codex/worktrees/xplayer-design-resources/xplayer`，分支 `v3`，应用版本 `3.0.0+1`。
- 基于 `main@b215395e3f06947b9c1dc735de4ebc995bdc77d6`。主工作区 `/Users/sunxiao/code/mine/xplayer` 保持 main 且干净。
- 本轮应用代码截止 `b181ba1`；后续交接提交仅包含文档与验收摘要。PR 链接与实际清理结果见 [交付状态](validation/DELIVERY.md)。
- 恢复前先获取远端，比较 main 新增提交，再决定合并 main 或变基；不要覆盖其他人的更新。未来用户明确同意合并后使用 **Squash merge**，本次不合并、不启用自动合并。
- 本仓库提交标题和正文使用中文；后续新建分支按 `feature/`、`fix/` 等用途命名。`v3` 是用户明确指定的大版本集成分支，继续保留。

## 设计与实现入口

| 内容 | 入口 |
| --- | --- |
| A / Nocturne 完整设计；B/C 概念保留 | [设计归档](../xplayer-v1/README.md) |
| 已发布 HTML 预览 | [四端设计预览](https://xplayer-design-studio-oct25.ivory-fox-4792.chatgpt.site/?style=nocturne&device=phone&page=home&state=normal) |
| Figma 资源库 | [设计文件](https://www.figma.com/design/g3InwuNMSszxmeHHWGKd2R) |
| Flutter 基础组件与业务展示组件 | `packages/xplayer_ui/lib/foundation.dart`、`media.dart` |
| 独立 Flutter 组件验收应用 | `packages/xplayer_ui/example/`；[说明](../components/README.md) |
| 多端布局与输入模式 | `lib/presentation/adaptive/` |
| 真实模型到组件的适配 | `lib/presentation/adapters/` |
| 主应用页面与播放器 | `lib/presentation/screens/` |
| 既有服务与工具 | `lib/providers/`、`lib/services/`、`lib/data/` |
| 多端规则、接入范围 | [集成说明](README.md) |

HTML 与 Figma 是设计资源快照；播放器状态和 TV 焦点的最新实现以本分支 Flutter 代码及验收记录为准，不代表云端设计文件已同步所有后续修订。

基础层只负责视觉、交互和受控状态；业务展示层只收数据与回调，不导入主应用、Provider、数据库或网络服务。布局按窗口宽度重排，TV 输入单独识别，不把所有宽屏当电视。旧数据库、播放内核、请求头、重试、源选择、测速、同步和投屏逻辑继续由主应用负责。

## 已完成的关键行为

- 首页、频道、节目单、收藏、设置、播放列表、遥控器和同步预览接入真实模型及服务。
- EPG 分源磁盘缓存，区分无配置、加载、空、部分缺失、失败、有缓存及过期；旧节目不会冒充正在播出。
- 无节目单卡片按内容收紧；缺图或坏图稳定回退到 A 设计的五张本地背景图，仍优先用真实图片。
- 连接、缓冲只显示中央小转圈并保留视频帧；失败反馈位于视频中央，操作随状态变化，最终失败停止后台恢复，避免重复动作和错误小窗。
- 播放源、画质、音轨、定时等选择面板统一样式，并适配小窗口、TV 和大字体。
- TV 首页显式连接“收藏 → 立即观看 ↔ 节目详情”；搜索先作为导航目标，确认后编辑，方向键或返回可退出编辑且保留关键词。详见 [TV 焦点记录](validation/TV-FOCUS.md)。

## 验证证据与实际边界

最新全量记录为主应用 **208 项**、UI 包 **23 项**、组件目录 **4 个视口 × 7 类**通过。最终定向回归为主页 11 项和 TV 导航 2 项通过；归档摘要见 [handoff-checks.json](validation/handoff-checks.json)。最终改动文件静态分析通过，旧播放器仍有既存 deprecated API 等 info，不能据此宣称整个仓库零 lint。

| 平台 / 场景 | 已验证 | 后续仍需验证 |
| --- | --- | --- |
| 手机 / iPad | 原生合成源、真实局域网列表、有效视频尺寸与推进、同后端小窗；iPad 失败态、缓冲态和声音 | 最后 TV 专项修改后未再次执行 iOS 原生全流程 |
| Android TV 模拟器 | 原生播放、失败态、选择面板；最终正常 APK 使用 Extended Controls 的方向盘与确认键验收首页及搜索 | 物理遥控器、物理 TV、长时间播放 |
| FLV / 平台直播 | 手机与 TV 各 6 个样本，包括 H.264/AAC、MP3、虎牙 FLV、B站 FLV/HLS | 签名过期后的来源需刷新；不保证所有房间和整份列表可用 |
| 桌面 / Web | 共享逻辑、四视口目录；macOS arm64 Debug 未签名构建 | 桌面原生运行、Windows/Linux 原生构建；Web FLV 能力 |
| 跨设备功能 | 真实回环 WebSocket、页面适配 | 真机局域网权限、Bonjour、DLNA、系统 PIP 等完整跨设备流程 |

新 A 页面以中文为基线，英文新文案尚未全部补齐。初次局域网测试使用过期 XMLTV；后续找到的 EPG 与订阅是独立配置交付，不内置为应用默认源。详情和脱敏截图见 [验收入口](validation/README.md)。

## 恢复开发

本机 SDK：`/Users/sunxiao/fvm/versions/3.41.9/bin/flutter`，Dart 3.11.5。先恢复依赖，再执行按层检查：

```sh
git switch v3
git fetch origin
git log --oneline HEAD..origin/main
flutter pub get
flutter test --no-pub test
cd packages/xplayer_ui
flutter pub get
dart run tool/check_architecture.dart
flutter analyze --no-pub
flutter test --no-pub
cd example
flutter pub get
flutter test --no-pub
```

查看正常应用使用 `flutter run -t lib/main.dart -d '<设备 ID>'`。组件目录需在 `packages/xplayer_ui/example/` 运行。CI 在 `.github/workflows/ui.yml`，不会访问私人局域网。

### 重建专用模拟器

测试资源清理后旧设备 ID 失效，创建后使用新返回的 ID。不需要重装已保留的系统运行时。

```sh
xcrun simctl create 'XPlayer UI QA Phone' \
  com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro \
  com.apple.CoreSimulator.SimRuntime.iOS-26-5
xcrun simctl create 'XPlayer UI QA iPad' \
  com.apple.CoreSimulator.SimDeviceType.iPad-Pro-11-inch-M5-12GB \
  com.apple.CoreSimulator.SimRuntime.iOS-26-5
avdmanager create avd -n XPlayer_V3_UI_TV \
  -k 'system-images;android-36;android-tv;arm64-v8a' -d tv_1080p
```

Android SDK 位于 `/Users/sunxiao/Library/Android/sdk`，`avdmanager` 位于 `cmdline-tools/22.0/bin/`。命令行未默认找到 Java 时，以 `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home'` 调用它。AVD 配置需有 `hw.keyboard=yes`、`hw.dPad=yes`、`hw.screen=no-touch`，1920×1080、density 320。修改后冷启动：

```sh
emulator -avd XPlayer_V3_UI_TV -port 5556 -gpu auto \
  -no-snapshot-load -no-boot-anim
```

`hw.keyboard=no` 曾导致 Emulator 右侧圆盘不能发出正常硬件键。ADB 注入成功不能替代 GUI 方向盘验证，最终记录已包含真实 GUI 点击。TV 原生画面用 `adb exec-out screencap -p` 获取；避免 Flutter 截图把视频 Surface 临时转换成静止 ImageView 后误判为播放器冻结。

iPad 无声曾是 Simulator 的音频输出固定到了旧显示器；将 Simulator 的 I/O → Audio Output 切到实际音箱后用户确认恢复。再次发生时先核对模拟器自身的输出路由；仅检查 Mac 默认设备不足以定位。

### 原生数据与播放验收

- 合成源与三端流程：[集成说明](README.md)，入口 `integration_test/v3_app_test.dart`。该流程会清专用设备应用数据，必须新建专用设备。
- 私人局域网：`integration_test/v3_lan_test.dart`，通过 `QA_PLAYLIST_URL`、`QA_CHANNEL_NAME` 传参；私人地址不提交到源码。
- 平台直播：[FLV 验收](validation/LIVE-SOURCES.md)，即时生成案例 JSON 后启动 `tool/live_source_fixture_server.py`。
- 保存测试播放列表：[导入步骤](validation/QA-PLAYLISTS.md)，入口 `integration_test/qa_playlists_test.dart`。
- 播放失败：`integration_test/player_failure_test.dart`，使用本地 404 资源验证真实失败流程。
- 需要保留应用数据的 `flutter drive` 必须加 `--keep-app-running`；测试完成后重新构建并覆盖安装 `lib/main.dart` 正常入口。默认 drive 清理可能卸载应用，不能用于用户日常设备。
- `test_driver/v3_driver.dart` 已关闭通信日志重复记录 base64 截图，避免日志膨胀。原始日志和短效流地址仅放忽略目录，脱敏后再归档。

## 保留的本地交付物

`releases/` 与 `design/publishing/` 属忽略的本地交付物，不随 PR 上传，但随本工作区保留。设计、HTML、截图和 manifest 的 Git 归档继续保留。用户已索要的 IPTV 配置包也保留：

| 文件 | SHA-256 |
| --- | --- |
| `releases/iptv-api-2026-10-25-expanded.zip` | `2a86bed2c1d7abb8b293bb08a5671dcd97cb9e3fd5d33e44d822dcdb9691576e` |
| `releases/iptv-api-2026-10-25.zip` | `54f405eb2e60c391d4a13b8a384c307e85b0cf1da514114ce046142d12902593` |

展开包包含订阅/EPG 配置、平台列表和 `platforms/refresh_flv.py`。恢复平台测试时按包内 README 重新创建虚拟环境并刷新 `flv-test.m3u`，不要依赖交付当日的短效签名。私人部署和局域网服务器未修改。

## 下次开始的建议顺序

1. 阅读本页与交付状态，确认 PR 仍保持草稿、分支已同步；拉取最新 main 后处理差异。
2. 恢复依赖，跑应用、组件包和目录检查；按需重建专用模拟器。
3. 先复测 TV 首页、搜索、播放器失败与重试，再做 iOS 最新正常入口回归。
4. 补齐英文文案、真机与跨设备验收，决定是否继续对齐云端设计稿；获得用户合并指令后再 Squash merge。
