import 'package:flutter/material.dart';
import '../models/paket_uc.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'uc_coin.dart';

// Kartu satu paket UC: jumlah UC, bonus, harga, harga per UC, dan label.
class PaketCard extends StatelessWidget {
  final PaketUc paket;
  final bool selected;
  final VoidCallback onTap;

  const PaketCard({
    super.key,
    required this.paket,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.kartu(
            selected: selected,
            warna: selected
                ? AppColors.accent.withValues(alpha: 0.10)
                : AppColors.surface,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const UcCoin(size: 26),
                  const Spacer(),
                  if (selected)
                    const Icon(Icons.check_circle_rounded,
                        size: 22, color: AppColors.accent)
                  else if (paket.tag != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(paket.tag!,
                          style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.success)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text.rich(
                TextSpan(
                  text: formatRibuan(paket.total),
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w900, height: 1),
                  children: const [
                    TextSpan(
                      text: ' UC',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                paket.punyaBonus
                    ? '${formatRibuan(paket.ucDasar)} + ${formatRibuan(paket.bonus)} bonus'
                    : 'Tanpa bonus',
                style: TextStyle(
                  fontSize: 12,
                  color: paket.punyaBonus
                      ? AppColors.success
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Text(formatRupiah(paket.harga),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent)),
              Text('Rp${formatRibuan(paket.hargaPerUc)} / UC',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
