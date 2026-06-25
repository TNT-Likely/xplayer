import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show LicenseRegistry, LicenseEntryWithLineBreaks;
import 'package:flutter/services.dart';
import 'package:xplayer/presentation/screens/splash.dart';
import 'package:xplayer/providers/global_provider.dart';
import 'presentation/screens/playlist.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:xplayer/localization/app_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/locale_provider.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'dart:async';
import 'package:xplayer/providers/remote_provider.dart';
import 'package:xplayer/presentation/screens/remote_input.dart';
import 'package:xplayer/shared/navigation.dart';
import 'package:xplayer/shared/theme/app_theme.dart';
import 'package:xplayer/services/log_store.dart';
import 'package:xplayer/utils/player_settings.dart';

/// 启动诊断日志(仅 Windows):写到 %TEMP%\xplayer_startup.log。
/// release 版控制台不可靠,用文件日志定位"白屏不出帧"卡在哪一步。
void _winLog(String msg) {
  if (!Platform.isWindows) return;
  try {
    final f = File('${Directory.systemTemp.path}\\xplayer_startup.log');
    f.writeAsStringSync(
      '${DateTime.now().toIso8601String()}  $msg\n',
      mode: FileMode.append,
      flush: true,
    );
  } catch (_) {}
}

/// 启动时检测本机对常见视频/音频编码的解码支持(尤其音频 AC-3/E-AC-3/MP2 —— 直播没声音的根因),
/// 结果写入日志中心 debug 级。仅 Android 有原生探测,其它平台忽略。
Future<void> _probeCodecsAtStartup() async {
  try {
    final s = await const MethodChannel('diag/logcat')
        .invokeMethod<String>('getCodecs');
    if (s != null && s.trim().isNotEmpty) {
      LogStore.instance.d('codec', '启动·编解码支持检测:\n${s.trim()}');
    }
  } catch (e) {
    LogStore.instance.d('codec', '编解码支持检测不可用(非 Android?):$e');
  }
}

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    _winLog('binding initialized');
    loadRenderMode(); // 载入渲染模式偏好(SurfaceView/纹理)
    loadNativeEngineMode(); // 载入播放引擎偏好(原生/video_player)

    // FFmpeg(media3-decoder-ffmpeg)LGPL 声明 —— Android 包内置 FFmpeg 音频软解(动态链接 .so)。
    LicenseRegistry.addLicense(() async* {
      yield const LicenseEntryWithLineBreaks(
        <String>['FFmpeg (media3-decoder-ffmpeg)'],
        'This application bundles FFmpeg for audio decoding (AC-3/E-AC-3/DTS/MP2/MP3/TrueHD) '
        'on Android, dynamically linked via the AndroidX Media3 FFmpeg decoder extension '
        '(media3-decoder-ffmpeg 1.9.2).\n\n'
        'FFmpeg is licensed under the GNU Lesser General Public License version 2.1 (LGPL-2.1) '
        'or later. FFmpeg source code is available at https://ffmpeg.org/ and '
        'https://git.ffmpeg.org/ffmpeg.git . The bundled build enables the decoders: '
        'ac3, eac3, dca, mp2, mp3, truehd.\n\n'
        'Full LGPL-2.1 text: https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html',
      );
    });

    FlutterError.onError = (FlutterErrorDetails details) {
      _winLog('FlutterError: ${details.exceptionAsString()}');
      LogStore.instance
          .e('flutter', '${details.exceptionAsString()}\n${details.stack}');
      FlutterError.presentError(details);
    };

    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      _winLog('sqflite ffi init done');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _winLog('first frame built');
      _probeCodecsAtStartup();
    });

    _winLog('calling runApp');
    runApp(MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => MediaProvider()),
      ChangeNotifierProvider(create: (_) => LocaleProvider()..loadLocale()),
      ChangeNotifierProvider(create: (_) => GlobalProvider()..loadDeviceInfo()),
      ChangeNotifierProvider(create: (_) => RemoteProvider()),
    ], child: const MyApp()));
    _winLog('runApp returned');
  }, (Object error, StackTrace stack) {
    _winLog('ZONE ERROR: $error\n$stack');
    LogStore.instance.e('zone', '$error\n$stack');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      title: 'XPlayer',
      debugShowCheckedModeBanner: false,
      navigatorKey: AppNav.key,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('zh')],
      locale: localeProvider.locale,
      navigatorObservers: [BotToastNavigatorObserver()],
      builder: (context, child) {
        return BotToastInit()(context, child); // 初始化 BotToast
      },
      theme: buildAppTheme(),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        // '/': (context) => const FocusTestPage(),
        '/playlists': (context) => const PlaylistListScreen(),
        '/remote': (context) => const RemoteInputScreen(),
      },
    );
  }
}
