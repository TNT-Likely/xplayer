# A「静夜」组件实现与验收

沿用当前 `feature/xplayer-design-resources` 设计分支。

- [独立 Flutter 包](../../packages/xplayer_ui/README.md)
- [包边界与设计映射](../../packages/xplayer_ui/ARCHITECTURE.md)
- [自动验证记录](../../packages/xplayer_ui/VALIDATION.md)
- [在线组件验收](https://xplayer-design-studio-oct25.ivory-fox-4792.chatgpt.site/components/)
- [组件包源码下载](https://xplayer-design-studio-oct25.ivory-fox-4792.chatgpt.site/resources/xplayer-ui-0.1.0.zip)

一个独立包，内部区分基础层与业务展示层。验收应用直接使用同一份公开组件 API，展示四端密度、状态与回调，不另写一套 HTML 组件。

`design/xplayer-v1` 继续作为已确认设计来源；B/C 原有方案保留，本次只实现 A。未将新 UI 接入主应用。
