import 'package:flutter/widgets.dart';
import 'package:xplayer/utils/hls_probe.dart';
import 'package:xplayer/shared/components/x_text_button.dart';
import 'package:xplayer/localization/app_localizations.dart';

/// null = 自动(播 master,交给 ExoPlayer ABR);否则为选定变体的媒体清单地址
typedef OnQualitySelectCallback = Future<void> Function(String? variantUrl);

/// 画质(多码率)选择列表。对齐 StreamVault 的「画质选择」:
/// 列出 master 清单里的各档分辨率,选定后直接播该档地址锁定画质。
class QualitySelectorWidget extends StatelessWidget {
  final List<HlsVariant> variants;

  /// 当前选定的变体地址;null 表示「自动」
  final String? currentUrl;
  final OnQualitySelectCallback onSelect;

  const QualitySelectorWidget({
    super.key,
    required this.variants,
    required this.currentUrl,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    // 按带宽降序(probe 已排序);这里再保险一次
    final sorted = [...variants]
      ..sort((a, b) => (b.bandwidth ?? 0) - (a.bandwidth ?? 0));

    Widget button({
      required String text,
      required bool selected,
      required String? url,
    }) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: XTextButton(
          text: text,
          size: XTextButtonSize.large,
          width: 180,
          onPressed: () {
            if (!selected) onSelect(url);
          },
          type: selected
              ? XTextButtonType.primary
              : XTextButtonType.defaultType,
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 自动
            button(
              text: l.qualityAuto,
              selected: currentUrl == null,
              url: null,
            ),
            // 各档
            ...sorted.map((v) {
              final label = v.bandwidthLabel.isNotEmpty
                  ? '${v.qualityLabel}  ·  ${v.bandwidthLabel}'
                  : v.qualityLabel;
              return button(
                text: label,
                selected: currentUrl == v.url,
                url: v.url,
              );
            }),
          ],
        ),
      ),
    );
  }
}
