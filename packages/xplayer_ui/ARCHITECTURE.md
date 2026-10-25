# 包边界与设计映射

## 依赖方向

```text
Flutter + flutter_svg
        ↓
xplayer_ui / foundation
        ↓
xplayer_ui / components + 展示模型
        ↓
主应用适配器 / 独立验收应用
```

包不会导入 `package:xplayer/`、`xplayer_player`、Provider、数据库、文件系统或发现插件。`flutter_svg` 用于加载包内设计 SVG。`assets/backdrops/` 随包提供五张用户确认的 A 设计装饰图，作为缺图/加载失败的本地兜底；示例节目信息仍只在 `example` 中。

`tool/check_architecture.dart` 检查基础层反向依赖、应用/服务耦合，以及基础颜色与确认版 JSON 的一致性。

## 设计组件映射

| 设计资源 | Flutter API | 层 |
| --- | --- | --- |
| 色彩 / 间距 / 多端尺寸 / 动效 | XpPalette, XpSpace, XpMotion, XpThemeData, XpTheme | 基础 |
| 图标 | XpIcon, XpSymbol | 基础 |
| 容器 | XpSurface | 基础 |
| 主按钮 / 次按钮 / 图标按钮 | XpButton, XpIconButton | 基础 |
| 表单 / 搜索 / 开关 | XpTextField, XpSearchField, XpToggleTile | 基础 |
| 分组 / 导航 | XpChip, XpNavigationItem | 基础 |
| 标记 / 进度 / 空态 / 通知 / 弹窗 | XpBadge, XpProgress, XpEmptyState, XpNotice, XpConfirmDialog | 基础 |
| 频道身份与图像回退 | XpChannelIdentity, XpArtwork | 业务展示 |
| 频道卡片 / 收藏 / 直播 / 首页头图 | XpChannelCard, XpFavouriteButton, XpLiveBadge, XpFeaturedChannel | 业务展示 |
| 标题与浏览入口 | XpSectionHeading | 业务展示 |
| EPG 时间块 / 时间轴 / 数据状态 | XpProgrammeBlock, XpEpgTimeline, XpEpgStateView | 业务展示 |
| 播放阶段 / 控制 / 迷你播放器 | XpPlayerStatusView, XpPlayerControls, XpMiniPlayer | 业务展示 |
| 播放列表 | XpPlaylistCard | 业务展示 |
| 遥控 / 发现与权限状态 | XpRemotePad, XpRemoteStatusView | 业务展示 |
| 同步差异 | XpSyncDiffPanel | 业务展示 |

## 数据与服务责任

- `XpProgramme` 用绝对时间计算进度，非法区间不绘制进度；显示时间默认按设备本地时区格式化。
- 时间轴要求有界宽度。它按起止时间裁切窗口、保留空档，忽略非法节目区间；数据源的冲突消解在适配器完成。
- `XpEpgStateView.coverageEnd` 应传入缓存实际覆盖结束时刻，并传 `now`；不以“获取于今天”代替有效性检查。
- `XpChannelCard`、头图和迷你播放器需收到该频道真实的 `epgStatus`。部分频道未匹配时给对应频道传空节目，不清空其他频道。
- 收藏/开关/暂停/同步勾选为受控状态。宿主接收回调，操作成功后更新值；失败由宿主反馈。
- 播放与缓冲、自动重试上限、音轨/画质能力、设备权限、M3U/XMLTV 校验和持久化属于应用与播放器服务。
- 交互文案以已确认中文版为基线；多语言迁移需要由宿主提供相应文案适配。

## 何时拆成两个包

满足以下任一条件再拆：基础层有第二个真实产品消费者；需要独立发布节奏；业务层引入了其他产品不需要的依赖。拆分时先移动 `src/foundation` 与 `foundation.dart`，保持 API 名称和依赖方向稳定。

当前既保留独立包的复用能力，也避免两个包为同一份设计频繁联动发版。
