import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Satu baris "label ... nilai" untuk struk / ringkasan pesanan
class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool tebal;
  final Color? warnaNilai;

  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.tebal = false,
    this.warnaNilai,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: tebal ? FontWeight.w800 : FontWeight.w600,
                fontSize: tebal ? 16 : 14,
                color: warnaNilai,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
