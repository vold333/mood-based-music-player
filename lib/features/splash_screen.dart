import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/soul_assets.dart';
import 'categories/category_screen.dart';

/// Full-bleed Grand Line splash shown before entering the library.
class SoulSplashScreen extends StatefulWidget {
  const SoulSplashScreen({super.key});

  @override
  State<SoulSplashScreen> createState() => _SoulSplashScreenState();
}

class _SoulSplashScreenState extends State<SoulSplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1400), _openHome);
  }

  void _openHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const CategoryScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openHome,
          child: Image.asset(
            SoulAssets.splash,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (_, __, ___) => const ColoredBox(
              color: Color(0xFFBDEBFF),
              child: Center(
                child: Text(
                  'SOUL KING',
                  style: TextStyle(
                    color: Color(0xFF12354F),
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
