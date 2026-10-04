import 'package:flutter/material.dart';
import 'package:lubao_core/lubao_core.dart';

/// Показывается, пока SessionController пытается восстановить сессию из
/// secure storage при старте приложения — см. providers/auth_provider.dart.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: LoadingView());
  }
}
