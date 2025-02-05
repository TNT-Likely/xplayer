import 'package:flutter/material.dart';
import 'package:bot_toast/bot_toast.dart';

// 初始化 BotToast
void initBotToast() {
  BotToastInit();
}

// 显示简单的 Toast 消息
void showToast(String message,
    {Duration duration = const Duration(seconds: 2)}) {
  BotToast.showText(
    text: message,
    duration: duration,
    onlyOne: true, // 确保一次只显示一个 Toas
  );
}

void hideToast() {
  BotToast.cleanAll();
}

// 显示加载中的提示
void showLoading({String message = "Loading..."}) {
  BotToast.showLoading(
    clickClose: false,
    allowClick: false,
    backButtonBehavior: BackButtonBehavior.ignore,
  );
}

// 隐藏加载中的提示
void hideLoading() {
  BotToast.closeAllLoading();
}

// 显示带有按钮的 SnackBar 类似效果
void showSnackBar(String message, {VoidCallback? onUndo}) {
  BotToast.showCustomNotification(
    toastBuilder: (_) => CustomSnackBar(message: message, onUndo: onUndo),
    duration: const Duration(seconds: 3),
    animationDuration: const Duration(milliseconds: 300),
    onlyOne: true,
  );
}

class CustomSnackBar extends StatelessWidget {
  final String message;
  final VoidCallback? onUndo;

  const CustomSnackBar({super.key, required this.message, this.onUndo});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
              child:
                  Text(message, style: const TextStyle(color: Colors.white))),
          if (onUndo != null)
            TextButton(
              onPressed: () {
                onUndo?.call();
                BotToast.cleanAll();
              },
              child: const Text('UNDO', style: TextStyle(color: Colors.blue)),
            ),
        ],
      ),
    );
  }
}
