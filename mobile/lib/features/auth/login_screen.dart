import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';
import '../common/language_selector_sheet.dart';
import '../home/main_screen.dart';
import '../partner/partner_dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // 0: Commuter Portal, 1: Partner Merchant Portal
  int _selectedPortalIndex = 0;

  // Commuter credentials
  final _emailController = TextEditingController(text: 'demo@trava.org');
  final _passwordController = TextEditingController(text: 'Password123!');

  // Partner credentials
  final _partnerEmailController = TextEditingController(text: 'partner@annapoorna.com');
  final _partnerPasswordController = TextEditingController(text: 'Bakery2026!');

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _partnerEmailController.dispose();
    _partnerPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_selectedPortalIndex == 1) {
      // Partner Login
      _handlePartnerLogin();
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ApiService().login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      setState(() {
        _errorMessage = 'Invalid email or password, or backend server unavailable.';
      });
    }
  }

  Future<void> _handleDemoLogin() async {
    _emailController.text = 'demo@trava.org';
    _passwordController.text = 'Password123!';
    await _handleLogin();
  }

  void _handlePartnerLogin() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged in as Annapoorna Bakery & Sweets Partner'),
          backgroundColor: AppTheme.emerald,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PartnerDashboardScreen()),
      );
    });
  }

  void _handlePartnerDemoLogin() {
    _partnerEmailController.text = 'partner@annapoorna.com';
    _partnerPasswordController.text = 'Bakery2026!';
    _handlePartnerLogin();
  }

  void _showServerSettingsDialog() {
    final api = ApiService();
    final controller = TextEditingController(text: api.baseUrl);

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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'When testing on a physical mobile phone (APK), enter your laptop’s Wi-Fi IP so the phone can reach the backend server.',
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
                  label: const Text('localhost:5000 (USB Debugging)', style: TextStyle(fontSize: 11)),
                  onPressed: () => controller.text = 'http://localhost:5000/api/v1',
                ),
                ActionChip(
                  label: const Text('10.198.87.40:5000 (Laptop Wi-Fi)', style: TextStyle(fontSize: 11)),
                  onPressed: () => controller.text = 'http://10.198.87.40:5000/api/v1',
                ),
                ActionChip(
                  label: const Text('10.0.2.2:5000 (Android Emulator)', style: TextStyle(fontSize: 11)),
                  onPressed: () => controller.text = 'http://10.0.2.2:5000/api/v1',
                ),
              ],
            ),
          ],
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
              await api.setBaseUrl(controller.text);
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Server URL set to: ${api.baseUrl}'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          const QuickLanguagePill(),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.settings_ethernet, color: AppTheme.emerald),
            tooltip: 'Server Connection / Mobile APK Settings',
            onPressed: _showServerSettingsDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo & Branding
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: _selectedPortalIndex == 1
                              ? const Color(0xFFFEF3C7)
                              : AppTheme.emerald.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _selectedPortalIndex == 1
                                ? const Color(0xFFF59E0B)
                                : AppTheme.emerald.withOpacity(0.2),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _selectedPortalIndex == 1 ? '🥐' : '🚌',
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      _selectedPortalIndex == 1 ? 'TRAVA PARTNER' : AppConstants.appName,
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: _selectedPortalIndex == 1 ? const Color(0xFF92400E) : AppTheme.emeraldDark,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedPortalIndex == 1
                          ? 'Merchant & Bakery Verification Portal'
                          : AppConstants.tagline,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.charcoal,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedPortalIndex == 1
                          ? 'Annapoorna Bakery & Sweets • Gandhipuram Terminal'
                          : AppConstants.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // PORTAL SWITCHER: 1) Commuter Portal, 2) Partner Merchant Portal
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedPortalIndex = 0;
                                  _errorMessage = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _selectedPortalIndex == 0 ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: _selectedPortalIndex == 0
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.08),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: 16,
                                      color: _selectedPortalIndex == 0 ? AppTheme.emeraldDark : AppTheme.muted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Commuter Portal',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        color: _selectedPortalIndex == 0 ? AppTheme.emeraldDark : AppTheme.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedPortalIndex = 1;
                                  _errorMessage = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _selectedPortalIndex == 1 ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: _selectedPortalIndex == 1
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.08),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.storefront,
                                      size: 16,
                                      color: _selectedPortalIndex == 1 ? const Color(0xFFD97706) : AppTheme.muted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Partner Portal',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        color: _selectedPortalIndex == 1 ? const Color(0xFF92400E) : AppTheme.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // PORTAL 1: COMMUTER PORTAL
                    if (_selectedPortalIndex == 0) ...[
                      // Commuter Demo Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.amber.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.amber.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.stars, color: AppTheme.amber, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Coimbatore Live Demo Mode',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: Colors.brown.shade800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Preloaded with active Coimbatore bus routes and live bus tracking simulation.',
                              style: TextStyle(fontSize: 12, color: Colors.brown.shade700),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: _isLoading ? null : _handleDemoLogin,
                              icon: const Icon(Icons.flash_on, size: 18, color: AppTheme.emerald),
                              label: const Text(
                                '1-Click Demo Login (demo@trava.org)',
                                style: TextStyle(
                                  color: AppTheme.emeraldDark,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: AppTheme.emerald),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Email Input
                      const Text(
                        'Email Address',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.charcoal),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'e.g. passenger@trava.org',
                          prefixIcon: Icon(Icons.email_outlined, color: AppTheme.muted),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Email is required';
                          if (!val.contains('@')) return 'Enter a valid email address';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Password Input
                      const Text(
                        'Password',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.charcoal),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.muted),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: AppTheme.muted,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Password is required';
                          if (val.length < 6) return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Log In to Trava'),
                      ),
                      const SizedBox(height: 20),

                      // Register link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account? ", style: TextStyle(color: AppTheme.muted)),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const RegisterScreen()),
                              );
                            },
                            child: const Text(
                              'Register now',
                              style: TextStyle(color: AppTheme.emerald, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ]
                    // PORTAL 2: PARTNER MERCHANT PORTAL
                    else ...[
                      // Partner Demo Quick Login Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Text('🥐', style: TextStyle(fontSize: 22)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Annapoorna Bakery & Sweets Demo',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: Colors.brown.shade900,
                                        ),
                                      ),
                                      Text(
                                        'Gandhipuram Bus Stand Terminal • Instant Verification',
                                        style: TextStyle(fontSize: 11, color: Colors.brown.shade700),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _handlePartnerDemoLogin,
                              icon: const Icon(Icons.storefront, size: 18),
                              label: const Text(
                                '🥐 1-Click Demo Login (Annapoorna Bakery)',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD97706),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Partner Email Input
                      const Text(
                        'Merchant / Partner Email',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.charcoal),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _partnerEmailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'partner@annapoorna.com',
                          prefixIcon: Icon(Icons.storefront_outlined, color: Color(0xFFD97706)),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Partner Password Input
                      const Text(
                        'Merchant Password',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.charcoal),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _partnerPasswordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFD97706)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: AppTheme.muted,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit Partner Login Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F4C3A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isLoading ? null : _handlePartnerLogin,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Log In to Partner Merchant Portal',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                      ),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified_user_outlined, size: 18, color: Color(0xFF059669)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Cashier Verification & ₹125–₹150 commuter cashback counter for Coimbatore local businesses.',
                                style: TextStyle(fontSize: 11, color: Color(0xFF065F46), fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
