import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xplayer/data/models/iptv_presets.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:xplayer/shared/components/x_text_button.dart';
import 'package:xplayer/utils/toast.dart';

/// 「推荐源」对话框：一键添加 iptv-org 预置直播源（运行时拉取）。
/// 用 XTextButton（TV 焦点封装），靠默认方向焦点遍历在 D-pad 下上下移动。
class PresetSourceDialog extends StatefulWidget {
  const PresetSourceDialog({super.key});

  @override
  State<PresetSourceDialog> createState() => _PresetSourceDialogState();
}

class _PresetSourceDialogState extends State<PresetSourceDialog> {
  final FocusNode _firstFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _firstFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _firstFocus.dispose();
    super.dispose();
  }

  String _presetName(AppLocalizations l, IptvPreset p) {
    switch (p.nameKey) {
      case 'presetChina':
        return l.presetChina;
      case 'presetSports':
        return l.presetSports;
      case 'presetNews':
        return l.presetNews;
      case 'presetAll':
        return l.presetAll;
      default:
        return p.fallbackName;
    }
  }

  Future<void> _addPreset(IptvPreset preset) async {
    // 先取依赖，再 pop，避免 await 后使用失效的 context
    final media = Provider.of<MediaProvider>(context, listen: false);
    final l = AppLocalizations.of(context)!;
    Navigator.of(context).pop();
    try {
      showToast(l.updatingChannels);
      // 按 URL 去重：已添加过的预置源直接切换，不重复创建
      final playlist =
          await media.addOrGetPlaylistByUrl(_presetName(l, preset), preset.url);
      final id = playlist.id;
      if (id != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('lastSelectedPlaylistId', id.toString());
        await media.updateCurrentPlaylist(id);
      }
      hideToast();
      showToast(l.channelsUpdatedSuccessfully);
    } catch (e) {
      showToast(l.channelsUpdateFailed(e.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: const Color.fromRGBO(34, 34, 34, 1),
      title: Text(
        l.recommendedSources,
        style: const TextStyle(color: Colors.white),
      ),
      content: FocusTraversalGroup(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < kIptvPresets.length; i++) ...[
                XTextButton(
                  focusNode: i == 0 ? _firstFocus : null,
                  text: _presetName(l, kIptvPresets[i]),
                  size: XTextButtonSize.large,
                  onPressed: () => _addPreset(kIptvPresets[i]),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 4),
              Text(
                l.presetDisclaimer,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      actions: [
        XTextButton(
          text: l.cancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
