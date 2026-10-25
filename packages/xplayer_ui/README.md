# XPlayer UI · A「静夜」

独立 Flutter UI 包。视觉来自 `design/xplayer-v1` 已确认的 A 方案。独立验收应用在 `example/`，直接引用本包。

[在线组件验收](https://xplayer-design-studio-oct25.ivory-fox-4792.chatgpt.site/components/) · [原交互设计稿](https://xplayer-design-studio-oct25.ivory-fox-4792.chatgpt.site/) · [分层与接入约定](ARCHITECTURE.md)

## 分层决定

当前采用 **一个包、两层、三个入口**：

| 入口 | 职责 | 包含 |
| --- | --- | --- |
| `foundation.dart` | 与播放器领域无关的基础组件 | 主题与尺寸、原始 SVG、表面、按钮、输入、搜索、分组、导航、开关、标记、进度、反馈、弹窗 |
| `media.dart` | 频道与播放场景的展示组合 | 频道身份/卡片/头图、节目块/时间轴/EPG 状态、播放状态/控制条/迷你播放器、列表、遥控、同步差异 |
| `xplayer_ui.dart` | 便捷入口 | 导出以上两层 |

基础层不反向引用业务层。业务层只消费展示数据与回调，持久化、XMLTV/M3U 解析、播放器、发现、权限和同步服务由宿主提供。

暂不拆成两个发布包：当前两层服务于同一个 XPlayer 产品，共享设计版本；包内分层已能明确依赖。若基础层被其他产品使用，或两层需要独立版本周期，再提取 `xplayer_foundation`，并保持 `xplayer_ui → foundation` 单向依赖。

## 使用

宿主加入路径依赖：

```yaml
dependencies:
  xplayer_ui:
    path: packages/xplayer_ui
```

```dart
import 'package:flutter/material.dart';
import 'package:xplayer_ui/xplayer_ui.dart';

const ui = XpThemeData(device: XpDevice.phone);

XpTheme(
  data: ui,
  child: MaterialApp(
    theme: ui.materialTheme(),
    home: Scaffold(
      body: XpButton(label: '立即观看', onPressed: playSelectedChannel),
    ),
  ),
);
```

`XpTheme` 在 `MaterialApp` 之上，使弹窗路由也能读取相同设计变量。主题默认使用宿主字体；验收应用单独打包了 OFL 授权的 Noto Sans SC 字体子集。

## 独立运行与验证

本轮使用 Flutter 3.41.9 / Dart 3.11.5。组件包与验收应用均有自己的 pubspec，运行它们不需要启动主应用或原生播放器。

```sh
cd packages/xplayer_ui
flutter pub get
flutter test
dart run tool/check_architecture.dart

cd example
flutter pub get
flutter test
flutter run -d chrome
```

部署到设计站独立路径时：

```sh
cd packages/xplayer_ui/example
flutter build web --release --no-web-resources-cdn --base-href /components/
```

## 验收目录

- **设计总览：** A 方案语义色、节目头图、四端密度。
- **基础操作：** 主/次/禁用/加载按钮、URL 输入错误、搜索清除、开关、长分组、导航、28 个 SVG、标记和确认弹窗。
- **频道与内容：** 收藏/未收藏、长文本、无图片、无 EPG、头图。
- **节目单：** 8 种状态、时间比例、部分缺失、过期缓存、跨午夜节目。
- **播放控制：** 7 种播放阶段、音频暂停、重试/取消、能力受限的控制条、迷你播放器。
- **列表与遥控：** 更新/失败/无有效频道、确认移除、发现/权限/离线、禁用遥控、同步勾选与确认。
- **边界状态：** 与设计资源一致的 21 类代表状态。

验收标记仅存在于当前会话。示例画面、列表和设备为演示数据；组件事件会显示在页面下方。B/C 原有设计保留，此包只实现 A。

## 关键行为契约

1. 无 EPG 不显示未知节目标题、起止时间和节目进度；频道仍可播放。卡片按内容收口，列表不预留节目进度区。
2. 真实节目图优先；缺图、加载中或加载失败时显示包内 A 设计装饰图。按分组与频道 ID 稳定选择，首页与小窗共享回退；来源与校验值见 `assets/backdrops/SOURCES.json`。
3. 有缓存更新失败保留内容；覆盖时段已结束的缓存自动标成过期。`XpEpgStateView` 会向内部时间轴传递过期语义，移除当前时间线和“正在播出”。
4. 收藏与播放使用独立操作区域，不互相触发。
5. 加载按钮阻止重复提交；搜索清除会通知宿主，输入错误保留原值。
6. 控制条只展示传入了可用能力及回调的操作。UI 包不生成假画质或音轨。
7. 未连接遥控器不发送按键；权限不足与未发现设备分开呈现。
8. 同步只有确认后提交已存在且被勾选的字段，取消不提交。
9. TV 必须由宿主显式选择，不按大窗口宽度自动推断。使用 Flutter 焦点遍历与方向键，Enter/Space 激活；触控最小高度 44，TV 为 56。

## 接入阶段

组件包已在 `v3` 分支接入主应用；适配器将现有领域模型转换为 `XpChannelData` 等展示数据。实现与原生验收见仓库的 `design/v3/README.md`，边界约定见 `ARCHITECTURE.md`。
