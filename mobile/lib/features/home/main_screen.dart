import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'home_tab.dart';
import '../tracking/track_bus_tab.dart';
import '../gps_sharing/share_gps_tab.dart';
import '../features/features_tab.dart';
import '../rewards/rewards_tab.dart';
import '../profile/profile_tab.dart';
import '../../services/language_service.dart';

class MainScreen extends StatefulWidget {
  final int initialTabIndex;
  const MainScreen({super.key, this.initialTabIndex = 0});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  final LanguageService _langService = LanguageService();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
  }

  void switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeTab(onNavigateTab: switchTab),
      const TrackBusTab(),
      ShareGpsTab(
        onJourneyCompleted: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RewardsTab()),
          );
        },
      ),
      FeaturesTab(onNavigateTab: switchTab),
      ProfileTab(onNavigateTab: switchTab),
    ];

    return ValueListenableBuilder<AppLanguage>(
      valueListenable: _langService.currentLanguageNotifier,
      builder: (context, _, child) {
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: tabs,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                height: 68,
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.emerald,
                    );
                  }
                  return const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  );
                }),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const IconThemeData(
                      color: AppTheme.emerald,
                      size: 24,
                    );
                  }
                  return const IconThemeData(
                    color: Color(0xFF64748B),
                    size: 22,
                  );
                }),
              ),
              child: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: switchTab,
                backgroundColor: Colors.white,
                indicatorColor: AppTheme.emerald.withOpacity(0.12),
                elevation: 0,
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.home_outlined),
                    selectedIcon: const Icon(Icons.home, color: AppTheme.emerald),
                    label: _langService.tr('nav_home'),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.directions_bus_outlined),
                    selectedIcon: const Icon(Icons.directions_bus, color: AppTheme.emerald),
                    label: _langService.tr('nav_track_bus'),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.share_location_outlined),
                    selectedIcon: const Icon(Icons.share_location, color: AppTheme.emerald),
                    label: _langService.tr('nav_share_gps'),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.widgets_outlined),
                    selectedIcon: const Icon(Icons.widgets, color: AppTheme.emerald),
                    label: _langService.tr('nav_features'),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.person_outline),
                    selectedIcon: const Icon(Icons.person, color: AppTheme.emerald),
                    label: _langService.tr('nav_profile'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
