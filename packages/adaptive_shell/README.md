# adaptive_shell

按「输入能力 × 屏幕宽度」判定界面骨架形态，把多端适配的分支收敛到唯一一处。

## 解决什么问题

多形态设计最常见的死法是 `if (isTV)` 散进几十个 widget。改一处形态要验四种
形态，标志位互相组合导致状态空间爆炸，最后没人敢改。

这个包的全部作用就是提供**唯一的形态分支点**，下游组件不再判断平台或尺寸，
只接受参数。

## 两条判定原则

**一、按输入能力判定，不按操作系统。**

Android TV 与平板可能是同一个 API level、同一块屏幕尺寸，靠 `Platform.isAndroid`
根本分不开。真正决定界面形态的是「有没有指针」——有指针就有悬停态，
只有方向键就必须处处可聚焦。

**二、先看输入，再看宽度。**

电视的物理分辨率往往比桌面还大（1920/3840）。若按宽度判会被归到
`ShellKind.expanded`，于是拿到一套需要鼠标悬停的界面——遥控器没法用。

## 用法

```dart
// 应用根部注入
InputModeScope(mode: detectInputMode(), child: MyApp())

// 唯一的形态分支
switch (resolveShell(context)) {
  ShellKind.compact  => CompactHome(vm),   // 手机 / 平板竖屏
  ShellKind.expanded => ExpandedHome(vm),  // 桌面 / 平板横屏
  ShellKind.tenFoot  => TenFootHome(vm),   // 电视
}

// 下游组件不分支，只接参数
ChannelCard(width: channelCardWidth(kind, screenWidth))
```

## 在桌面上调试 TV 布局

```dart
debugInputModeOverride = InputMode.remote;
```

不必每次往电视上装包。

## 测试

```bash
flutter test
```

15 条测试，其中一条专门钉住「电视分辨率再大也不能被归到 expanded」。
