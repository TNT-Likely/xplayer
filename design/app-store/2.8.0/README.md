# XPlayer Pro 2.8.0

2.8.0 在 iPhone、iPad 和 Mac 的 App Store 版本中加入节目工作台。月度、年度和永久会员解锁相同功能。Apple 商店包通过 `APPLE_MEMBERSHIP=true` 开启购买，GitHub 下载包使用社区模式。

| 商店 | 月付 | 年付 | 永久买断 |
| --- | ---: | ---: | ---: |
| 人民币基准 | ¥6 | ¥22 | ¥30 |
| 香港 | HK$8 | HK$22 | HK$32 |
| 台湾 | NT$30 | NT$90 | NT$120 |
| 美国 | US$0.99 | US$2.99 | US$3.99 |

价格来自 2026 年 11 月 27 日的 App Store Connect 商品档位。中国大陆区当日显示缺少 ICP 备案。运行时价格以 Apple 账户所在商店返回的金额为准。

## 权益与购买

- 工作台支持跨播放列表查找频道、按节目名查找正在播和即将播出的节目，以及保存关键词，持续查看最新节目单中的匹配场次。节目来自用户导入的 XMLTV。2.7.0 的播放、列表、收藏和基础节目单继续免费。
- 月付和年付位于同一 `XPlayer Pro` 订阅群组、同一级别。商品 ID 分别是 `com.tntlikely.xplayer.pro.monthly` 和 `com.tntlikely.xplayer.pro.yearly`。永久商品 `com.tntlikely.xplayer.pro.lifetime` 是非消耗型内购。
- 永久方案位于首位，明确标注一次买断。以基准价计算，买断比一年多 ¥8，第五次月付时累计支出与买断相同。月付和年付在选择时显示续订周期。已有订阅的用户购买永久前会看到取消续订的提示。
- 使用 StoreKit 2 验证苹果签名交易，支持 iOS 或 iPadOS 15、macOS 12 及以上。退款、订阅到期和跨设备恢复通过 StoreKit 刷新。付款、价格和购买状态不经过 XPlayer 服务器。
- 上线后可用 App Store Connect「销售和趋势」跟踪各商品首次购买、退款、收入和订阅续期。判断永久方案表现时，同时看新增付费人数和净收入。

## 验证

在项目指定的 Flutter 版本运行 `flutter test`。iOS 的 `RunnerTests.testStoreKitMembershipLifecycle` 使用 [本地 StoreKit 配置](../../../ios/RunnerTests/XPlayerPro.storekit) 验证购买、恢复、到期和退款。商品面向审核的操作入口是侧边栏的 XPlayer Pro 和节目工作台。

审核可手动导入[演示播放列表](https://xplayer.beejz.com/sample-guide.m3u)，搜索 Bunny 并追踪关键词。示例使用测试视频和滚动的虚构节目表。用户自行导入后才会出现示例频道。

## 2.8.0 验收记录

- 正式构建由主分支 `751d2e1` 生成，两端均使用构建号 67。[Apple 签名构建与上传](https://github.com/TNT-Likely/xplayer/actions/runs/45910568173)
- Flutter 回归 180 项通过。iOS 模拟器使用 Apple StoreKit Test 实际购买三个商品，并验证恢复、停止续订后到期、永久权益共存和退款撤权。macOS 已通过原生编译和签名上传。
- 在 iPhone 17 Pro 模拟器从侧边栏购买月度会员，导入测试列表，搜索 Bunny、保存关键词、刷新节目单并打开追踪结果。继续购买永久时出现原订阅续费提示，完成后从会员页恢复成功。此流程使用 Xcode 本地交易环境。
- 同一条发行流水线中，macOS 播放器独立包与解码检查通过。Windows 原生库下载失败，Linux 的 MP3 用例未通过。[Windows 构建日志](https://github.com/TNT-Likely/xplayer/actions/runs/45910568173/job/140217654335) · [Linux 解码日志](https://github.com/TNT-Likely/xplayer/actions/runs/45910568173/job/140217655643)
- Apple 已接收三张 1206 × 2622 的商品审核截图。素材对应美国商店价格。[永久会员](review/pro-lifetime.png) · [年付](review/pro-yearly.png) · [月付](review/pro-monthly.png) · [节目追踪实测](review/studio-following.png)

## 提审与发布

**当前发布设置为手动发布。** 2026 年 11 月 27 日 19:17（北京时间）回读 App Store Connect，iOS 和 macOS 2.8.0（67）均为 `MANUAL`。两端保留原审核单，iOS 正在排队，macOS 正在审核，月付、年付和永久商品都在排队。香港、美国和台湾公开商店均返回 2.7.0。会员权益重新确认后，再决定是否发布当前构建或提交新构建。

2026 年 11 月 27 日 07:35（北京时间）核对，iOS 和 macOS 2.8.0（67）均已提交，发布方式为审核通过后自动发布。订阅群组、月付、年付和永久商品与 iOS 版本一同送审。三个商品均返回 `WAITING_FOR_REVIEW`，当时香港、台湾和美国公开商店仍显示 2.7.0。[提审回执与价格核对](submission.json)
