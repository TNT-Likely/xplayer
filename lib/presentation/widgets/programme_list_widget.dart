import 'package:flutter/material.dart';
import 'dart:math';

import 'package:intl/intl.dart';
import 'package:xplayer/data/models/programme_model.dart';

class ProgrammeListWidget extends StatefulWidget {
  final List<Programme> programmes;
  final Function(Programme)? onSelected;

  const ProgrammeListWidget({
    Key? key,
    required this.programmes,
    this.onSelected,
  }) : super(key: key);

  @override
  State<ProgrammeListWidget> createState() => _ProgrammeListWidgetState();
}

class _ProgrammeListWidgetState extends State<ProgrammeListWidget> {
  Programme? selectedProgramme;
  int? currentProgrammeIndex;
  final ScrollController _scrollController = ScrollController();
  final Map<int, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _selectCurrentOrNextProgramme();
      if (currentProgrammeIndex != null) {
        _scrollToCurrentProgramme();
        _focusNodes[currentProgrammeIndex]?.requestFocus();
      }
    });
  }

  void _selectCurrentOrNextProgramme() {
    final now = DateTime.now();
    Programme? currentProgramme;
    Programme? nextProgramme;
    int currentIndex = -1;

    for (int i = 0; i < widget.programmes.length; i++) {
      final programme = widget.programmes[i];
      if (now.isAfter(programme.start) && now.isBefore(programme.stop)) {
        currentProgramme = programme;
        currentIndex = i;
        break;
      } else if (nextProgramme == null ||
          programme.start.isBefore(nextProgramme.start)) {
        if (programme.start.isAfter(now)) {
          nextProgramme = programme;
        }
      }
    }

    setState(() {
      selectedProgramme = currentProgramme ?? nextProgramme;
      currentProgrammeIndex = currentProgramme != null ? currentIndex : null;
    });
  }

  void _scrollToCurrentProgramme() {
    if (currentProgrammeIndex != null) {
      const double itemHeight = 72.0; // ListTile 默认高度为 56.0, 考虑一些额外间距
      double screenHeight = MediaQuery.of(context).size.height;
      final double scrollToPosition = currentProgrammeIndex! * itemHeight -
          (screenHeight - itemHeight) * 0.5;
      _scrollController.animateTo(
        scrollToPosition,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  double calculateProgress(Programme programme) {
    final now = DateTime.now();
    if (now.isBefore(programme.start)) return 0.0;
    if (now.isAfter(programme.stop)) return 1.0;
    final duration = programme.stop.difference(programme.start).inSeconds;
    final elapsed = now.difference(programme.start).inSeconds;
    return min(1.0, max(0.0, elapsed / duration));
  }

  @override
  Widget build(BuildContext context) {
    final Color themeColor = Theme.of(context).primaryColor;

    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.programmes.length,
      itemBuilder: (context, index) {
        final programme = widget.programmes[index];
        final progress = calculateProgress(programme);
        final isSelected = selectedProgramme == programme;

        if (!_focusNodes.containsKey(index)) {
          _focusNodes[index] = FocusNode();
        }

        return Focus(
          focusNode: _focusNodes[index],
          onFocusChange: (hasFocus) {
            if (hasFocus) {
              setState(() {
                selectedProgramme = programme;
                currentProgrammeIndex = index;
              });
              _scrollToCurrentProgramme();
            }
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                tileColor: isSelected
                    ? themeColor.withOpacity(0.8)
                    : Colors.transparent, // 更明显的选中颜色
                focusColor: themeColor.withOpacity(0.2), // 设置焦点颜色
                hoverColor: Colors.green.withOpacity(0.3), // 更明显的悬停颜色
                onTap: () {
                  setState(() {
                    selectedProgramme = programme;
                    currentProgrammeIndex = index;
                  });
                  _focusNodes[index]?.requestFocus();
                  widget.onSelected?.call(programme);
                },
                title: Text(
                  programme.title,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 16.0), // 减小标题文字的大小
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${DateFormat('HH:mm').format(programme.start.toLocal())} - ${DateFormat('HH:mm').format(programme.stop.toLocal())}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[600],
                      valueColor:
                          AlwaysStoppedAnimation<Color>(themeColor), // 使用主题色
                    ),
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
