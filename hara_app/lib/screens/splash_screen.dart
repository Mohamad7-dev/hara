import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';

const Color _splashBg = Color(0xFF29201C);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final u = auth.currentUser;
    if (u != null && !auth.needsProfile) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (u != null && auth.needsProfile) {
      Navigator.of(context).pushReplacementNamed('/profile-setup');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _splashBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/splash_anim.gif',
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 44,
            child: Column(
              children: [
                const Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppConstants.appTagline,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
