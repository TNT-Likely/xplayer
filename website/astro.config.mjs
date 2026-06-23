// XPlayer 官方站 —— 静态构建,托管在 Cloudflare Pages。
//
// i18n:默认 en(不带前缀),zh 走 /zh/* 前缀。
// 部署(Cloudflare Pages 关联 repo):
//   Build command   = npm run build      (或 pnpm build)
//   Build output    = website/dist
//   Root directory  = website
//
// ⚠️ 把下面的 site 换成你在 CF Pages 绑定的真实域名(会进 App Store 的隐私政策 URL)。

import { defineConfig } from 'astro/config';

export default defineConfig({
  site: 'https://xplayer.beejz.com',
  output: 'static',
  i18n: {
    defaultLocale: 'en',
    locales: ['en', 'zh'],
    routing: {
      prefixDefaultLocale: false, // / -> en;/zh/* -> zh
    },
  },
  build: {
    inlineStylesheets: 'auto',
  },
});
