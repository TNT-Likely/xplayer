# XPlayer 设计稿 → Figma 导入包

本目录包含全部 52 屏设计稿的**矢量 SVG 导出**（Figma 原生支持格式），以及导入说明。

## 资产清单（svg/ 目录，52 个文件）

| 文件名 | 内容 |
|---|---|
| `a-01` ~ `a-11` | 方向 A · ON AIR 演播室：home / player / groups / search / epg / sources / settings / info-cast / remote / lan-sync / splash |
| `b-01` ~ `b-11` | 方向 B · 暗夜客厅（同上 11 屏） |
| `c-01` ~ `c-11` | 方向 C · 频道指南（同上 11 屏） |
| `d-01` ~ `d-11` | 方向 D · 点阵 OSD（同上 11 屏） |
| `pad-a-studio` ~ `pad-d-osd` | Pad 横屏 1194×834（A/B/C/D 四方向） |
| `tv-a-studio` ~ `tv-d-osd` | Android TV 1920×1080（A/B/C/D 四方向） |

每个 SVG 都是分层矢量：矩形/文本/渐变/圆角/透明度均为独立元素，导入 Figma 后**文字可直接编辑**。

## 导入方式

### 方式一：直接拖入（最快，推荐先用这个）

1. 打开 Figma，新建/进入一个设计文件
2. 在访达里全选 `svg/` 下全部 52 个文件，拖到 Figma 画布
3. 每个 SVG 会变成一个 Frame，内部图层全部可编辑；按方向分 4 个页面（Page）整理即可

### 方式二：html.to.design 插件（还原度更高）

`html.to.design`（divRIOTS 出品，Figma Community 免费安装）能按渲染样式重建图层，对 CSS 的还原比 SVG 导入更接近源稿：

1. Figma 菜单 → Resources → Plugins → 搜索 **html.to.design** → 安装
2. 装它的 Chrome 扩展（官网 div RIOTS 提供下载），用它捕获本地地址
   `http://localhost:4173/index.html`（设计稿索引页）及各方向页
   —— 启动本地服务：在项目根目录执行 `python3 -m http.server 4173 --directory design`
3. 插件里点 Import，选择捕获的页面，导入后按方向分页整理

> 官方 Figma Dev Mode MCP 是反方向的（从 Figma 读取设计稿给代码用），不能用来往 Figma 里导入内容；社区的 "Talk to Figma" MCP 只能用基础图元拼装，对这种带渐变/玻璃质感的设计失真严重，不推荐。

## 字体（建议安装，均为 Google Fonts 免费）

Archivo（宽体字标/正文）· Spline Sans Mono · Manrope · Barlow · Chivo Mono · Doto（点阵数字）
中文：苹方（macOS 自带）/ Noto Sans SC。不装也能打开，文字会回退到默认字体导致宽度略变。

## 已知差异（SVG 导出特性）

- `backdrop-filter` 玻璃模糊会退化为半透明底色（视觉略清透，层次不变）
- LIVE 呼吸灯、跑马灯等 CSS 动画为静态帧
- 溢出裁剪（如横向滑动的 chips）已按原样裁切

## 重新导出

`svg-json/` 是导出的中间产物；如需重新生成：本地服务开着时，在任一设计稿页面控制台执行
`import('/vendor/dom-to-svg.mjs')`，对 `.screen / .mscr / .surface` 元素调用 `elementToSVG()`。
