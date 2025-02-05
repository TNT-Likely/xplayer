import 'package:flutter/widgets.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/shared/components/x_text_button.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

typedef OnSourceSwitchCallback = Future<void> Function(String link);

class ChannelSourceWidget extends StatefulWidget {
  final Channel channel;
  final String link;
  final OnSourceSwitchCallback? onSourceSwitch;

  const ChannelSourceWidget(
      {super.key,
      required this.channel,
      required this.link,
      this.onSourceSwitch});

  @override
  State<ChannelSourceWidget> createState() => _ChannelSourceWidgetState();
}

class _ChannelSourceWidgetState extends State<ChannelSourceWidget> {
  int currentIndex = 0;

  String getName(String name) {
    String modifiedTitle = name
        .toUpperCase()
        .replaceAll(widget.channel.id.toUpperCase(), '')
        .replaceAll(RegExp(r'^[-_]+'), '');
    currentIndex += 1;

    final hasId = name.toUpperCase().contains(widget.channel.id.toUpperCase());

    return !hasId
        ? '${AppLocalizations.of(context)!.source}$currentIndex'
        : modifiedTitle;
  }

  List<Source> get sources {
    return widget.channel.source
        .fold<Map<String, Source>>({},
            (Map<String, Source> map, Source source) {
          map[source.link] = source;
          return map;
        })
        .values
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: sources.map((e) {
        final isSelected = widget.link == e.link;

        return Column(
          children: [
            XTextButton(
              text: getName(e.title),
              size: XTextButtonSize.large,
              width: 160,
              onPressed: () {
                if (!isSelected && widget.onSourceSwitch != null) {
                  widget.onSourceSwitch!(e.link);
                }
              },
              type: isSelected
                  ? XTextButtonType.primary
                  : XTextButtonType.defaultType,
            ),
            const SizedBox(
              height: 8,
            ),
          ],
        );
      }).toList(),
    ));
  }
}
