import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/data/models/channel_test_result.dart';
import 'package:xplayer/presentation/components/channel_plate.dart';
import 'package:xplayer/presentation/screens/player.dart';
import 'package:xplayer/shared/components/x_base_button.dart';
import 'package:xplayer/actions/channel_actions.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';

class ChannelItemWidget extends StatefulWidget {
  final Channel channel;
  final List<Channel> favoriteChannels;
  final double width;
  final bool? hideTitle;
  final VoidCallback? onChannelUpdated;

  const ChannelItemWidget(
      {super.key,
      required this.channel,
      required this.favoriteChannels,
      required this.width,
      this.onChannelUpdated,
      this.hideTitle});

  @override
  State<ChannelItemWidget> createState() => _ChannelItemWidgetState();
}

class _ChannelItemWidgetState extends State<ChannelItemWidget> {
  bool get _isFavorite {
    return widget.favoriteChannels
        .any((element) => element.id == widget.channel.id);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final mediaProvider = Provider.of<MediaProvider>(context);
    final testResult = mediaProvider.getChannelTestResult(widget.channel.id);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimens.radius),
      ),
      child: XBaseButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlayerScreen(
                channel: widget.channel,
                favoriteChannels: widget.favoriteChannels,
              ),
            ),
          );
        },
        onMore: () =>
            ChannelActions.handleMoreAction(context, widget.channel, () {}),
        // 菜单键留给首页"回到在播小窗";频道"更多操作"仍可长按 OK 触发,避免与之冲突
        menuKeyAsMore: false,
        child: (isFocused) => SizedBox(
            width: widget.width,
            child: Stack(children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 统一频道牌:固定 16:10、统一内边距、中性衬底。
                  // 台标规格千差万别,靠这层合成才能扫成一个系统。
                  ChannelPlate(
                    channel: widget.channel,
                    width: widget.width,
                    focused: isFocused,
                    health: SourceHealth.fromTestResult(testResult),
                    overlay: Stack(
                      children: [
                        // 收藏心标 —— 右下角
                        Positioned(
                          right: widget.width * 0.05,
                          bottom: widget.width * 0.05,
                          child: Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color:
                                _isFavorite ? Colors.red : AppTokens.textPrimary,
                            size: widget.width * 0.12,
                          ),
                        ),
                        // 延时数值只在测过之后显示,且避开清晰度角标所在的右下角
                        if (testResult != null &&
                            _getStatusText(testResult).isNotEmpty)
                          Positioned(
                            top: widget.width * 0.05,
                            right: widget.width * 0.05,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: widget.width * 0.04,
                                  vertical: widget.width * 0.014),
                              decoration: BoxDecoration(
                                color: _getStatusColor(testResult),
                                borderRadius: BorderRadius.circular(
                                    AppDimens.radiusSm),
                              ),
                              child: Text(
                                _getStatusText(testResult),
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: widget.width * 0.06,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        if (isFocused)
                          Positioned.fill(
                            child: Container(
                              color: AppTokens.focusPlayOverlay,
                              child: Center(
                                child: Icon(
                                  Icons.play_circle,
                                  color: AppTokens.textPrimary,
                                  size: widget.width * 0.3,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (widget.hideTitle != true)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 8.0),
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(8.0)),
                        ),
                        // 这里此前渲染的是 channel.id —— 那是机器标识
                        // (`123TV.DE@SD`),全大写还被截断成
                        // `1PLUS1INTERNATIONA…`。改用规范化后的展示名,
                        // 并允许换到两行:宁可换行也不中途截断。
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              widget.channel.name.isEmpty
                                  ? widget.channel.id
                                  : widget.channel.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: widget.width * 0.07,
                                  height: 1.25,
                                  color: AppTokens.textPrimary),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                            if (_subtitle.isNotEmpty)
                              Text(
                                _subtitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: widget.width * 0.055,
                                    color: AppTokens.textTertiary),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                          ],
                        ),
                      ),
                    )
                ],
              ),
            ])),
      ),
    );
  }

  /// 名称下方的副行:分组 · 地区。
  ///
  /// 分组此前是压在牌面左下角的大标签,满屏都是「General」,占着黄金位置却
  /// 几乎不携带信息;而且 `Entertainment;Family;General` 会直接溢出。
  /// 现在降为副行,并走拆分后的多标签(只取第一个,副行放不下更多)。
  String get _subtitle {
    final parts = <String>[];
    final groups = widget.channel.groups;
    if (groups.isNotEmpty) parts.add(groups.first);
    final region = widget.channel.region;
    if (region != null && region.isNotEmpty) parts.add(region);
    return parts.join(' · ');
  }

  /// 根据测试结果获取显示文本
  String _getStatusText(ChannelTestResult result) {
    switch (result.status) {
      case TestStatus.success:
        return '${result.latency}ms';
      case TestStatus.timeout:
        return result.errorMessage ?? '超时';
      case TestStatus.failed:
        return result.errorMessage ?? '失败';
      case TestStatus.testing:
        return '测试中';
      case TestStatus.idle:
        return '';
    }
  }

  /// 根据测试结果获取颜色
  Color _getStatusColor(ChannelTestResult result) {
    switch (result.status) {
      case TestStatus.success:
        // 根据延时等级返回颜色
        return _getLatencyColor(result.latencyLevel);
      case TestStatus.timeout:
      case TestStatus.failed:
        return Colors.red;
      case TestStatus.testing:
        return Colors.blue;
      case TestStatus.idle:
        return Colors.grey;
    }
  }

  /// 根据延时等级获取颜色
  Color _getLatencyColor(LatencyLevel level) {
    switch (level) {
      case LatencyLevel.excellent:
        return Colors.green;
      case LatencyLevel.good:
        return Colors.orange;
      case LatencyLevel.poor:
        return Colors.red;
      case LatencyLevel.unknown:
        return Colors.grey;
    }
  }
}
