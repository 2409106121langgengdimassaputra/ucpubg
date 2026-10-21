import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Judul bagian bernomor: lingkaran angka berubah jadi centang saat langkah selesai
class StepTitle extends StatelessWidget {
  final int nomor;
  final String judul;
  final bool selesai;

  const StepTitle({
    super.key,
    required this.nomor,
    required this.judul,
    this.selesai = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selesai ? AppColors.success : AppColors.accent,
          ),
          child: selesai
              ? const Icon(Icons.check_rounded,
                  size: 16, color: AppColors.onAccent)
              : Text('$nomor',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.onAccent)),
        ),
        const SizedBox(width: 10),
        Text(judul,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      ],
    );
  }
}
