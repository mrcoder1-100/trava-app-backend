import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';
import '../features/features_tab.dart';
import '../common/language_selector_sheet.dart';
import '../../services/language_service.dart';

class ProfileTab extends StatefulWidget {
  final Function(int)? onNavigateTab;
  const ProfileTab({super.key, this.onNavigateTab});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final ApiService _api = ApiService();
  final LanguageService _langService = LanguageService();

  Future<void> _handleResetDemo() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Demo State?'),
        content: const Text(
          'This will reset simulated bus positions, restore coupons to active state, and return the presentation environment to pristine initial settings.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Reset Demo')),
        ],
      ),
    );

    if (confirmed == true) {
      await _api.resetDemo();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demo environment restored to pristine baseline state!'),
            backgroundColor: AppTheme.emerald,
          ),
        );
      }
    }
  }

  void _showServerSettingsDialog() {
    final controller = TextEditingController(text: _api.baseUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.network_check, color: AppTheme.emerald),
            SizedBox(width: 8),
            Text('Server Connection', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'When testing on a physical mobile phone (APK), enter your computer’s Wi-Fi IP so the phone can reach the backend server.',
                style: TextStyle(fontSize: 12, color: AppTheme.muted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Backend Base URL',
                  hintText: 'http://192.168.1.xxx:5000/api/v1',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Quick Presets:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ActionChip(
                    label: const Text('localhost:5000', style: TextStyle(fontSize: 11)),
                    onPressed: () => controller.text = 'http://localhost:5000/api/v1',
                  ),
                  ActionChip(
                    label: const Text('10.0.2.2:5000 (Android Emulator)', style: TextStyle(fontSize: 11)),
                    onPressed: () => controller.text = 'http://10.0.2.2:5000/api/v1',
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emerald,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              await _api.setBaseUrl(controller.text);
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Server URL set to: ${_api.baseUrl}'),
                    backgroundColor: AppTheme.emerald,
                  ),
                );
              }
            },
            child: const Text('Save & Apply'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    await _api.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _api.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        title: Text(
          _langService.tr('profile_and_settings'),
          style: const TextStyle(fontWeight: FontWeight.w800),
          overflow: TextOverflow.ellipsis,
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: QuickLanguagePill(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Profile Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppTheme.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.emerald.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (user != null && user.fullName.toLowerCase().contains('demo'))
                            ? 'S'
                            : (user != null && user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'S'),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.emeraldDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                (user?.fullName.toLowerCase().contains('demo') == true)
                                    ? 'Sam'
                                    : (user?.fullName ?? 'Sam'),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'DEMO USER',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF78350F),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? 'demo@trava.org',
                          style: const TextStyle(color: AppTheme.muted, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.stars, color: AppTheme.amber, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${user?.pointsBalance ?? 50} ${_langService.tr('community_points')}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.emeraldDark,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Regional Languages Card (Tamil, English, Hindi)
            const RegionalLanguagesCard(),
            const SizedBox(height: 20),

            // Community Impact Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _langService.tr('community_impact'),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF065F46)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _langService.tr('fellow_passengers_assisted'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF065F46)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _langService.tr('community_impact_sub'),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF047857), height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Privacy & Data Governance Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.privacy_tip_outlined, color: AppTheme.emerald, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _langService.tr('privacy_first'),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _langService.tr('privacy_bullet_1'),
                    style: const TextStyle(fontSize: 12, color: AppTheme.muted, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Offline & Network Mode Simulation
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _api.isNoNetMode ? const Color(0xFFEF4444) : AppTheme.border,
                  width: _api.isNoNetMode ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _api.isNoNetMode ? const Color(0xFFFEF2F2) : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.signal_cellular_connected_no_internet_4_bar,
                                color: _api.isNoNetMode ? const Color(0xFFDC2626) : AppTheme.charcoal,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _langService.tr('no_net_mode_title'),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch.adaptive(
                        value: _api.isNoNetMode,
                        activeColor: const Color(0xFFDC2626),
                        onChanged: (val) {
                          setState(() {
                            _api.setNoNetMode(val);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                val
                                    ? 'No Net Mode Enabled: GPS records will queue locally.'
                                    : 'No Net Mode Disabled: Online network sync restored.',
                              ),
                              backgroundColor: val ? const Color(0xFFDC2626) : AppTheme.emerald,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _api.isNoNetMode
                        ? _langService.tr('no_net_sub_on')
                        : _langService.tr('no_net_sub_off'),
                    style: TextStyle(
                      fontSize: 12,
                      color: _api.isNoNetMode ? const Color(0xFFB91C1C) : AppTheme.muted,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const FeaturesTab(
                              initialSubSection: FeaturesSubSection.offlineGps,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: Text(
                        _langService.tr('open_offline_portal'),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _api.isNoNetMode ? const Color(0xFF1E3A8A) : AppTheme.emerald,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Demo Actions
            Text(
              _langService.tr('judge_controls'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.charcoal),
            ),
            const SizedBox(height: 10),

            OutlinedButton(
              onPressed: _showServerSettingsDialog,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppTheme.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.settings_ethernet, color: AppTheme.emerald, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '${_langService.tr('server_url')} (${_api.baseUrl.replaceAll('/api/v1', '')})',
                      style: const TextStyle(color: AppTheme.emeraldDark, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: _handleResetDemo,
              icon: const Icon(Icons.refresh, color: AppTheme.emerald),
              label: Text(
                _langService.tr('reset_demo_btn'),
                style: const TextStyle(color: AppTheme.emeraldDark, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppTheme.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),

            // Logout
            OutlinedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout, color: Color(0xFFDC2626)),
              label: Text(
                _langService.tr('logout_btn'),
                style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFFCA5A5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 24),

            // Footer
            Center(
              child: Column(
                children: const [
                  Text(
                    AppConstants.appName,
                    style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.emeraldDark, letterSpacing: 1),
                  ),
                  SizedBox(height: 2),
                  Text(
                    AppConstants.tagline,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.muted),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Version 1.0.0 (Coimbatore Edition)',
                    style: TextStyle(fontSize: 10, color: AppTheme.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
