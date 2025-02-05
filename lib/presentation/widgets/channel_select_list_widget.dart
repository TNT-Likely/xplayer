import 'package:flutter/material.dart';
import 'package:xplayer/data/models/channel_model.dart';

class ChannelSelectListWidget extends StatefulWidget {
  final List<Channel> channels;
  final Function(Channel)? onSelected;
  final Channel currentChannel; // 新增：当前选中的频道

  const ChannelSelectListWidget({
    Key? key,
    required this.channels,
    this.onSelected,
    required this.currentChannel,
  }) : super(key: key);

  @override
  State<ChannelSelectListWidget> createState() =>
      _ChannelSelectListWidgetState();
}

class _ChannelSelectListWidgetState extends State<ChannelSelectListWidget> {
  Channel? selectedChannel;
  int? currentChannelIndex;
  final ScrollController _scrollController = ScrollController();
  final Map<int, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _selectCurrentOrNextChannel();
      _scrollToCurrentChannel();
      _focusNodes[currentChannelIndex]?.requestFocus();
    });
  }

  void _selectCurrentOrNextChannel() {
    // 这个方法名可能需要调整以更好地反映其功能
    final currentIndex = widget.channels.indexOf(widget.currentChannel);

    setState(() {
      selectedChannel = widget.currentChannel;
      currentChannelIndex = currentIndex;
    });
  }

  void _scrollToCurrentChannel() {
    if (currentChannelIndex != null) {
      const double itemHeight = 48.0;
      double screenHeight = MediaQuery.of(context).size.height;
      final double scrollToPosition =
          currentChannelIndex! * itemHeight - (screenHeight - itemHeight) * 0.5;
      _scrollController.animateTo(
        scrollToPosition,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color themeColor = Theme.of(context).primaryColor;

    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.channels.length,
      itemBuilder: (context, index) {
        final channel = widget.channels[index];
        final isSelected = selectedChannel == channel;

        if (!_focusNodes.containsKey(index)) {
          _focusNodes[index] = FocusNode();
        }

        return Focus(
          focusNode: _focusNodes[index],
          onFocusChange: (hasFocus) {
            if (hasFocus) {
              setState(() {
                selectedChannel = channel;
                currentChannelIndex = index;
              });
              _scrollToCurrentChannel();
            }
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                tileColor: isSelected
                    ? themeColor.withOpacity(0.8)
                    : Colors.transparent,
                focusColor: themeColor.withOpacity(0.2),
                hoverColor: Colors.green.withOpacity(0.3),
                onTap: () {
                  setState(() {
                    selectedChannel = channel;
                    currentChannelIndex = index;
                  });
                  _focusNodes[index]?.requestFocus();
                  widget.onSelected?.call(channel);
                },
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(channel.id,
                        style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (var node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }
}
