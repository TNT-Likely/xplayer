import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:xplayer_ui/xplayer_ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 验收应用主动打开语义树；组件包本身不改变宿主的语义开关。
  SemanticsBinding.instance.ensureSemantics();
  runApp(const ComponentGallery());
}

class ComponentGallery extends StatelessWidget {
  const ComponentGallery({super.key});
  @override
  Widget build(BuildContext context) {
    const theme = XpThemeData(fontFamily: 'NotoSansSC');
    return XpTheme(
        data: theme,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'XPlayer · Flutter 组件验收',
          theme: theme.materialTheme(),
          home: const GalleryPage(),
        ));
  }
}

enum GallerySection {
  overview,
  foundation,
  channel,
  epg,
  player,
  management,
  boundaries
}

const sectionLabels = {
  GallerySection.overview: '设计总览',
  GallerySection.foundation: '基础操作',
  GallerySection.channel: '频道与内容',
  GallerySection.epg: '节目单',
  GallerySection.player: '播放控制',
  GallerySection.management: '列表与遥控',
  GallerySection.boundaries: '边界状态',
};
const sectionIcons = {
  GallerySection.overview: XpSymbol.home,
  GallerySection.foundation: XpSymbol.plus,
  GallerySection.channel: XpSymbol.channels,
  GallerySection.epg: XpSymbol.guide,
  GallerySection.player: XpSymbol.play,
  GallerySection.management: XpSymbol.remote,
  GallerySection.boundaries: XpSymbol.info,
};
const scenarioLabels = {
  'epg-loading': '节目单 · 加载中',
  'epg-unconfigured': '节目单 · 未配置',
  'epg-empty': '节目单 · 暂无数据',
  'epg-error': '节目单 · 失败，无缓存',
  'epg-cache': '节目单 · 失败，有缓存',
  'epg-stale': '节目单 · 缓存过期',
  'epg-partial': '节目单 · 部分缺失',
  'offline': '网络 · 离线',
  'list-empty': '列表 · 首次添加',
  'list-no-channels': '列表 · 无有效频道',
  'import-error': '列表 · 导入失败',
  'search-empty': '搜索 · 无结果',
  'favourites-empty': '收藏 · 尚无收藏',
  'player-connecting': '播放 · 正在连接',
  'player-buffering': '播放 · 缓冲中',
  'player-error': '播放 · 断流',
  'player-unsupported': '播放 · 格式不支持',
  'player-audio': '播放 · 仅音频',
  'remote-none': '遥控 · 未发现设备',
  'remote-permission': '遥控 · 权限受限',
  'sync-conflict': '同步 · 内容冲突',
};

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});
  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  GallerySection section = GallerySection.overview;
  XpDevice device = XpDevice.desktop;
  final query = TextEditingController();
  final demoSearch = TextEditingController();
  final address = TextEditingController(text: 'https://example.com/guide.xml');
  String? addressError;
  final scroll = ScrollController();
  final now = DateTime(2026, 10, 25, 20, 42);
  bool favourite = true, paused = false, toggle = true, busy = false;
  bool longText = false,
      noArtwork = false,
      noEpg = false,
      sourceRemoved = false;
  bool reducedMotion = false;
  XpEpgStatus epg = XpEpgStatus.ready;
  XpPlaybackPhase playback = XpPlaybackPhase.playing;
  XpRemoteStatus remote = XpRemoteStatus.connected;
  XpPlaylistStatus playlist = XpPlaylistStatus.ready;
  String category = '全部', scenario = 'epg-error';
  String lastEvent = '点击任意组件，查看真实回调与状态变化。';
  Set<String> syncSelection = {'playlists'};
  final Set<String> reviewed = {};
  int appliedFields = 0;
  Timer? recoveryTimer;

  static const syncFields = [
    XpSyncField(
        id: 'playlists', label: '播放列表', local: '3 个列表', remote: '4 个列表'),
    XpSyncField(
        id: 'favourites', label: '我的收藏', local: '3 个频道', remote: '8 个频道'),
    XpSyncField(id: 'quality', label: '默认画质', local: '自动', remote: '1080p'),
  ];

  XpChannelData get channel => XpChannelData(
        id: 'cctv9',
        name: longText ? 'CCTV-9 纪录 · 这是一个特别长的频道名称用于检查换行与可访问性' : 'CCTV-9 纪录',
        logoLabel: 'CCTV⁹',
        group: '纪录',
        quality: '4K',
        artwork:
            noArtwork ? null : const AssetImage('assets/images/forest.jpg'),
        programme: noEpg
            ? null
            : XpProgramme(
                title: longText ? '向野而生：在漫长旅途中寻找森林与生命的故事' : '向野而生',
                subtitle: '森林之境 · 第 3 集',
                start: DateTime(2026, 10, 25, 20),
                end: DateTime(2026, 10, 25, 21)),
      );

  List<XpEpgRowData> get epgRows {
    final yesterday = epg == XpEpgStatus.stale;
    final day = yesterday ? 24 : 25;
    XpProgramme show(
            String title, int hour, int minute, int endHour, int endMinute) =>
        XpProgramme(
            title: title,
            start: DateTime(2026, 10, day, hour, minute),
            end: DateTime(2026, 10, day, endHour, endMinute));
    return [
      XpEpgRowData(channel: channel, programmes: [
        show('向野而生', 20, 0, 21, 0),
        show('蓝色星球', 21, 0, 21, 45),
        show('晚间特别节目', 21, 45, 22, 30)
      ]),
      XpEpgRowData(
          channel: const XpChannelData(
              id: 'cctv13', name: 'CCTV-13 新闻', logoLabel: 'CCTV¹³'),
          programmes: epg == XpEpgStatus.partial
              ? []
              : [show('世界这一刻', 20, 30, 21, 0), show('环球视线', 21, 0, 21, 45)]),
      XpEpgRowData(
          channel: const XpChannelData(
              id: 'cctv5', name: 'CCTV-5 体育', logoLabel: 'CCTV⁵'),
          programmes: [
            show('绿茵之夜', 20, 0, 22, 0),
            show('体育世界', 22, 0, 22, 45)
          ]),
    ];
  }

  @override
  void dispose() {
    query.dispose();
    demoSearch.dispose();
    address.dispose();
    scroll.dispose();
    recoveryTimer?.cancel();
    super.dispose();
  }

  void event(String text) => setState(() => lastEvent = text);
  void selectSection(GallerySection value) {
    setState(() {
      section = value;
      query.clear();
    });
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  void recover(VoidCallback start, VoidCallback done) {
    recoveryTimer?.cancel();
    setState(start);
    recoveryTimer = Timer(const Duration(milliseconds: 850), () {
      if (mounted) setState(done);
    });
  }

  void _validateAddress() {
    final uri = Uri.tryParse(address.text.trim());
    final valid = uri != null &&
        ['http', 'https'].contains(uri.scheme) &&
        uri.host.isNotEmpty;
    setState(() {
      addressError = valid ? null : '请输入有效的 http 或 https 节目单地址。';
      lastEvent = valid ? 'onSubmitEpg · 地址格式有效' : 'onValidate · 保留输入并展示错误';
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = XpTheme.of(context).palette;
    return Scaffold(body: LayoutBuilder(builder: (context, box) {
      final wide = box.maxWidth >= 1050;
      return Row(children: [
        if (wide) SizedBox(width: 224, child: _sidebar()),
        Expanded(
            child: Column(children: [
          Container(
              padding: EdgeInsets.symmetric(
                  horizontal: wide ? 32 : 18, vertical: 16),
              decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: p.border))),
              child: Column(children: [
                Row(children: [
                  if (!wide) ...[
                    const Text('XPlayer',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 14)
                  ],
                  Expanded(
                      child: Text(
                          wide ? '设计系统 / ${sectionLabels[section]}' : '组件验收',
                          style: TextStyle(color: p.muted, fontSize: 12))),
                  const XpBadge('v0.1.0')
                ]),
                const SizedBox(height: 15),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final d in XpDevice.values)
                    XpChip(
                        label: switch (d) {
                          XpDevice.phone => '手机',
                          XpDevice.ipad => 'iPad',
                          XpDevice.desktop => '桌面',
                          XpDevice.tv => 'TV'
                        },
                        selected: d == device,
                        onPressed: () => setState(() => device = d)),
                ]),
                if (!wide) ...[
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: [
                        for (final s in GallerySection.values)
                          Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: XpButton(
                                  label: sectionLabels[s]!,
                                  onPressed: () => selectSection(s),
                                  variant: s == section
                                      ? XpButtonVariant.primary
                                      : XpButtonVariant.ghost))
                      ]))
                ],
              ])),
          Expanded(
              child: SingleChildScrollView(
                  controller: scroll,
                  padding: EdgeInsets.all(wide ? 32 : 18),
                  child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1400),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _heading(),
                                const SizedBox(height: 24),
                                XpSearchField(
                                    controller: query,
                                    onChanged: (_) => setState(() {}),
                                    hint: '查找组件名称，如按钮、频道、节目单…'),
                                const SizedBox(height: 22),
                                if (section == GallerySection.overview &&
                                    query.text.isEmpty)
                                  _overview(),
                                if (section != GallerySection.overview ||
                                    query.text.isNotEmpty)
                                  _catalogue(),
                                const SizedBox(height: 28),
                                Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                        color: p.surface,
                                        border: Border.all(color: p.border),
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: Text('最近回调  /  $lastEvent',
                                        style: TextStyle(
                                            color: p.muted,
                                            fontSize: 12,
                                            height: 1.8))),
                                const SizedBox(height: 18),
                                Text(
                                    'A · 静夜 / 真实 Flutter 组件 / 演示数据\n验收标记只记录本次会话。播放、网络、发现与同步由宿主接入。',
                                    style: TextStyle(
                                        color: p.quiet,
                                        fontSize: 11,
                                        height: 1.9)),
                              ]))))),
        ])),
      ]);
    }));
  }

  Widget _sidebar() {
    final p = XpTheme.of(context).palette;
    return Container(
        decoration:
            BoxDecoration(border: Border(right: BorderSide(color: p.border))),
        padding: const EdgeInsets.fromLTRB(18, 28, 18, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('XPlayer',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -1))),
          const SizedBox(height: 8),
          Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text('COMPONENT WORKSHOP',
                  style: TextStyle(
                      color: p.quiet, fontSize: 9, letterSpacing: 1.7))),
          const SizedBox(height: 36),
          for (final s in GallerySection.values)
            Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: XpNavigationItem(
                    label: sectionLabels[s]!,
                    icon: sectionIcons[s]!,
                    selected: section == s,
                    onPressed: () => selectSection(s))),
          const Spacer(),
          Divider(color: p.border),
          const SizedBox(height: 16),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('一个包 · 两层职责\n基础组件 → 业务展示\n四端共用，可独立验收',
                  style: TextStyle(color: p.muted, fontSize: 11, height: 2))),
        ]));
  }

  Widget _heading() {
    final p = XpTheme.of(context).palette;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('A / NOCTURNE · FLUTTER UI',
          style: TextStyle(color: p.quiet, fontSize: 10, letterSpacing: 2)),
      const SizedBox(height: 14),
      Text(
          section == GallerySection.overview
              ? '组件先行，界面有据。'
              : sectionLabels[section]!,
          style: const TextStyle(
              fontSize: 32, fontWeight: FontWeight.w500, letterSpacing: -.9)),
      const SizedBox(height: 12),
      Text('同一套设计语言，在手机、iPad、桌面与 TV 上保持一致。\n在这里检查状态、内容边界、键盘焦点与回调。',
          style: TextStyle(color: p.muted, fontSize: 13, height: 1.9)),
    ]);
  }

  Widget _inPreview(Widget child) => XpTheme(
        data: XpThemeData(device: device, reduceMotion: reducedMotion),
        child: FocusTraversalGroup(
            policy: ReadingOrderTraversalPolicy(),
            child: Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxWidth:
                            device == XpDevice.phone ? 390 : double.infinity),
                    child: child))),
      );

  Widget _overview() {
    final p = XpTheme.of(context).palette;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: 14, runSpacing: 14, children: [
        _metric('28', '原始 SVG 图标'),
        _metric('21', '代表边界场景'),
        _metric('4', '端侧密度'),
        _metric('${reviewed.length}', '本次已验收'),
      ]),
      const SizedBox(height: 28),
      _case(
          'FeaturedChannel',
          '首页节目头图',
          '频道身份、节目、播放入口与收藏组合；没有 EPG 时不补造节目。',
          _inPreview(XpFeaturedChannel(
              channel: channel,
              now: now,
              onPlay: () => event('onPlay(cctv9) · 示例回调'),
              englishTitle: 'Into the wild.',
              favourite: favourite,
              onFavouriteChanged: (v) => setState(() {
                    favourite = v;
                    lastEvent = 'onFavouriteChanged($v)';
                  })))),
      const SizedBox(height: 20),
      Text('设计基础', style: TextStyle(fontSize: 21, color: p.foreground)),
      const SizedBox(height: 16),
      Wrap(spacing: 10, runSpacing: 12, children: [
        for (final (name, color) in [
          ('Background', p.background),
          ('Surface', p.surface),
          ('Raised', p.raised),
          ('Border', p.border),
          ('Accent', p.accent),
          ('Foreground', p.foreground)
        ])
          Container(
              width: 132,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  border: Border.all(color: p.border),
                  borderRadius: BorderRadius.circular(10)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        height: 58,
                        decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(6))),
                    const SizedBox(height: 12),
                    Text(name, style: const TextStyle(fontSize: 11)),
                    const SizedBox(height: 5),
                    Text('#${color.toARGB32().toRadixString(16).substring(2)}',
                        style: TextStyle(fontSize: 10, color: p.muted))
                  ]))
      ]),
      const SizedBox(height: 24),
      XpNotice(
          title: '先在一个包内分层',
          description:
              'foundation.dart 导出通用基础；media.dart 导出业务展示。业务组件只接收展示数据和回调，后续需要跨产品复用时再拆分发布包。'),
    ]);
  }

  Widget _metric(String number, String label) => Container(
      width: 170,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          border: Border.all(color: const Color(0xff29382e)),
          borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(number,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w400)),
        const SizedBox(height: 7),
        Text(label,
            style: const TextStyle(color: Color(0xff8d9c8d), fontSize: 12))
      ]));

  Widget _case(String id, String title, String description, Widget child) {
    final p = XpTheme.of(context).palette;
    return Container(
        decoration: BoxDecoration(
            border: Border.all(color: p.border),
            borderRadius: BorderRadius.circular(14)),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 15, 12, 16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text(title,
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w500))),
                      Checkbox(
                          value: reviewed.contains(id),
                          semanticLabel: '$title 已验收',
                          onChanged: (v) => setState(() {
                                v == true
                                    ? reviewed.add(id)
                                    : reviewed.remove(id);
                              }))
                    ]),
                    const SizedBox(height: 2),
                    Text('Xp$id',
                        style: TextStyle(
                            fontSize: 10, color: p.accent, letterSpacing: .5)),
                    const SizedBox(height: 8),
                    Text(description,
                        style: TextStyle(
                            color: p.muted, fontSize: 12, height: 1.8)),
                  ])),
          Divider(height: 1, color: p.border),
          Padding(padding: const EdgeInsets.all(20), child: child),
        ]));
  }

  Widget _catalogue() {
    final cases = <(GallerySection, String, String, String, Widget)>[
      (
        GallerySection.foundation,
        'Button',
        '按钮',
        '主按钮、次按钮、禁用、加载；Tab / Enter / Space 可操作。',
        _buttons()
      ),
      (
        GallerySection.foundation,
        'TextField',
        '表单输入与错误',
        '地址格式在宿主校验，错误靠近输入，保留已输入内容。',
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          XpTextField(
              controller: address,
              label: 'XMLTV 地址',
              helper: '支持 http / https 地址；此处不发起网络请求。',
              error: addressError,
              keyboardType: TextInputType.url,
              onSubmitted: (_) => _validateAddress()),
          const SizedBox(height: 16),
          Align(
              alignment: Alignment.centerLeft,
              child: XpButton(label: '检查地址', onPressed: _validateAddress)),
        ]),
      ),
      (
        GallerySection.foundation,
        'SearchField',
        '搜索输入',
        '受控输入、清除、空结果和禁用。',
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          XpSearchField(
              controller: demoSearch,
              onChanged: (q) => event('onChanged("$q")')),
          const SizedBox(height: 12),
          XpToggleTile(
              title: '启动时恢复上次播放',
              description: '开关值与持久化由宿主控制。',
              value: toggle,
              onChanged: (v) => setState(() {
                    toggle = v;
                    lastEvent = 'onChanged($v)';
                  }))
        ])
      ),
      (
        GallerySection.foundation,
        'Chip',
        '分组与导航',
        '选中态、数量、横向编排与窄侧栏。',
        _navigation()
      ),
      (
        GallerySection.foundation,
        'Icon',
        '图标与状态标记',
        '与设计稿相同的 28 个矢量图标；纯图标按钮有可访问名称。',
        _icons()
      ),
      (
        GallerySection.foundation,
        'ConfirmDialog',
        '确认弹窗',
        '确认、取消与关闭路径；使用原生 Dialog 管理焦点。',
        XpButton(
            label: '打开确认弹窗',
            icon: XpSymbol.plus,
            onPressed: () => _confirm('确认移除此列表？', '这里只修改验收数据，取消不会触发移除回调。',
                () => event('onConfirm · 已确认演示操作')))
      ),
      (
        GallerySection.channel,
        'ChannelCard',
        '频道卡片',
        '收藏独立响应；长标题、无节目图和无节目单分别回退。',
        _channelCases()
      ),
      (
        GallerySection.channel,
        'FeaturedChannel',
        '节目头图',
        '四端字号与操作面积；保留同一份频道展示数据。',
        XpFeaturedChannel(
            channel: channel,
            now: now,
            epgStatus: noEpg ? XpEpgStatus.empty : XpEpgStatus.ready,
            onPlay: () => event('onPlay(${channel.id})'),
            englishTitle: 'Into the wild.',
            favourite: favourite,
            onFavouriteChanged: (v) => setState(() => favourite = v))
      ),
      (
        GallerySection.epg,
        'EpgStateView',
        '节目单与恢复',
        '区分首次加载、空数据、失败、有缓存、过期与部分缺失；时间比例来自真实区间。',
        _epgDemo()
      ),
      (
        GallerySection.epg,
        'ProgrammeBlock',
        '跨午夜节目',
        '跨日日期、非法时间范围和时间窗口裁切。',
        _midnightDemo()
      ),
      (
        GallerySection.player,
        'PlayerStatusView',
        '播放状态',
        '连接、缓冲、断流、格式不支持和音频状态。',
        _playerDemo()
      ),
      (
        GallerySection.player,
        'MiniPlayer',
        '迷你播放器',
        '暂停、展开、关闭各自回调；无 EPG 只展示频道身份。',
        XpMiniPlayer(
            channel: channel,
            paused: paused,
            epgStatus: noEpg ? XpEpgStatus.empty : XpEpgStatus.ready,
            onRestore: () => event('onRestore'),
            onTogglePause: () => setState(() => paused = !paused),
            onClose: () => event('onClose · 由宿主管理播放器生命周期'))
      ),
      (
        GallerySection.management,
        'PlaylistCard',
        '播放列表',
        '选中、更新中、更新失败、空列表和确认移除。',
        _playlistDemo()
      ),
      (
        GallerySection.management,
        'RemotePad',
        '遥控与权限',
        '未连接时按键禁用；权限拒绝与未发现设备分别呈现。',
        _remoteDemo()
      ),
      (
        GallerySection.management,
        'SyncDiffPanel',
        '同步差异确认',
        '只有确认后才发送已勾选项目；取消保留当前配置。',
        _syncDemo()
      ),
      (
        GallerySection.boundaries,
        'BoundaryStates',
        '边界状态实验室',
        '21 类代表边界；共享正式组件，恢复动作可交互。',
        _boundaries()
      ),
    ];
    final filtered = cases
        .where((c) => query.text.isNotEmpty
            ? '${c.$2} ${c.$3} ${c.$4}'
                .toLowerCase()
                .contains(query.text.toLowerCase())
            : c.$1 == section)
        .toList();
    if (filtered.isEmpty) {
      return XpEmptyState(
          title: '没有找到这个组件',
          description: '可以搜索中文名称或组件类名。',
          icon: XpSymbol.search,
          actionLabel: '清除搜索',
          onAction: () => setState(() => query.clear()));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final item in filtered)
        Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: _case(item.$2, item.$3, item.$4, _inPreview(item.$5)))
    ]);
  }

  Widget _buttons() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 12, runSpacing: 12, children: [
          XpButton(
              label: '立即观看',
              icon: XpSymbol.play,
              onPressed: () => event('onPressed(立即观看)')),
          XpButton(
              label: '配置节目单',
              onPressed: () => event('onPressed(配置节目单)'),
              variant: XpButtonVariant.secondary),
          XpButton(
              label: '稍后再说',
              onPressed: () => event('onPressed(稍后再说)'),
              variant: XpButtonVariant.ghost),
          const XpButton(label: '暂不可用', onPressed: null),
          XpButton(
              label: '重新获取',
              loading: busy,
              onPressed: () => recover(() {
                    busy = true;
                    lastEvent = 'onRetry · loading';
                  }, () {
                    busy = false;
                    lastEvent = 'onRetry · 演示完成';
                  })),
          XpButton(
              label: '移除列表',
              onPressed: () => event('onRemove'),
              variant: XpButtonVariant.danger),
        ]),
        const SizedBox(height: 18),
        XpToggleTile(
            title: '减少动态效果',
            description: '关闭非必要过渡；加载提示继续保留语义。',
            value: reducedMotion,
            onChanged: (v) => setState(() => reducedMotion = v)),
      ]);

  Widget _navigation() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final label in [
            '全部',
            '央视',
            '卫视',
            '新闻',
            '体育',
            '电影',
            '这是一个特别长的分组名称'
          ])
            XpChip(
                label: label,
                count: label == '全部' ? 128 : null,
                selected: category == label,
                onPressed: () => setState(() {
                      category = label;
                      lastEvent = 'onCategoryChanged($label)';
                    }))
        ]),
        const SizedBox(height: 24),
        ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Column(children: [
              XpNavigationItem(
                  label: '首页',
                  icon: XpSymbol.home,
                  selected: true,
                  onPressed: () => event('onNavigate(home)')),
              XpNavigationItem(
                  label: '我的收藏',
                  count: 3,
                  icon: XpSymbol.heart,
                  onPressed: () => event('onNavigate(favourites)'))
            ])),
      ]);

  Widget _icons() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, runSpacing: 12, children: [
          for (final icon in XpSymbol.values)
            Tooltip(
                message: icon.name,
                child: SizedBox(
                    width: 72,
                    height: 80,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          XpIcon(icon),
                          const SizedBox(height: 10),
                          Text(icon.name,
                              style: const TextStyle(
                                  fontSize: 10, color: Color(0xff8d9c8d)))
                        ])))
        ]),
        const SizedBox(height: 18),
        const Wrap(spacing: 10, runSpacing: 10, children: [
          XpLiveBadge(),
          XpBadge('缓存', tone: XpTone.warning),
          XpBadge('获取失败', tone: XpTone.error),
          XpBadge('已收藏', tone: XpTone.success)
        ])
      ]);

  Widget _channelCases() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          XpChip(
              label: '长文本',
              selected: longText,
              onPressed: () => setState(() => longText = !longText)),
          XpChip(
              label: '无节目图片',
              selected: noArtwork,
              onPressed: () => setState(() => noArtwork = !noArtwork)),
          XpChip(
              label: '无节目单',
              selected: noEpg,
              onPressed: () => setState(() => noEpg = !noEpg))
        ]),
        const SizedBox(height: 20),
        ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: XpChannelCard(
                channel: channel,
                now: now,
                epgStatus: noEpg ? XpEpgStatus.empty : XpEpgStatus.ready,
                onPlay: () => event('onPlay(${channel.id})'),
                favourite: favourite,
                onFavouriteChanged: (v) => setState(() {
                      favourite = v;
                      lastEvent = 'onFavouriteChanged($v)';
                    }))),
      ]);

  Widget _picker<T>(String label, T value, List<T> values,
          String Function(T) name, ValueChanged<T> changed) =>
      Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(label,
                style: const TextStyle(color: Color(0xff8d9c8d), fontSize: 12)),
            DropdownButton<T>(
                value: value,
                underline: const SizedBox(),
                borderRadius: BorderRadius.circular(8),
                items: values
                    .map((v) => DropdownMenuItem(
                        value: v,
                        child: Text(name(v),
                            style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (v) {
                  if (v != null) changed(v);
                })
          ]);

  Widget _epgDemo() =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _picker(
            '节目单状态',
            epg,
            XpEpgStatus.values,
            (s) => switch (s) {
                  XpEpgStatus.ready => '正常',
                  XpEpgStatus.loading => '首次加载',
                  XpEpgStatus.unconfigured => '未配置',
                  XpEpgStatus.empty => '无数据',
                  XpEpgStatus.error => '失败 / 无缓存',
                  XpEpgStatus.errorWithCache => '失败 / 有缓存',
                  XpEpgStatus.stale => '缓存过期',
                  XpEpgStatus.partial => '部分缺失'
                },
            (v) => setState(() => epg = v)),
        const SizedBox(height: 18),
        XpEpgStateView(
            status: epg,
            cachedAt:
                DateTime(2026, 10, epg == XpEpgStatus.stale ? 24 : 25, 19, 30),
            now: now,
            missingCount: 1,
            onWatch: () => event('onWatch · EPG 状态不阻止直播'),
            onConfigure: () =>
                _confirm('配置节目单', '验收只展示配置入口；XMLTV 下载与解析由宿主接入。', () {
                  setState(() => epg = XpEpgStatus.ready);
                  event('onConfigure');
                }),
            onRetry: () => recover(() => epg = XpEpgStatus.loading, () {
                  epg = XpEpgStatus.ready;
                  lastEvent = 'onRetry · 已恢复示例节目单';
                }),
            child: XpEpgTimeline(
                rows: epgRows,
                start:
                    DateTime(2026, 10, epg == XpEpgStatus.stale ? 24 : 25, 20),
                end: DateTime(
                    2026, 10, epg == XpEpgStatus.stale ? 24 : 25, 22, 30),
                now: now,
                stale: epg == XpEpgStatus.stale,
                onWatchChannel: (c) => event('onWatchChannel(${c.id})'),
                onProgramme: (p) => event('onProgramme(${p.title})'))),
      ]);

  Widget _midnightDemo() => XpEpgTimeline(
          rows: [
            XpEpgRowData(channel: channel, programmes: [
              XpProgramme(
                  title: '跨午夜的自然纪录',
                  start: DateTime(2026, 10, 25, 23, 30),
                  end: DateTime(2026, 10, 26, 0, 30)),
              XpProgramme(
                  title: '凌晨特别节目',
                  start: DateTime(2026, 10, 26, 0, 30),
                  end: DateTime(2026, 10, 26, 1, 30))
            ])
          ],
          start: DateTime(2026, 10, 25, 23),
          end: DateTime(2026, 10, 26, 2),
          now: DateTime(2026, 10, 26, 0, 10),
          onProgramme: (p) => event('跨日节目 ${p.title}'));

  Widget _playerDemo() =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _picker(
            '播放状态',
            playback,
            XpPlaybackPhase.values,
            (s) => switch (s) {
                  XpPlaybackPhase.playing => '播放中',
                  XpPlaybackPhase.paused => '已暂停',
                  XpPlaybackPhase.connecting => '正在连接',
                  XpPlaybackPhase.buffering => '正在缓冲',
                  XpPlaybackPhase.error => '连接失败',
                  XpPlaybackPhase.unsupported => '格式不支持',
                  XpPlaybackPhase.audioOnly => '仅音频'
                },
            (v) => setState(() => playback = v)),
        const SizedBox(height: 18),
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ColoredBox(
              color: Colors.black,
              child: XpPlayerStatusView(
                  phase: playback,
                  channelName: channel.name,
                  paused: paused,
                  onToggleAudio: () => setState(() => paused = !paused),
                  onRetry: () =>
                      recover(() => playback = XpPlaybackPhase.connecting, () {
                        playback = XpPlaybackPhase.playing;
                        lastEvent = 'onRetry · 演示恢复';
                      }),
                  onCancel: () => setState(() {
                        playback = XpPlaybackPhase.paused;
                        lastEvent = 'onCancel';
                      }),
                  onSwitchSource: () => event('onSwitchSource'),
                  onSwitchChannel: () => event('onSwitchChannel'))),
        ),
        if (playback == XpPlaybackPhase.playing ||
            playback == XpPlaybackPhase.paused)
          const XpNotice(
              title: '播放界面已就绪', description: '此处是 UI 验收，没有启动真实音视频流。'),
        const SizedBox(height: 18),
        if (playback == XpPlaybackPhase.playing ||
            playback == XpPlaybackPhase.paused) ...[
          XpPlayerControls(
              paused: paused,
              onTogglePause: () => setState(() => paused = !paused),
              onVolume: () => event('onVolume'),
              onChannels: () => event('onChannels'),
              onFullscreen: () => event('onFullscreen'),
              qualityLabel: '自动',
              onQuality: () => event('onQuality'),
              audioLabel: '国语',
              onAudio: () => event('onAudio'),
              onSleep: () => event('onSleep')),
          const SizedBox(height: 20),
          const Text('没有额外能力时的控制条',
              style: TextStyle(color: Color(0xff8d9c8d), fontSize: 12)),
          const SizedBox(height: 8),
          XpPlayerControls(
              paused: paused,
              onTogglePause: () => setState(() => paused = !paused)),
        ],
      ]);

  Widget _playlistDemo() =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _picker(
            '列表状态',
            playlist,
            XpPlaylistStatus.values,
            (s) => switch (s) {
                  XpPlaylistStatus.ready => '正常',
                  XpPlaylistStatus.updating => '正在更新',
                  XpPlaylistStatus.error => '更新失败',
                  XpPlaylistStatus.empty => '无有效频道'
                },
            (v) => setState(() => playlist = v)),
        const SizedBox(height: 18),
        if (sourceRemoved)
          XpEmptyState(
              title: '列表已从验收数据移除',
              description: '主工程与本地文件没有改变。',
              actionLabel: '恢复示例',
              onAction: () => setState(() => sourceRemoved = false))
        else
          XpPlaylistCard(
              name: '我的电视',
              channelCount: 128,
              updatedLabel: '今天 19:30 更新',
              selected: false,
              status: playlist,
              onSelect: () => event('onSelectPlaylist'),
              onRetry: () => recover(() => playlist = XpPlaylistStatus.updating,
                  () => playlist = XpPlaylistStatus.ready),
              onEdit: () => event('onEditPlaylist'),
              onRemove: () => _confirm('移除「我的电视」？', '取消会保留当前列表。此操作只影响验收数据。',
                  () => setState(() => sourceRemoved = true))),
      ]);

  Widget _remoteDemo() =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _picker(
            '连接状态',
            remote,
            XpRemoteStatus.values,
            (s) => switch (s) {
                  XpRemoteStatus.connected => '已连接',
                  XpRemoteStatus.searching => '搜索中',
                  XpRemoteStatus.notFound => '未发现设备',
                  XpRemoteStatus.permissionDenied => '权限受限',
                  XpRemoteStatus.disconnected => '连接断开'
                },
            (v) => setState(() => remote = v)),
        const SizedBox(height: 18),
        XpRemoteStatusView(
            status: remote,
            deviceName: '客厅电视',
            onRetry: () => recover(() => remote = XpRemoteStatus.searching,
                () => remote = XpRemoteStatus.connected),
            onPermissionHelp: () => _confirm(
                '局域网设置指引',
                '在系统设置中允许 XPlayer 访问局域网，再回到应用重新搜索。',
                () => event('onPermissionHelp')),
            onManualConnect: () => event('onManualConnect')),
        const SizedBox(height: 22),
        Center(
            child: XpRemotePad(
                connected: remote == XpRemoteStatus.connected,
                onCommand: (command) => event('onCommand(${command.name})'))),
      ]);

  Widget _syncDemo() =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        XpSyncDiffPanel(
            fields: syncFields,
            selectedIds: syncSelection,
            onSelectionChanged: (ids) => setState(() => syncSelection = ids),
            onApply: (ids) => setState(() {
                  appliedFields += ids.length;
                  lastEvent = 'onApply(${ids.join(', ')}) · 仅确认的字段';
                }),
            onCancel: () => setState(() {
                  syncSelection = {'playlists'};
                  lastEvent = 'onCancel · 已应用数不变';
                })),
        const SizedBox(height: 12),
        Text('本次确认应用：$appliedFields 项',
            style: const TextStyle(color: Color(0xff8d9c8d), fontSize: 12)),
      ]);

  Widget _boundaries() =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _picker('选择场景', scenario, scenarioLabels.keys.toList(),
            (s) => scenarioLabels[s]!, (v) => setState(() => scenario = v)),
        const SizedBox(height: 20),
        _boundaryContent(),
      ]);

  Widget _boundaryContent() {
    final epgMap = {
      'epg-loading': XpEpgStatus.loading,
      'epg-unconfigured': XpEpgStatus.unconfigured,
      'epg-empty': XpEpgStatus.empty,
      'epg-error': XpEpgStatus.error,
      'epg-cache': XpEpgStatus.errorWithCache,
      'epg-stale': XpEpgStatus.stale,
      'epg-partial': XpEpgStatus.partial
    };
    if (epgMap.containsKey(scenario)) {
      return XpEpgStateView(
          status: epgMap[scenario]!,
          cachedAt: DateTime(2026, 10, 25, 19, 30),
          missingCount: 3,
          onWatch: () => event('onWatch · 可继续选台'),
          onConfigure: () => event('onConfigure'),
          onRetry: () => event('onRetry · 验收回调'),
          child: XpNotice(
              title: '频道与节目内容保留',
              description: scenario == 'epg-stale'
                  ? '过期缓存只供参考，不标记为正在播出。'
                  : '局部数据失败不会清空其他有效内容。'));
    }
    if (scenario.startsWith('player-')) {
      return AspectRatio(
          aspectRatio: 16 / 9,
          child: ColoredBox(
              color: Colors.black,
              child: XpPlayerStatusView(
                  phase: {
                    'player-connecting': XpPlaybackPhase.connecting,
                    'player-buffering': XpPlaybackPhase.buffering,
                    'player-error': XpPlaybackPhase.error,
                    'player-unsupported': XpPlaybackPhase.unsupported,
                    'player-audio': XpPlaybackPhase.audioOnly
                  }[scenario]!,
                  channelName: channel.name,
                  onRetry: () => event('onRetryPlayer'),
                  onCancel: () => event('onCancelConnecting'),
                  onSwitchChannel: () => event('onSwitchChannel'),
                  paused: paused,
                  onToggleAudio: () => setState(() => paused = !paused))));
    }
    if (scenario.startsWith('remote-')) {
      return XpRemoteStatusView(
          status: scenario == 'remote-none'
              ? XpRemoteStatus.notFound
              : XpRemoteStatus.permissionDenied,
          onRetry: () => event('onSearchDevices'),
          onManualConnect: () => event('onManualConnect'),
          onPermissionHelp: () => event('onPermissionHelp'));
    }
    if (scenario == 'sync-conflict') return _syncDemo();
    if (scenario == 'offline') {
      return const XpNotice(
          title: '网络连接已断开',
          description: '本地列表与收藏仍可浏览；正在播放的流是否中断由实际播放器状态决定。',
          tone: XpTone.warning);
    }
    final (title, copy, label, icon) = switch (scenario) {
      'list-empty' => (
          '从第一个播放列表开始',
          '添加网络地址或导入本地 M3U 文件。',
          '添加播放列表',
          XpSymbol.sources
        ),
      'list-no-channels' => (
          '这个列表还没有可播放频道',
          '播放列表已添加，但没有读取到有效条目。',
          '检查播放列表',
          XpSymbol.channels
        ),
      'import-error' => (
          '这个列表暂时无法导入',
          '没有读取到有效 M3U 频道，原有列表与收藏已保留。',
          '修改地址',
          XpSymbol.info
        ),
      'search-empty' => (
          '没有找到这个频道',
          '保留关键词，允许清除分组与搜索条件。',
          '清除筛选',
          XpSymbol.search
        ),
      _ => ('喜欢的频道，留在这里', '点一下频道旁的爱心，收进你的专属清单。', '去找频道', XpSymbol.heart),
    };
    return XpEmptyState(
        title: title,
        description: copy,
        actionLabel: label,
        onAction: () => event('onAction($scenario)'),
        icon: icon,
        tone: scenario == 'import-error' ? XpTone.error : XpTone.neutral);
  }

  void _confirm(String title, String body, VoidCallback confirm) {
    final data = XpThemeData(device: device, reduceMotion: reducedMotion);
    showDialog<void>(
        context: context,
        builder: (dialogContext) => XpTheme(
            data: data,
            child: XpConfirmDialog(
                title: title,
                child: Text(body, style: const TextStyle(height: 1.8)),
                onCancel: () => Navigator.pop(dialogContext),
                onConfirm: () {
                  Navigator.pop(dialogContext);
                  confirm();
                })));
  }
}
