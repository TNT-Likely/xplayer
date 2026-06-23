# XPlayer 官网 / Website

XPlayer 的官方站点(落地页 + 隐私政策 + 用户协议 + 支持),用 [Astro](https://astro.build) 写,静态构建,托管在 Cloudflare Pages。中英双语:英文在根路径,中文在 `/zh/`。

> The official XPlayer site (landing + privacy + terms + support). Astro static site, hosted on Cloudflare Pages. Bilingual: English at root, Chinese under `/zh/`.

## 本地开发 / Local dev

```bash
cd website
pnpm install      # 或 npm install
pnpm dev          # http://localhost:4321
pnpm build        # 产物在 website/dist
```

## 部署到 Cloudflare Pages

在 CF Pages 关联本仓库,构建设置:

| 设置 | 值 |
|---|---|
| Root directory（根目录）| `website` |
| Build command（构建命令）| `npm run build`(或 `pnpm build`)|
| Build output（输出目录）| `dist`(即 `website/dist`)|

绑定自定义域名后,**记得把 `astro.config.mjs` 里的 `site` 改成真实域名** —— 这个域名会作为隐私政策 URL 填进 App Store Connect:
- 隐私政策:`https://你的域名/privacy`(中文 `/zh/privacy`)
- 用户协议:`https://你的域名/terms`

## 改文案 / Editing copy

几乎所有文字都在 `src/i18n/strings.ts`(中英两份,结构一致),页面只负责渲染。截图在 `public/screenshots/`。
