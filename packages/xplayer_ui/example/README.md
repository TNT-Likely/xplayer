# 独立组件验收应用

此应用仅依赖 Flutter 与本地 `xplayer_ui` 包，展示的组件来自包的公开入口。

```sh
flutter pub get
flutter test
flutter run -d chrome
```

四端按钮调整组件密度；手机展示区最多 390 宽，其他端使用可用宽度。窗口响应式调整验收工具栏与目录，不把浏览器宽度当作 TV 判断依据。

勾选每个组件右上角的复选框记录当前会话验收进度。刷新后重置。回调在底部展示，没有接入实际播放、设备或配置服务。

`assets/fonts/NotoSansSC-Subset.ttf` 为 Noto Sans SC 的演示字形子集，原许可保存在同目录 `OFL.txt`。来源为 Google Fonts 官方仓库的 `ofl/notosanssc`；其作用仅限示例应用，组件包的宿主可使用自己的字体。

发布路径固定为 `/components/`，构建时使用 `--base-href /components/`。使用 `--no-web-resources-cdn` 让 Flutter 渲染引擎也由当前站点提供。

## 示例图片来源

沿用已确认设计稿的示例图片，仅用于组件演示。

- forest：https://images.unsplash.com/photo-1441974231531-c6227db76b6e
- mountain：https://images.unsplash.com/photo-1464822759023-fed622ff2c3b
- ocean：https://images.unsplash.com/photo-1518837695005-2083093ee35b
- city：https://images.unsplash.com/photo-1519501025264-65ba15a82390
- sport：https://images.unsplash.com/photo-1574629810360-7efbbe195018
