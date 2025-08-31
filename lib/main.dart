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
import 'package:xplayer/providers/remote_provider.dart';
import 'package:xplayer/presentation/screens/remote_input.dart';
import 'package:xplayer/shared/navigation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => MediaProvider()),
    ChangeNotifierProvider(create: (_) => LocaleProvider()..loadLocale()),
    ChangeNotifierProvider(create: (_) => GlobalProvider()..loadDeviceInfo()),
    ChangeNotifierProvider(create: (_) => RemoteProvider()),
  ], child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      title: 'Flutter Demo',
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromRGBO(0, 220, 130, 1), // 主色调种子颜色
          brightness: Brightness.light,
        ),
        useMaterial3: true, // 启用 Material You (Material 3) 风格
      ),
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
