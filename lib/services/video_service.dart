import 'dart:async';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class VideoService {
  final ScreenshotController screenshotController = ScreenshotController();

  Future<Map<String, dynamic>> testM3u8LatencyAndScreenshot(
      String m3u8Url) async {
    Completer<void> firstFrameCompleter = Completer<void>();
    Timer? timer;
    Duration latency = Duration.zero;

    // 创建VideoPlayerController并初始化
    final VideoPlayerController controller =
        VideoPlayerController.network(m3u8Url);

    // 监听控制器状态变化
    listener() {
      if (controller.value.isInitialized && !firstFrameCompleter.isCompleted) {
        controller.removeListener(listener);
        firstFrameCompleter.complete();
      }
    }

    controller.addListener(listener);

    try {
      // 开始计时
      timer = Timer.periodic(const Duration(milliseconds: 1), (Timer t) {
        if (firstFrameCompleter.isCompleted) {
          latency = Duration(milliseconds: t.tick); // 将 tick 转换为 milliseconds
          t.cancel();
        }
      });

      await controller
          .initialize()
          .timeout(const Duration(seconds: 10)); // 设置一个超时

      // 播放视频
      await controller.play();

      // 等待第一帧加载完成
      await firstFrameCompleter.future;

      // 截图当前帧
      String screenshotPath = await _captureScreenshot(controller, m3u8Url);

      return {
        'latency': latency,
        'screenshotPath': screenshotPath,
      };
    } catch (e) {
      print('Error testing M3u8 latency and taking screenshot: $e');
      rethrow;
    } finally {
      // 清理资源
      await controller.dispose();
      timer?.cancel();
    }
  }

  Future<String> _captureScreenshot(
      VideoPlayerController controller, String m3u8Url) async {
    // 使用 ScreenshotController 捕获画面
    final image = await screenshotController.captureFromWidget(
      VideoPlayer(controller),
      delay: const Duration(milliseconds: 500), // 等待一段时间以确保画面稳定
    );

    // 获取应用文档目录
    final appDocDir = await getApplicationDocumentsDirectory();
    final urlFileName = path.basename(Uri.parse(m3u8Url).path); // 从URL获取文件名部分
    final fileName = '${urlFileName}_screenshot.png'; // 生成带有M3U8文件名的截图文件名
    final file = File('${appDocDir.path}/$fileName');

    // 将图片保存到文件
    await file.writeAsBytes(image);

    return file.path;
  }
}
