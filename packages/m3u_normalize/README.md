# m3u_normalize

把 M3U / IPTV 播放列表里的机器标识清洗成人类可读的频道名，并把分号粘连的
`group-title` 拆成多标签。

**纯 Dart，无 Flutter 依赖。**

## 解决什么问题

**一、频道名是机器标识。** 很多播放列表把 `tvg-name` 直接设成 tvg-id，
界面上于是出现 `1KZNTV.ZA@SD`、`2MMONDE.MA@PLUS1`，全大写还会被截断成
`1PLUS1INTERNATIONA…`。

**二、分组是分号粘连的。** `Entertainment;Family;General` 被当成一个组名，
分组列表里于是出现大量只含一个频道的怪组，弹窗里还会溢出到看不全。

## 用法

```dart
import 'package:m3u_normalize/m3u_normalize.dart';

final d = normalizeChannel(
  tvgName: '1PLUS1INTERNATIONAL.UA@SD',
  title: '1+1 International',
);
d.name;    // '1+1 International'
d.quality; // 'SD'
d.region;  // 'UA'

splitGroupTitle('Entertainment;Family;General');
// ['Entertainment', 'Family', 'General']

splitGroupTitle('Undefined');
// []  —— Undefined 不是分组，是解析失败的残留
```

## 设计取舍

**按「像不像人话」打分挑候选字段，而不是硬编码 `tvg-name` 优先。**
不同播放列表习惯不一样：有的把好名字放 `title`，有的放 `tvg-name`，
还有的两个都填成 id。打分比固定顺序稳。

**单个全大写词不硬拆。** `DARETODREAMNETWORK` 无法可靠断词，
拆成 `Dare To Dream Network` 需要词典且容易出错，拆错比不拆更糟。
带空格的全大写串（`DARE TO DREAM NETWORK`）才做标题式转换。

**已知缩写保持全大写。** `CCTV`、`BBC`、`NHK` 等不会被转成 `Cctv`。

**清晰度与地区码从名字里剥出来**单独返回，交给界面上的角标和副行，
而不是留在名字里占位置。`@PLUS1` 这类时移变体不是清晰度，会留在名字中。

## 测试

```bash
dart test
```

29 条测试，覆盖候选选择、清晰度剥离、地区码剥离、大小写与分隔符、
以及各种非法输入。
