import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dashboard_home.dart';
import 'inventory_screen.dart';
import 'tickets_screen.dart';
import 'supplies_screen.dart';
import 'qr_code_scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardHome(),
    InventoryScreen(),
    SizedBox.shrink(), // espaço do botão QR central
    TicketsScreen(),
    SuppliesScreen(),
  ];

  void _onTabTapped(int index) {
    if (index == 2) return;
    setState(() => _currentIndex = index);
  }

  void _openQrScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QrCodeScannerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF522583);
    const bg = Color(0xFFF4F3F8);

    return Scaffold(
      extendBody: true,
      backgroundColor: bg,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: bg,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: ColoredBox(
        color: bg,
        child: SafeArea(
          top: true,
          bottom: false,                 // não empurra a bottom bar
          child: IndexedStack(index: _currentIndex, children: _pages),
        ),
      ),
    ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          bottom: 0.0,
        ), // 🔹 desce levemente o botão
        child: SizedBox(
          width: 64,
          height: 64,
          child: FloatingActionButton(
            backgroundColor: const Color(0xFF522583),
            elevation: 10,
            shape: const CircleBorder(),
            onPressed: _openQrScanner,
            child: const Icon(
              Icons.qr_code_scanner,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),

      // ⬇️ FIX principal
      bottomNavigationBar: SafeArea(
        top: false,
        bottom: true,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // Fundo roxo
            Container(
              height: 76,
              decoration: const BoxDecoration(
                color: Color(0xFF522583),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: BottomAppBar(
                color: Colors.transparent,
                elevation: 0,
                shape: const CircularNotchedRectangle(),
                notchMargin: 10,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNavItem(Icons.home_rounded, "Home", 0),
                      _buildNavItem(Icons.computer_rounded, "Inventário", 1),
                      const SizedBox(width: 56), // espaço pro botão central
                      _buildNavItem(Icons.receipt_long_rounded, "Chamados", 3),
                      _buildNavItem(Icons.inventory_2_rounded, "Insumos", 4),
                    ],
                  ),
                ),
              ),
            ),

            // === Meia-lua branca perfeitamente encaixada no botão ===
            Positioned(
              top: 0, // 🔹 move ligeiramente pra cima pra “abraçar” o botão
              child: Container(
                width: 75,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(90),
                    bottomRight: Radius.circular(90),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _currentIndex == index;

    return SizedBox(
      width: 72, // largura fixa evita “aperto” vertical
      child: InkWell(
        onTap: () => _onTabTapped(index),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: isActive ? Colors.white : Colors.white70,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.0,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? Colors.white : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
