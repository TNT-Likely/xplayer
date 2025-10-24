import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:xplayer/presentation/screens/home.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  void _initializeAndNavigate() async {
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);

    // 初始化应用数据
    await mediaProvider.initializeApp();

    // 确保至少显示启动屏1秒
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 18, 18, 18),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Image(
              width: 300,
              image: AssetImage('assets/images/mini-logo.png'),
            ),
            const SizedBox(height: 20),
            Text(
              localizations.appDescription,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 40),
            Consumer<MediaProvider>(
              builder: (context, mediaProvider, child) {
                return mediaProvider.isInitializing
                    ? Column(
                        children: [
                          const CircularProgressIndicator(
                            color: Colors.green,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            localizations.loading,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
