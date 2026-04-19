import 'dart:convert';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _loaderAsset = 'assets/animations/LOGO_Loading_Animation_video_ready.json';

  @override
  void initState() {
    super.initState();
    _navigateAway();
  }

  _navigateAway() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      // Navigation will be handled by router based on auth state
      // The router will automatically redirect based on whether user is authenticated
    }
  }

  Future<bool> _hasValidLottieAsset() async {
    try {
      final raw = await rootBundle.loadString(_loaderAsset);
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> &&
          decoded.containsKey('layers') &&
          decoded['layers'] is List &&
          decoded.containsKey('v');
    } catch (_) {
      return false;
    }
  }

  Widget _fallbackMark(BuildContext context) {
    return Container(
      width: 144,
      height: 144,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.saffronPrimary,
            AppTheme.lightGreen,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.saffronPrimary.withValues(alpha: 0.24),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.how_to_vote_rounded,
        size: 74,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<bool>(
        future: _hasValidLottieAsset(),
        builder: (context, snapshot) {
          final showLottie = snapshot.data == true;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeInUp(
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  child: ScaleTransition(
                    scale: const AlwaysStoppedAnimation(1.0),
                    child: showLottie
                        ? Lottie.asset(
                            _loaderAsset,
                            width: 180,
                            height: 180,
                            fit: BoxFit.contain,
                            repeat: true,
                          )
                        : _fallbackMark(context),
                  ),
                ),
                const SizedBox(height: 22),
                FadeInUp(
                  duration: const Duration(milliseconds: 1300),
                  curve: Curves.easeOutCubic,
                  child: Text(
                    'ConstituencyConnect',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                          letterSpacing: -0.3,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                FadeInUp(
                  duration: const Duration(milliseconds: 1400),
                  delay: const Duration(milliseconds: 120),
                  curve: Curves.easeOutCubic,
                  child: Text(
                    'Civic engagement for Tamil Nadu',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black87,
                          letterSpacing: 0.2,
                        ),
                  ),
                ),
                const SizedBox(height: 28),
                FadeIn(
                  duration: const Duration(milliseconds: 1500),
                  delay: const Duration(milliseconds: 180),
                  child: SizedBox(
                    width: 34,
                    height: 34,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.saffronPrimary,
                      ),
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}





