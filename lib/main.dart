import 'package:adaptive_shell/adaptive_shell.dart';
import 'package:flutter/material.dart';
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
import 'package:xplayer/providers/mini_player_controller.dart';
import 'package:xplayer/providers/cast_provider.dart';
import 'package:xplayer/presentation/widgets/mini_player_overlay.dart';
import 'package:xplayer/shared/theme/app_theme.dart';
import 'package:xplayer/shared/theme/theme_settings.dart';
import 'package:xplayer/shared/theme/theme_mode_setting.dart';
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
    loadRecentModuleSetting(); // 载入「最近播放」模块显示偏好
    loadFavoritesRowSetting(); // 载入「收藏」行显示偏好
    loadMiniPlayerSetting(); // 载入「返回小窗续播」偏好
    loadPipSetting(); // 载入「回桌面画中画」偏好
    loadThemeColor(); // 载入用户设定的主题强调色
    loadThemeMode(); // 载入日间/暗黑外观偏好

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
      ChangeNotifierProvider(create: (_) => MiniPlayerController()),
      ChangeNotifierProvider(create: (_) => CastProvider()),
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

    // 主色变化时重建 MaterialApp,使 buildAppTheme() 取到新的种子色。
    // 换色是低频操作,整树重建的代价可接受。
    // 输入方式在根部注入一次,下游靠 resolveShell 取形态。
    // 这是全应用唯一的形态判定入口 —— 组件层不再判断平台或尺寸。
    return InputModeScope(
      mode: detectInputMode(),
      // 两个 notifier 都要监听:主色变化与外观模式变化都需要重建 MaterialApp,
      // 因为 AppTokens 的取值依赖它们。换色/换外观都是低频操作,整树重建可接受。
      child: ValueListenableBuilder<AppThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, __mode, ___) => ValueListenableBuilder<Color>(
      valueListenable: themeColor,
      builder: (context, _, __) => MaterialApp(
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
          // 初始化 BotToast + 注入全局小窗浮层
          return BotToastInit()(
            context,
            Stack(
              children: [
                if (child != null) child,
                const MiniPlayerOverlay(),
              ],
            ),
          );
        },
        theme: buildAppTheme(brightness: Brightness.light),
        darkTheme: buildAppTheme(brightness: Brightness.dark),
        themeMode: materialThemeMode,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          // '/': (context) => const FocusTestPage(),
          '/playlists': (context) => const PlaylistListScreen(),
          '/remote': (context) => const RemoteInputScreen(),
        },
      ),
      ),
      ),
    );
  }
}
