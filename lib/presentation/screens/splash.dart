import 'package:flutter/material.dart';
import 'dart:async';
import 'package:xplayer/presentation/screens/home.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // 定义延时时间（例如3秒）
  static const Duration splashDuration = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  void _navigateToHome() async {
    await Future.delayed(splashDuration);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()), // 替换为你的主页面
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    double screenWidth = MediaQuery.of(context).size.width * 0.7;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 18, 18, 18),
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Image(
              width: 300,
              image: AssetImage('assets/images/mini-logo.png')), // 替换为你的logo路径
          const SizedBox(height: 20),
          Text(
            localizations.appDescription, // 使用 .tr() 进行翻译
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 40),
          // const CircularProgressIndicator(color: Colors.green), // 设置进度条颜色
        ],
      )),
    );
  }
}
