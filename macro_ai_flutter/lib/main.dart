import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/log_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/profile_screen.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0D0D0F),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const MacroAiApp());
}

class MacroAiApp extends StatelessWidget {
  final bool showOnboarding;
  final AppState? initialState;
  const MacroAiApp({super.key, this.showOnboarding = true, this.initialState});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Macro AI',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: showOnboarding ? const SplashScreen() : _RootShell(initialState: initialState),
    );
  }
}

// ── Root Shell with bottom nav ─────────────────────────────────────────────────
class _RootShell extends StatefulWidget {
  final AppState? initialState;
  const _RootShell({this.initialState});

  @override
  State<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<_RootShell> {
  int _currentIndex = 0;
  late final AppState _state;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState ?? AppState();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        state: _state,
        onOpenProfile: () => setState(() => _currentIndex = 4),
      ),
      LogScreen(state: _state),
      ScanScreen(state: _state),
      StatsScreen(state: _state),
      ProfileScreen(state: _state),
    ];

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(index: _currentIndex, children: screens),
        bottomNavigationBar: _BottomNav(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}

// ── Custom Bottom Nav ─────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    _NavItem(icon: Icons.home_outlined, label: 'Home'),
    _NavItem(icon: Icons.access_time_rounded, label: 'Log'),
    _NavItem(icon: Icons.crop_free_rounded, label: 'Scan'),
    _NavItem(icon: Icons.insights_rounded, label: 'Stats'),
    _NavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        height: 68,
        decoration: BoxDecoration(
          color: kBgCard.withOpacity(0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kBorder.withOpacity(0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: List.generate(_items.length, (i) {
            final item = _items[i];
            final selected = i == currentIndex;
            final isCenter = i == 2;

            Widget iconWidget;
            if (isCenter) {
              // Custom scan viewfinder style matching the mockup
              iconWidget = Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  border: Border.all(color: kAccent, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: kAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            } else {
              iconWidget = Icon(
                item.icon,
                size: 24,
                color: selected ? Colors.white : kTextMuted,
              );
            }

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    iconWidget,
                    if (selected && !isCenter) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: kAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
