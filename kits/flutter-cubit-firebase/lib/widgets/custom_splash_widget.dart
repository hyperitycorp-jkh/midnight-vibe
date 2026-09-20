import 'package:flutter/material.dart';
import '../configs/app_config.dart';

class CustomSplashWidget extends StatelessWidget {
  const CustomSplashWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withAlpha(200),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 로고 아이콘
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.rocket_launch,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 30),
              
              // 앱 이름
              Text(
                AppConfig().appName,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              
              // 부제목
              const Text(
                '시작하는 중...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 60),
              
              // 로딩 인디케이터
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}