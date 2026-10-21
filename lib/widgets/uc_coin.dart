import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Ikon koin UC buatan sendiri (tanpa aset gambar)
class UcCoin extends StatelessWidget {
  final double size;
  const UcCoin({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.accentGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.35),
            blurRadius: size / 3,
          ),
        ],
      ),
      child: Text(
        'UC',
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF3A2400),
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
