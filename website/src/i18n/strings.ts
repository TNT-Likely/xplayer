// 站点文案(中英)。页面只取字符串渲染,改文案改这里即可。
export type Locale = 'en' | 'zh';

const REPO = 'https://github.com/TNT-Likely/xplayer';
const RELEASES = `${REPO}/releases/latest`;
const APPSTORE = 'https://apps.apple.com/app/id6783271337';
const DONATE = `${REPO}#-捐赠--donate`;
const LAST_UPDATED = '2026-07-14';

const en = {
  site: {
    brand: 'XPlayer',
    tagline: 'A free, open-source IPTV / M3U player for all your screens.',
    repo: REPO,
    releases: RELEASES,
    appStore: APPSTORE,
    donate: DONATE,
    langSwitchHref: '/zh/',
    langSwitchLabel: '中文',
  },
  nav: { home: 'Home', privacy: 'Privacy', terms: 'Terms', support: 'Support' },
  index: {
    heroTitle: 'Watch IPTV anywhere, on any screen.',
    heroSubtitle:
      'XPlayer is a free, open-source IPTV / M3U player. Bring your own playlists or start with built-in public lists — with channel grouping, search, EPG, favorites, and phone-to-TV remote input.',
    ctaAppStore: 'Download on the App Store',
    ctaDownload: 'Other platforms',
    ctaGithub: 'GitHub',
    platforms: 'Android (phone / tablet / TV) · iOS / iPad · macOS · Windows · Linux',
    appStoreNote: 'iOS, iPad and macOS: get it from the App Store. Android, Windows and Linux: download from GitHub Releases.',
    availabilityNote:
      'The App Store release is currently available outside mainland China only — a mainland China listing requires an ICP filing, and our filing quota is used up for now. Want it on the mainland China App Store? You can help cover the filing and server costs by',
    donateLabel: 'donating',
    donateSuffix: '.',
    featuresTitle: 'Features',
    features: [
      { h: '📺 Bring your own / built-in sources', p: 'Import any M3U / M3U8 (URL or local file), or one-tap add public lists from open-source projects like iptv-org.' },
      { h: '🔎 Grouping & search', p: 'Filter by group and search by name — find what you want fast even with thousands of channels.' },
      { h: '🗓️ EPG', p: 'XMLTV programme guide support, with a clean empty state when a channel has no guide.' },
      { h: '⭐ Favorites', p: 'One-tap favorite the channels you watch most.' },
      { h: '🖥️ Every platform', p: 'One codebase for Android (incl. TV), iOS / iPad, macOS, Windows and Linux.' },
      { h: '📱 Phone-to-TV remote', p: 'Type on your phone, send to the TV on the same network in real time.' },
    ],
    shotsTitle: 'Screenshots',
    shots: [
      { src: '/screenshots/home.png', alt: 'XPlayer channel grid', caption: 'Browse, group & search channels' },
      { src: '/screenshots/player.png', alt: 'XPlayer playing a live channel', caption: 'Live playback, simple controls' },
      { src: '/screenshots/search-en.png', alt: 'XPlayer channel search', caption: 'Instant search by name' },
      { src: '/screenshots/groups-en.png', alt: 'XPlayer channel groups', caption: 'Jump to any group' },
      { src: '/screenshots/remote-en.png', alt: 'XPlayer phone-to-TV remote', caption: 'Type on your phone, send to TV' },
    ],
    shotsMoreTitle: 'iPad & macOS screenshots',
    shotsMore: [
      { src: '/screenshots/ipad-home.png', alt: 'XPlayer on iPad — channel grid' },
      { src: '/screenshots/ipad-player.png', alt: 'XPlayer on iPad — live playback' },
      { src: '/screenshots/ipad-groups-en.png', alt: 'XPlayer on iPad — channel groups' },
      { src: '/screenshots/mac-home.png', alt: 'XPlayer on macOS — channel grid' },
      { src: '/screenshots/mac-player.png', alt: 'XPlayer on macOS — live playback' },
      { src: '/screenshots/mac-groups-en.png', alt: 'XPlayer on macOS — channel groups' },
    ],
  },
  privacy: {
    title: 'Privacy Policy',
    lastUpdated: `Last updated: ${LAST_UPDATED}`,
    summary:
      'Short version: XPlayer is a local-first player. It has no account, no ads, no tracking, and no analytics server. Your data stays on your device.',
    sections: [
      { h: 'No account, no tracking', p: 'XPlayer does not require an account and does not collect, sell or share personal data. There is no advertising SDK and no analytics server operated by us.' },
      { h: 'Data stored on your device', p: 'Your playlists, favorites and settings are stored locally on your device only. Uninstalling the app removes them.' },
      { h: 'Network requests', p: 'XPlayer connects to the internet only to: (1) fetch the playlist / EPG you add or the built-in public lists; (2) play video streams directly from their source servers; (3) check GitHub for app updates. Those third-party servers can see your IP address, as with any internet streaming — we do not control their privacy practices.' },
      { h: 'Local network (phone-to-TV)', p: 'The optional phone-to-TV remote uses local network (mDNS/Bonjour) discovery and stays within your own network. Nothing is sent to us.' },
      { h: 'Children', p: 'XPlayer is a general-purpose player and is not directed at children. Channel content comes from third-party sources you choose to add.' },
      { h: 'Contact', p: 'Questions about privacy? Open an issue on our GitHub repository.' },
    ],
  },
  terms: {
    title: 'Terms of Use',
    lastUpdated: `Last updated: ${LAST_UPDATED}`,
    sections: [
      { h: 'What XPlayer is', p: 'XPlayer is a media player. It does not host, provide, control or curate any channel or stream. It plays the playlists and streams that you choose to add.' },
      { h: 'Content sources', p: 'Built-in "recommended sources" only aggregate publicly available links from open-source projects (such as iptv-org). XPlayer is not affiliated with, and does not endorse, any channel or content provider. Channel availability and legality are determined by those third parties, not by XPlayer.' },
      { h: 'Your responsibility', p: 'You are responsible for ensuring that your use of any source or stream complies with applicable laws and the rights of content owners in your region. Do not use XPlayer to access content you are not authorized to access.' },
      { h: 'No warranty', p: 'XPlayer is provided "as is", without warranty of any kind. Streams may be unavailable, change, or stop working at any time. We are not liable for any loss arising from use of the app.' },
      { h: 'Open source', p: 'XPlayer is open-source software released under the MIT License. You may use, modify and distribute it under that license.' },
      { h: 'Takedown & contact', p: 'If you are a rights holder and believe a built-in source links to infringing content, open an issue and we will remove the relevant preset. Note that streams themselves are hosted by third parties, not by XPlayer.' },
    ],
  },
  support: {
    title: 'Support',
    lastUpdated: `Last updated: ${LAST_UPDATED}`,
    intro: 'Need help or want to report a problem? Here is the fastest way.',
    sections: [
      { h: 'Report a bug / request a feature', p: 'Open an issue on GitHub using the bug / feature templates. Please include your platform, app version and steps to reproduce.' },
      { h: 'A channel won’t play', p: 'Single channels often fail because the upstream source is dead — not the app. Try the "test" button (top-right) to filter dead channels, or switch to another source. Add your own M3U if a built-in list is unreliable in your region.' },
      { h: 'Add your own source', p: 'Open the side drawer → Playlists → add a playlist, then paste any M3U / M3U8 URL or pick a local file.' },
    ],
    contact: {
      h: 'Contact us',
      p: 'Have a question or need help? Email us directly — we usually reply within a day or two. You can also open a GitHub issue.',
      email: 'sunxiaoyes@outlook.com',
      github: 'https://github.com/TNT-Likely/xplayer/issues',
      githubLabel: 'GitHub issues',
    },
  },
  footer: {
    license: 'MIT Licensed',
    builtWith: 'Built with Flutter',
    note: 'XPlayer is a player only; channel content comes from third-party sources you choose to add.',
  },
};

// 中文文案(与 en 同结构)。
const zh: typeof en = {
  site: {
    brand: 'XPlayer',
    tagline: '免费、开源的跨平台 IPTV / M3U 播放器。',
    repo: REPO,
    releases: RELEASES,
    appStore: APPSTORE,
    donate: DONATE,
    langSwitchHref: '/',
    langSwitchLabel: 'English',
  },
  nav: { home: '首页', privacy: '隐私政策', terms: '用户协议', support: '支持' },
  index: {
    heroTitle: '随时随地,在任意设备上看 IPTV。',
    heroSubtitle:
      'XPlayer 是一个免费、开源的 IPTV / M3U 播放器。可导入你自己的播放列表,也可一键添加内置的公开直播源 —— 支持频道分组、搜索、EPG 节目单、收藏,以及手机遥控 TV 输入。',
    ctaAppStore: 'App Store 下载',
    ctaDownload: '其它平台',
    ctaGithub: 'GitHub',
    platforms: 'Android(手机 / 平板 / TV)· iOS / iPad · macOS · Windows · Linux',
    appStoreNote: 'iOS、iPad 与 macOS:请从 App Store 获取。Android、Windows、Linux:从 GitHub Releases 下载。',
    availabilityNote:
      'App Store 版本目前仅在中国大陆以外地区上架 —— 在大陆区上架需要 ICP 备案,而备案名额暂时已用完。希望它也能上架大陆区?可以通过',
    donateLabel: '捐赠',
    donateSuffix: '帮忙分担备案与服务器成本。',
    featuresTitle: '特性',
    features: [
      { h: '📺 自带源 / 内置源', p: '导入任意 M3U / M3U8(网络 URL 或本地文件),或一键添加 iptv-org 等开源项目的公开直播源。' },
      { h: '🔎 分组与搜索', p: '按分组筛选、按名称搜索 —— 频道再多也能快速找到想看的。' },
      { h: '🗓️ EPG 节目单', p: '支持 XMLTV 节目单;无节目单的频道有清晰的空状态。' },
      { h: '⭐ 收藏', p: '常看的频道一键收藏。' },
      { h: '🖥️ 全平台', p: '一套代码覆盖 Android(含 TV)、iOS / iPad、macOS、Windows、Linux。' },
      { h: '📱 手机遥控 TV', p: '在手机上打字,实时发送到同一局域网内的 TV。' },
    ],
    shotsTitle: '应用截图',
    shots: [
      { src: '/screenshots/home.png', alt: 'XPlayer 频道网格', caption: '浏览、分组与搜索频道' },
      { src: '/screenshots/player.png', alt: 'XPlayer 播放直播频道', caption: '简洁控制的直播播放' },
      { src: '/screenshots/search-zh.png', alt: 'XPlayer 频道搜索', caption: '按名称即时搜索' },
      { src: '/screenshots/groups-zh.png', alt: 'XPlayer 频道分组', caption: '一键直达任意分组' },
      { src: '/screenshots/remote-zh.png', alt: 'XPlayer 手机遥控 TV', caption: '手机打字,发送到 TV' },
    ],
    shotsMoreTitle: 'iPad 与 macOS 截图',
    shotsMore: [
      { src: '/screenshots/ipad-home.png', alt: 'iPad 频道网格' },
      { src: '/screenshots/ipad-player.png', alt: 'iPad 直播播放' },
      { src: '/screenshots/ipad-groups-zh.png', alt: 'iPad 频道分组' },
      { src: '/screenshots/mac-home.png', alt: 'macOS 频道网格' },
      { src: '/screenshots/mac-player.png', alt: 'macOS 直播播放' },
      { src: '/screenshots/mac-groups-zh.png', alt: 'macOS 频道分组' },
    ],

  },
  privacy: {
    title: '隐私政策',
    lastUpdated: `最后更新:${LAST_UPDATED}`,
    summary:
      '一句话:XPlayer 是本地优先的播放器,没有账号、没有广告、没有追踪、也没有我们运营的分析服务器。你的数据只留在你的设备上。',
    sections: [
      { h: '没有账号,没有追踪', p: 'XPlayer 无需注册账号,不收集、不出售、不分享个人数据;不含广告 SDK,也没有我们运营的分析服务器。' },
      { h: '数据只存在你的设备上', p: '播放列表、收藏、设置等仅保存在本地设备;卸载应用即清除。' },
      { h: '网络请求', p: 'XPlayer 仅在以下情况联网:(1)拉取你添加的播放列表 / EPG 或内置的公开直播源;(2)播放时直接从源服务器加载视频流;(3)向 GitHub 检查应用更新。和任何在线播放一样,这些第三方服务器能看到你的 IP 地址,其隐私行为不由我们控制。' },
      { h: '局域网(手机遥控 TV)', p: '可选的"手机遥控 TV"通过局域网(mDNS/Bonjour)发现设备,数据只在你自己的网络内流转,不会发送给我们。' },
      { h: '未成年人', p: 'XPlayer 是通用播放器,并非面向未成年人;频道内容来自你自行添加的第三方源。' },
      { h: '联系我们', p: '有隐私相关问题?请在我们的 GitHub 仓库提 issue。' },
    ],
  },
  terms: {
    title: '用户协议',
    lastUpdated: `最后更新:${LAST_UPDATED}`,
    sections: [
      { h: 'XPlayer 是什么', p: 'XPlayer 是一个媒体播放器。它不托管、不提供、不控制、也不编辑任何频道或直播流,只播放你自行添加的播放列表与流。' },
      { h: '内容来源', p: '内置「推荐源」只是聚合开源项目(如 iptv-org)中公开的链接。XPlayer 与任何频道或内容提供方无关联、不背书。频道是否可用、是否合法,由这些第三方决定,与 XPlayer 无关。' },
      { h: '你的责任', p: '你需自行确保对任何源或流的使用符合你所在地区的法律法规及内容版权方的权利。请勿使用 XPlayer 访问你无权访问的内容。' },
      { h: '免责声明', p: 'XPlayer 按「现状」提供,不作任何明示或默示担保。直播流可能随时不可用、变更或失效。我们不对因使用本应用产生的任何损失负责。' },
      { h: '开源协议', p: 'XPlayer 是基于 MIT 协议发布的开源软件,你可在该协议下使用、修改与分发。' },
      { h: '投诉与联系', p: '若你是权利人,认为某内置源指向了侵权内容,请提 issue,我们会移除相应预置项。请注意:直播流本身由第三方托管,而非 XPlayer。' },
    ],
  },
  support: {
    title: '支持',
    lastUpdated: `最后更新:${LAST_UPDATED}`,
    intro: '需要帮助或想反馈问题?这是最快的方式。',
    sections: [
      { h: '反馈 Bug / 提功能建议', p: '在 GitHub 用 Bug / 功能模板提 issue,请附上平台、App 版本和复现步骤。' },
      { h: '某个频道打不开', p: '个别频道打不开多是上游源失效,不是 App 的问题。可用右上角「测速」筛掉死频道,或换一个源;若某内置源在你所在地区不稳定,建议导入你自己的 M3U。' },
      { h: '添加自己的源', p: '打开侧边栏 → 播放列表 → 添加,然后粘贴任意 M3U / M3U8 网址或选择本地文件。' },
    ],
    contact: {
      h: '联系我们',
      p: '有问题或需要帮助?可直接发邮件给我们,通常 1~2 天内回复;也可以在 GitHub 提 issue。',
      email: 'sunxiaoyes@outlook.com',
      github: 'https://github.com/TNT-Likely/xplayer/issues',
      githubLabel: 'GitHub issues',
    },
  },
  footer: {
    license: 'MIT 协议',
    builtWith: '由 Flutter 构建',
    note: 'XPlayer 仅为播放器;频道内容来自你自行添加的第三方源。',
  },
};

export function t(locale: Locale) {
  return locale === 'zh' ? zh : en;
}
