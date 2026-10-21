import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/topup_provider.dart';
import '../theme/app_theme.dart';
import 'home_page.dart';
import 'profil_page.dart';
import 'riwayat_page.dart';

// Kerangka utama dengan navigasi bawah (Material 3 NavigationBar).
// Tab aktif disimpan di TopUpProvider (currentIndex).
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    // context.select: rebuild hanya jika nilai yang dipilih berubah
    final currentIndex =
        context.select<TopUpProvider, int>((p) => p.currentIndex);
    final diproses =
        context.select<TopUpProvider, int>((p) => p.jumlahDiproses);

    return Scaffold(
      // IndexedStack: state halaman lain (misal teks Player ID) tetap terjaga
      body: IndexedStack(
        index: currentIndex,
        children: const [HomePage(), RiwayatPage(), ProfilPage()],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (i) => context.read<TopUpProvider>().setTab(i),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront_rounded),
              label: 'Top Up',
            ),
            NavigationDestination(
              // Badge: jumlah transaksi yang masih diproses
              icon: Badge(
                isLabelVisible: diproses > 0,
                label: Text('$diproses'),
                child: const Icon(Icons.receipt_long_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: diproses > 0,
                label: Text('$diproses'),
                child: const Icon(Icons.receipt_long_rounded),
              ),
              label: 'Riwayat',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
