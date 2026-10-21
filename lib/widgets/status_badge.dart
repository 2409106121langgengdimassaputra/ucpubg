import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Lencana status transaksi: Diproses (amber) / Berhasil (hijau)
class StatusBadge extends StatelessWidget {
  final bool berhasil;
  const StatusBadge({super.key, required this.berhasil});

  @override
  Widget build(BuildContext context) {
    final warna = berhasil ? AppColors.success : AppColors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: warna, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            berhasil ? 'Berhasil' : 'Diproses',
            style: TextStyle(
                color: warna, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
