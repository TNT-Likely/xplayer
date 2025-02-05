import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/presentation/screens/player.dart';
import 'package:xplayer/shared/components/x_base_button.dart';
import 'package:xplayer/actions/channel_actions.dart';

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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
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
        child: (isFocused) => SizedBox(
            width: widget.width,
            child: Stack(children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(children: [
                      Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(8.0),
                            decoration: const BoxDecoration(
                              color: Color.fromRGBO(0, 0, 0, 0.35),
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(8.0),
                                  bottom: Radius.circular(8.0)),
                            ),
                            child: LayoutBuilder(
                              builder: (BuildContext context,
                                  BoxConstraints constraints) {
                                final double logoWidth = constraints.maxWidth *
                                    0.4 *
                                    (isFocused ? 1.1 : 1.0);
                                return SizedBox(
                                  width: logoWidth,
                                  child: CachedNetworkImage(
                                    imageUrl: widget.channel.logo ?? '',
                                    fit: BoxFit.fitWidth,
                                    errorWidget: (BuildContext context,
                                        String exception, Object? stackTrace) {
                                      return Icon(
                                          Icons
                                              .signal_wifi_statusbar_connected_no_internet_4,
                                          color: Colors.white70,
                                          size: logoWidth * 0.8);
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            bottom: 8.0,
                            left: 8.0,
                            child: Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 4.0),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                child: Text(
                                  widget.channel.source.first.groupTitle ?? '',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: widget.width * 0.06),
                                ),
                              ),
                            ]),
                          ),
                          Positioned(
                            right: 8.0,
                            bottom: 8.0,
                            child: Icon(
                              _isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _isFavorite ? Colors.red : Colors.white,
                              size: widget.width * 0.12,
                            ),
                          )
                        ],
                      ),
                      Positioned.fill(
                        child: Opacity(
                            opacity: isFocused ? 1 : 0,
                            child: Stack(children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color.fromRGBO(0, 0, 0, 0.65),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                    child: Icon(
                                  Icons.play_circle,
                                  color: Colors.white,
                                  size: widget.width * 0.3,
                                )),
                              )
                            ])),
                      ),
                    ]),
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                widget.channel.id,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: widget.width * 0.07,
                                    color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
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
}
