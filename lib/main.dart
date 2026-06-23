import 'package:flutter/material.dart';
import 'package:xplayer/presentation/screens/splash.dart';
import 'package:xplayer/providers/global_provider.dart';
import 'presentation/screens/playlist.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    _winLog('binding initialized');

    FlutterError.onError = (FlutterErrorDetails details) {
      _winLog('FlutterError: ${details.exceptionAsString()}');
      FlutterError.presentError(details);
    };

    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      _winLog('sqflite ffi init done');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _winLog('first frame built');
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
