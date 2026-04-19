import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TweenAnimationBuilder<double>(
          duration: const Duration(seconds: 2),
          tween: Tween(begin: 0.7, end: 1),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return Opacity(
              opacity: value,
              child: Transform.scale(
                scale: value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 42,
                      backgroundColor: AppTheme.seed,
                      child: Icon(Icons.ballot_rounded, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 16),
                    Text(AppConstants.appName, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    const FadeScaleTransition(
                      animation: AlwaysStoppedAnimation<double>(1),
                      child: Text('Voice of every constituency'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

