// lib/main.dart
// TenderPro AI — Main entry point
// Architecture: Provider state management, Bottom Nav shell
//
// Screens:
//   0 - DashboardScreen
//   1 - UploadTenderScreen
//   2 - BoqScreen
//   3 - ProjectsScreen
//   (Quotation accessible via BOQ screen)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/upload_tender_screen.dart';
import 'screens/boq_screen.dart';
import 'screens/projects_screen.dart';
import 'screens/quotation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode for consistent mobile experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Style system UI (status bar)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider()..seedDemoData(),
      child: const TenderProApp(),
    ),
  );
}

// ─────────────────────────────────────────────
// Root App Widget
// ─────────────────────────────────────────────
class TenderProApp extends StatelessWidget {
  const TenderProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TenderPro AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppShell(),
    );
  }
}

// ─────────────────────────────────────────────
// App Shell — Bottom Navigation Container
// ─────────────────────────────────────────────
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  bool _showQuotation = false;

  // Navigate to a specific tab
  void _navigateTo(int index) {
    if (index == 99) {
      // Special index for Quotation (not in bottom nav)
      setState(() { _showQuotation = true; _currentIndex = 2; });
      return;
    }
    setState(() {
      _currentIndex = index;
      _showQuotation = false;
    });
  }

  // Build the current screen based on index
  Widget _buildScreen() {
    if (_showQuotation) {
      return QuotationScreen(onNavigate: _navigateTo);
    }
    switch (_currentIndex) {
      case 0:
        return DashboardScreen(onNavigate: _navigateTo);
      case 1:
        return UploadTenderScreen(onNavigate: _navigateTo);
      case 2:
        return BoqScreen(onNavigate: _navigateTo);
      case 3:
        return ProjectsScreen(onNavigate: _navigateTo);
      default:
        return DashboardScreen(onNavigate: _navigateTo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        child: KeyedSubtree(
          key: ValueKey(_showQuotation ? 'quotation' : _currentIndex),
          child: _buildScreen(),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard,
                label: 'Dashboard',
                selected: _currentIndex == 0 && !_showQuotation,
                onTap: () => _navigateTo(0),
              ),
              _NavItem(
                icon: Icons.upload_file_outlined,
                activeIcon: Icons.upload_file,
                label: 'Upload',
                selected: _currentIndex == 1 && !_showQuotation,
                onTap: () => _navigateTo(1),
              ),
              _NavItem(
                icon: Icons.table_chart_outlined,
                activeIcon: Icons.table_chart,
                label: 'BOQ',
                selected: _currentIndex == 2 && !_showQuotation,
                onTap: () => _navigateTo(2),
              ),
              _NavItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long,
                label: 'Quotation',
                selected: _showQuotation,
                onTap: () => _navigateTo(99),
              ),
              _NavItem(
                icon: Icons.folder_outlined,
                activeIcon: Icons.folder,
                label: 'Projects',
                selected: _currentIndex == 3 && !_showQuotation,
                onTap: () => _navigateTo(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Custom Bottom Nav Item
// ─────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySurface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  selected ? activeIcon : icon,
                  key: ValueKey(selected),
                  color: selected ? AppColors.primary : AppColors.textMuted,
                  size: 22,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? AppColors.primary : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
