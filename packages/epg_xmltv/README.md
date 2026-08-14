# epg_xmltv

XMLTV 电子节目单（EPG）解析与节目查找。

**纯 Dart，无 Flutter 依赖。**

## 覆盖 IPTV 客户端需要 EPG 做的全部事情

- 解析 XMLTV 文档为 `Programme` 列表
- 按频道检索节目（频道名匹配不区分大小写——不同源的大小写习惯不一致）
- 求「当前正在播」与「下一个」
- 解析 XMLTV 那套带时区偏移的时间格式（`20260814190000 +0800`）

## 用法

```dart
import 'package:epg_xmltv/epg_xmltv.dart';

final programmes = parseProgrammes(xmlString);

final (index, current, next) =
    PlaylistUtil.findCurrentAndNextProgramme(programmes, 'CCTV1');

current?.title;  // '新闻联播'
next?.title;     // '焦点访谈'
```

## 设计取舍

**没有节目单的频道返回空而不是抛异常。** 这在 IPTV 里是**多数情况**——
一份几千条的播放列表，通常只有几百条能匹配到 EPG。多数情况不该走异常路径。

**一条坏记录不该让整份节目单解析失败。** 时间格式非法时安全降级，
而不是让整个 XMLTV 文档解析中断。

## 已知问题

⚠️ `PlaylistUtil` 这个类名是历史遗留——它做的全是 EPG 节目查找，与播放列表无关。
抽包时保留原名以免一次性改动过大，后续可安全重命名为 `EpgLookup`。

## 测试

```bash
dart test
```

11 条测试，覆盖频道检索（含大小写）、当前/下一个、边界（恰在起点、无下一个、
时间越界、频道为 null）、XMLTV 时间解析与非法输入。
